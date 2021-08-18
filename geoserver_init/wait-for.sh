#!/bin/sh

# The MIT License (MIT)
#
# Copyright (c) 2017 Eficode Oy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Modified version of wait-for.sh in order to check if GeoServer and PostgREST
# are available in our stack. Only then GeoServer Init script makes sense to
# run.

set -- "$@" -- "$TIMEOUT" "$QUIET" "$GS_HOST" "$GS_PORT" "$PGR_HOST" "$PGR_PORT" "$result"
TIMEOUT=15
QUIET=0

echoerr() {
  if [ "$QUIET" -ne 1 ]; then printf "%s\n" "$*" 1>&2; fi
}

usage() {
  exitcode="$1"
  cat << USAGE >&2
Usage:
  $cmdname gshost:gsport pgrhost:pgrport [-t timeout] [-- command args]
  -q | --quiet                        Do not output any status messages
  -t TIMEOUT | --timeout=timeout      Timeout in seconds, zero for no timeout
  -- COMMAND ARGS                     Execute command with args after the test finishes
USAGE
  exit "$exitcode"
}

wait_for() {
 if ! command -v wget >/dev/null; then
    echoerr 'wget command is missing!'
    exit 1
  fi

  while :; do
    echo "testing" "http://"$GS_HOST:$GS_PORT"/geoserver" and "http://$PGR_HOST:$PGR_PORT/raster_metadata"
    wget --spider "http://"$GS_HOST:$GS_PORT"/geoserver/web/wicket/resource/org.geoserver.web.GeoServerBasePage/img/logo.png" > /dev/null 2>&1 &&
    wget --spider "http://$PGR_HOST:$PGR_PORT/raster_metadata?is_published=eq.0" > /dev/null 2>&1

    result=$?
    if [ $result -eq 0 ] ; then
      if [ $# -gt 6 ] ; then
        for result in $(seq $(($# - 6))); do
          result=$1
          shift
          set -- "$@" "$result"
        done

        TIMEOUT=$2 QUIET=$3 GS_HOST=$4 GS_PORT=$5 PGR_HOST=$6 PGR_PORT=$7 result=$8
        shift 6
        exec "$@"
      fi
      exit 0
    fi

    if [ "$TIMEOUT" -le 0 ]; then
      break
    fi
    TIMEOUT=$((TIMEOUT - 1))

    sleep 1
  done
  echo "Operation timed out" >&2
  exit 1
}

resources_cnt=0;
while :; do
  case "$1" in
    *:* )
    # first arg is the GeoServer host and port
    if [ "$resources_cnt" -eq 0 ]; then
      GS_HOST=$(printf "%s\n" "$1"| cut -d : -f 1)
      GS_PORT=$(printf "%s\n" "$1"| cut -d : -f 2)

      resources_cnt=$((resources_cnt+1))
    fi

    # first arg is the PostgREST host and port
    if [ "$resources_cnt" -eq 1 ]; then
      PGR_HOST=$(printf "%s\n" "$1"| cut -d : -f 1)
      PGR_PORT=$(printf "%s\n" "$1"| cut -d : -f 2)
    fi

    shift 1
    ;;
    -q | --quiet)
    QUIET=1
    shift 1
    ;;
    -q-*)
    QUIET=0
    echoerr "Unknown option: $1"
    usage 1
    ;;
    -q*)
    QUIET=1
    result=$1
    shift 1
    set -- -"${result#-q}" "$@"
    ;;
    -t | --timeout)
    TIMEOUT="$2"
    shift 2
    ;;
    -t*)
    TIMEOUT="${1#-t}"
    shift 1
    ;;
    --timeout=*)
    TIMEOUT="${1#*=}"
    shift 1
    ;;
    --)
    shift
    break
    ;;
    --help)
    usage 0
    ;;
    -*)
    QUIET=0
    echoerr "Unknown option: $1"
    usage 1
    ;;
    *)
    QUIET=0
    echoerr "Unknown argument: $1"
    usage 1
    ;;
  esac
done

if ! [ "$TIMEOUT" -ge 0 ] 2>/dev/null; then
  echoerr "Error: invalid timeout '$TIMEOUT'"
  usage 3
fi

if [ "$GS_HOST" = "" -o "$GS_PORT" = "" ]; then
  echoerr "Error: you need to provide a host and port to test."
  usage 2
fi

wait_for "$@"

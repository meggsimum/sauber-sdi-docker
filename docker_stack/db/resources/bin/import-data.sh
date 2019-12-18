#!/usr/bin/env bash

# usage: import_data.sh PACKAGE_FOLDER
# This is a helper script to import new data into a running container.
# Executes .sql .sql.gz and .sh scripts located in the given package folder.

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# Sanity checks
if [ $# -ne 1 ]
  then
    echo "error: No module data location specified as command line argument"
    exit 1
fi

if [ ! -d $1 ]; then
    echo "error: Source directory $1 does not exist"
    exit 1
fi

# Perform all actions as $POSTGRES_USER
file_env 'POSTGRES_USER' 'postgres'
file_env 'POSTGRES_PASSWORD'

echo
        echo "processing $1"
echo

export PGPASSWORD="${PGPASSWORD:-$POSTGRES_PASSWORD}"
psql=( psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --no-password )

echo
for f in $1/*; do
    case "$f" in
        *.sh)
            # https://github.com/docker-library/postgres/issues/450#issuecomment-393167936
            # https://github.com/docker-library/postgres/pull/452
            if [ -x "$f" ]; then
                echo "$0: running $f"
                "$f"
            else
                echo "$0: sourcing $f"
                . "$f"
            fi
            ;;
        *.sql)    echo "$0: running $f"; "${psql[@]}" -f "$f"; echo ;;
        *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${psql[@]}"; echo ;;
        *)        echo "$0: ignoring $f" ;;
    esac
    echo
done


unset PGPASSWORD

echo
		echo "PostgreSQL update process for $1 complete."
echo

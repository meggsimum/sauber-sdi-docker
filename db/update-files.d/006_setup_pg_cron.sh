#!/bin/bash

if [ -z "$PGDATA" ]
    then
        echo "ERROR: \$PGDATA is empty."
    else
        echo "Setting up pg_cron config..."
fi

# Check if pg_cron configurations already set, else set them

if grep -q pg_cron "$PGDATA/postgresql.conf"
    then
        echo "pg_config already set "
    else
        sed -i "s/shared_preload_libraries = '/shared_preload_libraries = 'pg_cron,/" $PGDATA/postgresql.conf
        echo "cron.database_name = 'sauber_data'" >> $PGDATA/postgresql.conf
        echo "Finished pg_cron config. Restarting..."

        # Need to restart server 
        source /usr/local/bin/docker-entrypoint.sh
        docker_temp_server_stop postgres
        docker_temp_server_start postgres

fi

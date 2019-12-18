# Set roles and create PGREST structure
# Seach for 'STEP' comments for key steps


#Read docker secrets 
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
	echo "$var,$val"
	export "$var"="$val"
	unset "$fileVar" 
}


# STEP 1: Secrets to be read by above script. Add other secrets if necessary
secrets=(
    SAUBER_USER_PASSWORD
    SAUBER_MANAGER_PASSWORD
)

for e in "${secrets[@]}"; do
		file_env "$e"
done

# Check if all envs are set
envs=(
    SAUBER_USER_PASSWORD
    SAUBER_MANAGER_PASSWORD
)

for e in "${envs[@]}"; do
	if [ -z ${!e:-} ]; then
		echo "error: $e is not set"
		exit 1
	fi
done

#STEP 2: Create roles for database cluster in template DB
# The functions check if a user already exists to avoid issues with re-deploying the DB service...
# on an existing volume, i.e. avoid errors when trying to drop users with dependencies 
echo "Creating users"
psql -U "${POSTGRES_USER}" -q<<-'EOSQL'
    DO
    $do$
    BEGIN
    IF NOT EXISTS (
        SELECT                       
        FROM   pg_catalog.pg_roles
        WHERE  rolname = 'sauber_user') THEN
        CREATE USER sauber_user;
        RAISE NOTICE 'Created user role';
    END IF;
    END
    $do$;
    DO
    $do$
    BEGIN
    IF NOT EXISTS (
        SELECT                       
        FROM   pg_catalog.pg_roles
        WHERE  rolname = 'sauber_manager') THEN
        CREATE USER sauber_manager;
        RAISE NOTICE 'Created manager role';
    END IF;
    END
    $do$;
EOSQL


#STEP 3: Set passwords from above. 

echo "Setting secrets"
psql -q -U "${POSTGRES_USER}" -c "ALTER USER sauber_manager PASSWORD '$SAUBER_USER_PASSWORD'; ALTER USER sauber_user PASSWORD '$SAUBER_MANAGER_PASSWORD';"
#! /bin/bash
source $SECRETS_KEYS
echo "dppass: $DB_PASS"
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=$DB_PASS -e POSTGRES_DB=mpsdb -e  POSTGRES_USER=mpsroot --name dp_db_cfgsvc  postgres

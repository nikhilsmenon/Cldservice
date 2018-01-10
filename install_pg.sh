#! /bin/bash
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=pguser -e POSTGRES_DB=mpsdb -e  POSTGRES_USER=mpsroot --name dp_db_cfgsvc  postgres
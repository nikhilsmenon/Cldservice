#! /bin/bash
source $SECRETS_KEYS
echo "dppass: $DB_PASS"
docker stop dp_db_cfgsvc
docker rm dp_db_cfgsvc
echo -e "cfgsvc\ncfgsvc" | (adduser cfgsvcdb)
echo -e "cfgsvc123\ncfgsvc123" | (passwd cfgsvcdb)
sed -i "s/PasswordAuthentication*/PasswordAuthentication yes/g" /etc/ssh/sshd_config > /etc/ssh/sshd_config
sed "s/PermitRootLogin */PermitRootLogin yes/g" /etc/ssh/sshd_config > /etc/ssh/sshd_config
usermod -aG sudo cfgsvcdb
service ssh restart

echo "------------------------------list of available user---------------------------------"
awk -F':' '{ print $1}' /etc/passwd
echo "-----------------------------------------------------------------------------------------"
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=$DB_PASS -e POSTGRES_DB=mpsdb -e  POSTGRES_USER=mpsroot --name dp_db_cfgsvc  postgres

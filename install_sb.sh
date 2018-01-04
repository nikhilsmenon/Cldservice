#!/bin/bash
source /etc/environment
if [[ -n "$stylebook_buildno" ]]; then echo "The stylebook build no  is $stylebook_buildno"; else  export  stylebook_buildno="stylebook"; fi
aws configure set aws_access_key_id $access_key
aws configure set aws_secret_access_key $secret_key
aws configure set default.region us-east-2

login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login
stylebook_image="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable:$stylebook_buildno"

docker pull $stylebook_image
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
#docker  rmi -f $(docker images |  awk -e '{print $3}')
source $SECRETS_KEYS
source $USER_DATA_ENV

CURR_HOST=`hostname -I | cut -d' ' -f1`
SB_SERVER=$CURR_HOST

container_name="dp_cfgsvc"

sed -i 's/scripts-user$/\[scripts-user, always\]/' /etc/cloud/cloud.cfg

SB_DB_STR="DRIVER=PostgreSQL_unixODBC;DATABASE=$DB_NAME;SERVER=$DB_HOST;PORT=$DB_PORT;UID=$DB_USER;PWD=$DB_PASS;"
docker run -it -d -p 5800:5800  -e STYLEBOOK_MODE=container -e NSSTYLEBOOK_DB_CONNECTION_STR=$SB_DB_STR --name "${container_name}_stylebook" $stylebook_image

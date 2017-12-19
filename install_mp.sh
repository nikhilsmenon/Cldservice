#!/bin/bash

if [[ -n "$CFGSVC_BUILD" ]]; then echo "The cfgsvc build no  is $CFGSVC_BUILD"; else  export  CFGSVC_BUILD="210"; fi
login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login
docker pull 252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-mgmt-dev/stable:$CFGSVC_BUILD
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker  rmi -f $(docker images |  awk -e '{print $3}')
mgmtpop_cfgsvc="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-mgmt-dev/stable:$CFGSVC_BUILD"
DB_USER=mpsroot
DB_PASS=pguser123
DB_PORT=5432
DB_NAME=mpsdb
sed -i 's/scripts-user$/\[scripts-user, always\]/' /etc/cloud/cloud.cfg
source /etc/environment
cp dev-pub /home/ubuntu/.ssh/authorized_keys
echo "$POP_ID"
container_name="${POP_ID}BUILD201"
MSG_CA_CERTS_FILE_PATH=/etc/ssl/certs/ca-certificates.crt
docker run -d  --restart=always  -v "/var/log":"/var/log" -e TRUST_SVC_AUTH="CWSAuth" -e   NEW_RELIC_LICENSE_KEY=$NEW_RELIC_LICENSE_KEY --log-driver=splunk --log-opt splunk-token=$SPLUNK_TOKEN --log-opt splunk-url="https://http-inputs-citrixsys.splunkcloud.com" --log-opt splunk-sourcetype=container:$container_name --log-opt splunk-format=json   --log-opt splunk-source=container:$container_name --log-opt tag="{{.Name}}_{{.ID}}"  -e CONFIG_SVC_ALL_DATAPOPS_TOPIC=$ALL_DATA_TOPIC -e CONFIG_SVC_MGMTPOP_TOPIC=$MGMT_TOPIC -e POP_ID=$POP_ID -e  DB_PORT=$DB_PORT  -e DB_HOST=$DB_HOST -e DB_PASS=$DB_PASS -e DB_USER=$DB_USER  -e DB_NAME=$DB_NAME -e WAF_CALLBACK=$SERVICE_CALLBACK -e NGS_CALLBACK=$SERVICE_CALLBACK  -e PRIVATE_KEY=$PRIVATE_KEY -e SERVICE_NAME=$SERVICE_NAME -e MESSAGING_SERVER_URL=$MESSAGING_SERVER  -p 5001:5001  --name $container_name $mgmtpop_cfgsvc

sleep 10

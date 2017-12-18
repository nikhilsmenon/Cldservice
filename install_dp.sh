#!/bin/bash

CFGSVC_LOGFILE="/var/log/cfgsvc.log"
sudo touch $CFGSVC_LOGFILE
sudo chmod 0777 $CFGSVC_LOGFILE

cfgsvc_buildno="210"
image=252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable
if [ -z "$1" ];then
    echo "No argument supplied" >> $CFGSVC_LOGFILE
else
    cfgsvc_buildno=$1
    image="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable:$cfgsvc_buildno"
    if [ ! -z $access_key ];then
	aws configure set aws_access_key_id $access_key
	aws configure set aws_secret_access_key $secret_key
	aws configure set default.region us-east-2
  
	login_cmd=` echo aws ecr get-login --registry-ids 252210149234 --no-include-email`
	docker_login=`eval $login_cmd`
	echo $docker_login >> $CFGSVC_LOGFILE
	eval $docker_login
	docker stop $(docker ps -a -q)
	docker rm $(docker ps -a -q)
	docker rmi -f $(docker images -a -q)
	docker pull $image
	echo "stopped container; removed image and pulled new image" >> $CFGSVC_LOGFILE
	echo "$(docker images | grep 'cfg')" >> $CFGSVC_LOGFILE
    fi
fi
KSTORE_SERVER=172.16.8.99:7379


DB_USER="mpsroot"
DB_PASS="pguser"
DB_HOST="172.16.7.101"
DB_PORT=5432
DB_NAME=mpsdb

DB_CONN_STR="postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME"
echo $DB_CONN_STR >> $CFGSVC_LOGFILE

MY_IP=$(ifconfig | grep 'inet' | grep '172.16.7' | awk '{print $2}' | sed 's/addr://') #grep -v 172 added to avoid docker ip
echo $MY_IP >> $CFGSVC_LOGFILE
DP1_SB_PORT=5800
DP1_SB_SERVER=$MY_IP
DP1_INV_PORT=5002
DP1_INV_SERVER=$MY_IP

echo $DP1_SB_PORT >> $CFGSVC_LOGFILE
echo $DP1_SB_SERVER >> $CFGSVC_LOGFILE
echo $DP1_INV_PORT >> $CFGSVC_LOGFILE
echo $DP1_INV_SERVER >> $CFGSVC_LOGFILE
#INSTANCE_ID=e59b05fc-e547-4a52-a461-2cfe81554a80
MSG_CA_CERTS_FILE_PATH="/etc/ssl/certs/ca-certificates.crt"


echo "--------------------------------------------------------------------------------------------"

cat  /etc/environment >> $CFGSVC_LOGFILE
. /etc/environment

docker run -d --restart=always -v "/var/log":"/var/log" -v /etc/hosts:/etc/hosts -v ${MSG_CA_CERTS_FILE_PATH}:/app/cfgsvc/ca.cert -e MSG_CA_CERTS_FILE_PATH=$MSG_CA_CERTS_FILE_PATH -e KVSTORE_SERVER=$KVSTORE_SERVER -e PRIVATE_KEY=$PRIVATE_KEY -e NEW_RELIC_LICENSE_KEY=$NEWRELIC_KEY -e SERVICE_NAME=${SERVICE_NAME} -e INSTANCE_ID=${INSTANCE_ID} -e CONFIG_SVC_MGMTPOP_TOPIC=$MGMT_TOPIC -e CONFIG_SVC_ALL_DATAPOPS_TOPIC=$ALL_DATA_TOPIC -e POP_ID=$POP_ID -e MGMT_DATAPOP_ID=$MGMT_POP_ID -e DB_CONN_STR=$DB_CONN_STR -e DB_PORT=$DB_PORT  -e DB_HOST=$DB_HOST -e DB_PASS=$DB_PASS -e DB_NAME=$DB_NAME -e STYLEBOOK_SERVER=$DP1_SB_SERVER:$DP1_SB_PORT -e INVENTORY_SERVER=$DP1_INV_SERVER:$DP1_INV_PORT  -e MESSAGING_SERVER_URL=$MESSAGING_SERVER_URL -p 5000:5000 -p 5002:5002 --name dp1_cfgsvc $image --log-driver=splunk --log-opt splunk-token=$SPLUNK_TOKEN --log-opt splunk-url="https://http-inputs-citrixsys.splunkcloud.com" --log-opt splunk-sourcetype=container:${POP_ID}dp1_cfgsvc --log-opt splunk-format=json -e SERVICE_TYPE=$SERVICE_TYPE --log-opt splunk-source=container:dp_cfgsvc --log-opt tag="${image}/dp1_cfgsvc/${POP_ID}"

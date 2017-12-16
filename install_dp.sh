#!/bin/bash
echo "i am instakk "
exit 1
if [[ -n "$CFGSVC_BUILD" ]]; then echo "The cfgsvc build no  is $CFGSVC_BUILD"; else  export  CFGSVC_BUILD="210"; fi
aws configure set aws_access_key_id $access_key
aws configure set aws_secret_access_key $secret_key
aws configure set default.region us-east-2

stylebook_image="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable:$STYLEBOOK_BUILD"
data_image="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable:$CFGSVC_BUILD"

login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login
docker stop $(docker ps -aq)
docker rm $(docker ps –aq)
docker  rmi -f $(docker images |  awk -e '{print $3}')
if [[ "$pop_type" == "data" ]] ; then  docker pull $stylebook_image; fi
docker pull $data_image

CURR_HOST=`hostname -I | cut -d' ' -f1`
SERVICE_TYPE="WAF"
#remove all this - should set in env file
DB_USER=mpsroot
DB_PASS=pguser123
DB_PORT=5432
DB_NAME=mpsdb
DP1_SB_PORT=5800
DP1_SB_SERVER=$CURR_HOST
DP1_INV_PORT=5002
DP1_INV_SERVER=$CURR_HOST
TF_LOG=TRACE
TF_LOG_PATH=/var/log/terraform.log
TF_SKIP_PROVIDER_VERIFY=1
PYTHONPATH="/app/cfgsvc"
container_name="${POP_ID}BUILD${CFGSVC_BUILD}"
echo "--------------------------------------------------------------------------------------------"
SB_DB_STR="DRIVER=PostgreSQL_unixODBC;DATABASE=$DB_NAME;SERVER=$DB_HOST;PORT=$DB_PORT;UID=$DB_USER;PWD=$DB_PASS;"
#docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=pguser123 -e POSTGRES_DB=mpsdb -e  POSTGRES_USER=mpsroot --name mp_db_$ID postgres
MSG_CA_CERTS_FILE_PATH="/etc/ssl/certs/ca-certificates.crt"
docker run -it -d -p $DP1_SB_PORT:5800  -e STYLEBOOK_MODE=container -e NSSTYLEBOOK_DB_CONNECTION_STR=$SB_DB_STR --name "${container_name}_stylebook" $stylebook_image
#make sure that messaging_server_url ip are updated in /etc/hosts in datapop vm

if [[ "$pop_type" == "data" ]] ; then SPLUNK_SOURCE="cfgsvc_dp" ; then SPLUNK_SOURCE="cfgsvc_mp"
if [[ "$service_type" == "ngs" ]] ; then SPLUNK_SOURCETYPE="cfgsvc_ngs" ; then SPLUNK_SOURCETYPE="cfgsvc_waf"
#--env-file /etc/environment (move evrerything from userdata to env file)
#remove AWS_DEF -> DNS_SERVER
docker run -d --restart=always -v "/var/log":"/var/log"  --env-file $USERDATA_  --env-file /etc/env..  -e   NEW_RELIC_LICENSE_KEY=$NEW_RELIC_LICENSE_KEY --log-driver=splunk --log-opt splunk-token=$SPLUNK_TOKEN --log-opt splunk-url="https://http-inputs-citrixsys.splunkcloud.com" --log-opt splunk-sourcetype=container:$SPLUNK_SOURCETYPE --log-opt splunk-format=json   --log-opt splunk-source=container:$SPLUNK_SOURCE --log-opt tag="{{.Name}}_{{.ID}}"  -e AWS_DEFAULT_REGION=$REGION -e TRUST_SVC_AUTH="CWSAuth" -e PYTHONPATH=$PYTHONPATH -e TF_SKIP_PROVIDER_VERIFY=$TF_SKIP_PROVIDER_VERIFY -e TF_LOG_PATH=$TF_LOG_PATH -e TF_LOG=$TF_LOG -e PRIVATE_KEY=$PRIVATE_KEY -e CITRIX_SECRET=$CITRIX_SECRET -e CITRIX_ID=$CITRIX_ID -e MAS_AGENT_IP=$MAS_AGENT_IP -e MAS_DEVICEPROFILE=$MAS_DEVICEPROFILE -e MAS_AGENT_ID=$MAS_AGENT_ID -e MAS_URL=$MAS_URL -e SVC_NODE_BOOTSTRAP_SB=$SVC_NODE_BOOTSTRAP_SB  -e DNS_CUSTOMER_NAME=$DNS_CUSTOMER_NAME -e SVC_NODE_CLIENT_SVC_GRP=$SVC_NODE_CLIENT_SEC_GRP -e SVC_NODE_CLIENT_SUBNET=$SVC_NODE_CLIENT_SUBNET -e SVC_NODE_MGMT_SVC_GRP=$SVC_NODE_MGMT_SEC_GRP -e SVC_NODE_MGMT_SUBNET=$SVC_NODE_MGMT_SUBNET -e SVC_NODE_AMI=$SVC_NODE_AMI -e SVC_NODE_INSTANCE_TYPE=$SVC_NODE_INSTANCE_TYPE -e SVC_NODE_SERVER_SUBNET=$SVC_NODE_SERVER_SUBNET  -e SVC_NODE_SERVER_SUBNET_MASK=$SVC_NODE_SERVER_SUBNET_MASK -e SVC_NODE_SERVER_SVC_GRP=$SVC_NODE_SERVER_SEC_GRP -e SERVICE_TYPE=$SERVICE_TYPE -e CW_SERVICE_NAME=${CW_SERVICE_NAME} -e DNS_DEFAULT_ZONE=${DNS_DEFAULT_ZONE} -e CW_PRIVATE_KEY=${CW_PRIVATE_KEY} -e PRIVATE_KEY=$PRIVATE_KEY -e SERVICE_NAME=${SERVICE_NAME} -e INSTANCE_ID=${INSTANCE_ID} -e CONFIG_SVC_MGMTPOP_TOPIC=$MGMT_TOPIC -e CONFIG_SVC_ALL_DATAPOPS_TOPIC=$ALL_DATA_TOPIC -e POP_ID=$POP_ID -e MGMT_DATAPOP_ID=$MGMT_POP_ID -e DB_PORT=$DB_PORT -e DB_USER=$DB_USER   -e DB_HOST=$DB_HOST -e DB_PASS=$DB_PASS -e DB_NAME=$DB_NAME -e STYLEBOOK_SERVER=$DP1_SB_SERVER:$DP1_SB_PORT -e INVENTORY_SERVER=$DP1_INV_SERVER:$DP1_INV_PORT  -e MESSAGING_SERVER_URL=$MESSAGING_SERVER_URL -e SVC_NODE_PASSWORD=$SVC_NODE_PASSWORD -e IPAM_SERVER=$IPAM_SERVER -e DNS_SERVER=$DNS_SERVER  -p 5000:5000 -p 5002:5002 --name $container_name $data_image

sed -i 's/scripts-user$/\[scripts-user, always\]/' /etc/cloud/cloud.cfg
#based on env
cp /home/ubuntu/dev-pub /home/ubuntu/.ssh/authorized_keys

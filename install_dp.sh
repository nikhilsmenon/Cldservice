#!/bin/bash
source /etc/environment
if [[ -n "$cfgsvc_buildno" ]]; then echo "The cfgsvc build no  is $cfgsvc_buildno"; else  export  cfgsvc_buildno="216"; fi
aws configure set aws_access_key_id $access_key
aws configure set aws_secret_access_key $secret_key
aws configure set default.region us-east-2

login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login

datapop_cfgsvc="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable:$cfgsvc_buildno"

docker pull $datapop_cfgsvc


#docker  rmi -f $(docker images |  awk -e '{print $3}')
source $SECRETS_KEYS
export SOURCE_TYPE=""
export SOURCE=""
export SPLUNK_TOKEN=""
export  SERVICE_TYPE=""
CURR_HOST=`hostname -I | cut -d' ' -f1`
SB_SERVER=$CURR_HOST
DP_INV_PORT=5002
DP_INV_SERVER=$CURR_HOST
TF_LOG=ERROR
TF_LOG_PATH=/var/log/terraform.log
TF_SKIP_PROVIDER_VERIFY=1
PYTHONPATH="/app/cfgsvc"

typeset -l service_type
if [[ "$service_type" == "ngs" ]]; then
     echo " service is ngs , setting the requied details  "
      SPLUNK_TOKEN=$NGS_DP_SPLUNK_TOKEN
      SOURCE_TYPE="dp_cfgsvc"
      SERVICE_TYPE="NGS"
      SOURCE="cfgsvc_ngs"
else
  echo "service type is waf , setting the required details "
  SPLUNK_TOKEN=$WAF_DP_SPLUNK_TOKEN
  SOURCE_TYPE="dp_cfgsvc"
  SERVICE_TYPE="WAF"
  SOURCE="cfgsvc_waf"
fi

echo "pop id : $POP_ID"

container_name="dp_cfgsvc"

sed -i 's/scripts-user$/\[scripts-user, always\]/' /etc/cloud/cloud.cfg

docker run -d  --restart=always  -v "/var/log":"/var/log" -e TRUST_SVC_AUTH="CWSAuth" --env-file $SECRETS_KEYS --env-file  $USER_DATA_ENV -e SERVICE_TYPE=$SERVICE_TYPE -e SB_SERVER=$SB_SERVER:5800 -e DP_INV_PORT=$DP_INV_PORT -e DP_INV_SERVER=$DP_INV_SERVER -e TF_LOG=$TF_LOG -e TF_LOG_PATH=$TF_LOG_PATH -e TF_SKIP_PROVIDER_VERIFY=$TF_SKIP_PROVIDER_VERIFY -e PYTHONPATH=$PYTHONPATH --log-driver=splunk --log-opt splunk-token=$SPLUNK_TOKEN --log-opt splunk-url="https://http-inputs-citrixsys.splunkcloud.com" --log-opt splunk-sourcetype=container:$SOURCE_TYPE --log-opt splunk-format=json   --log-opt splunk-source=container:$SOURCE --log-opt tag="{{.Name}}_{{.ID}}"  -p 5000:5000 -p 5002:5002 --name $container_name $datapop_cfgsvc





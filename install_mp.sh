#!/bin/bash
if [[ -n "$CFGSVC_BUILD" ]]; then echo "The cfgsvc build no  is $CFGSVC_BUILD"; else  export  CFGSVC_BUILD="210"; fi
login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login
docker pull 252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-mgmt-dev/stable:$CFGSVC_BUILD
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
# docker  rmi -f $(docker images |  awk -e '{print $3}')
mgmtpop_cfgsvc="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-mgmt-dev/stable:$CFGSVC_BUILD"
sed -i 's/scripts-user$/\[scripts-user, always\]/' /etc/cloud/cloud.cfg
export SPLUNK_TOKEN=""
export SOURCE_TYPE=""
export SOURCE=""
source $SECRETS_KEYS
echo $NGS_MP_SPLUNK_TOKEN
exh
if [[ "$service_type" == "ngs" ]]; then
     echo " service is ngs , setting the requied details  "
     SPLUNK_TOKEN=$NGS_MP_SPLUNK_TOKEN
     SOURCE_TYPE="mp_cfgsvc"
     SOURCE="cfgsvc_ngs"
else
  echo "service type is waf , setting the required details "
fi

echo "pop id : $POP_ID"

container_name="mp_cfgsvc"
docker run -d  --restart=always  -v "/var/log":"/var/log" -e TRUST_SVC_AUTH="CWSAuth" --env-file $SECRETS_KEYS --env-file  $USER_DATA_ENV  --log-driver=splunk --log-opt splunk-token=$SPLUNK_TOKEN --log-opt splunk-url="https://http-inputs-citrixsys.splunkcloud.com" --log-opt splunk-sourcetype=container:$SOURCE_TYPE --log-opt splunk-format=json   --log-opt splunk-source=container:$SOURCE --log-opt tag="{{.Name}}_{{.ID}}"  -p 5001:5001  --name $container_name $mgmtpop_cfgsvc

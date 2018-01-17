#!/bin/bash
source /etc/environment
if [[ -n "$cfgsvc_buildno" ]]; then echo "The cfgsvc build no  is $cfgsvc_buildno"; else  export  cfgsvc_buildno="222"; fi
login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login
mgmtpop_cfgsvc="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-mgmt-dev/stable:$cfgsvc_buildno"

docker pull $mgmtpop_cfgsvc
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
#docker  rmi -f $(docker images |  awk -e '{print $3}')
echo -e "cfgsvc\ncfgsvc" | (adduser cfgsvcmp)
echo -e "cfgsvc123\ncfgsvc123" | (passwd cfgsvcmp)
sed -i "s/PasswordAuthentication*/PasswordAuthentication yes/g" /etc/ssh/sshd_config > /etc/ssh/sshd_config
sed "s/PermitRootLogin */PermitRootLogin yes/g" /etc/ssh/sshd_config > /etc/ssh/sshd_config
usermod -aG sudo cfgsvcmp
service ssh restart
awk -F':' '{ print $1}' /etc/passwd

source $SECRETS_KEYS
echo $SECRETS_KEYS
echo $USER_DATA_ENV
export SOURCE_TYPE=""
export SOURCE=""
export SPLUNK_TOKEN=""
echo "$NGS_MP_SPLUNK_TOKEN"
typeset -l service_type
if [[ "$service_type" == "ngs" ]]; then
     echo " service is ngs , setting the requied details  "
      SPLUNK_TOKEN=$NGS_MP_SPLUNK_TOKEN
      SOURCE_TYPE="mp_cfgsvc"
      SOURCE="cfgsvc_ngs"
      SERVICE_TYPE="NGS"
else
  echo "service type is waf , setting the required details "
  SPLUNK_TOKEN=$WAF_MP_SPLUNK_TOKEN
  SOURCE_TYPE="mp_cfgsvc"
  SOURCE="cfgsvc_waf"
  SERVICE_TYPE="WAF"
fi

echo "pop id : $POP_ID"

container_name="mp_cfgsvc_$environment"

mgmtpop_cfgsvc="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-mgmt-dev/stable:$cfgsvc_buildno"
sleep 10
sed -i 's/scripts-user$/\[scripts-user, always\]/' /etc/cloud/cloud.cfg

sleep 10
MSG_CA_CERTS_FILE_PATH=/etc/ssl/certs/ca-certificates.crt
docker run -d  --restart=always  -v "/var/log":"/var/log" -e TRUST_SVC_AUTH="CWSAuth" --env-file $SECRETS_KEYS --env-file  $USER_DATA_ENV -e MSG_CA_CERTS_FILE_PATH=$MSG_CA_CERTS_FILE_PATH  --log-driver=splunk --log-opt splunk-token=$SPLUNK_TOKEN --log-opt splunk-url="https://http-inputs-citrixsys.splunkcloud.com" --log-opt splunk-sourcetype=container:$SOURCE_TYPE --log-opt splunk-format=json   --log-opt splunk-source=container:$SOURCE --log-opt tag="{{.Name}}_{{.ID}}"  -p 5001:5001  --name $container_name $mgmtpop_cfgsvc

if [ -f "/var/cwcdone.txt"  ]; then
echo "cwc download is completed "
#cp /var/cfgsvc/authorized_keys  ~/.ssh/authorized_keys
done=`cat /var/cfgsvc/authorized_keys > ~/.ssh/authorized_keys`
fi


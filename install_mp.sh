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
 sed -i 's/scripts-user$/\[scripts-user, always\]/' /etc/cloud/cloud.cfg
 source /etc/environment
 export SPLUNK_TOKEN=""
 case "$service_type" in
             "ngs")
             echo " service is ngs , setting the requied details  "
             export SPLUNK_TOKEN=$NGS_MP_SPLUNK_TOKEN
             export SOURCE_TYPE="mp_cfgsvc"
             export SOURCE="cfgsvc_ngs"
             shift # past argument 
             ;;
            "waf")
             echo "service type is waf , setting the required details "
             shift # past argument
             ;;
 esac
 echo "pop id : $POP_ID"
             
 container_name="mp_cfgsvc"
 docker run -d  --restart=always  -v "/var/log":"/var/log" -e TRUST_SVC_AUTH="CWSAuth" --env-file $AUTHORIZED_KEYS --env-file  $USER_DATA_ENV  --log-driver=splunk --log-opt splunk-token=$SPLUNK_TOKEN --log-opt splunk-url="https://http-inputs-citrixsys.splunkcloud.com" --log-opt splunk-sourcetype=container:$SOURCE_TYPE --log-opt splunk-format=json   --log-opt splunk-source=container:$SOURCE --log-opt tag="{{.Name}}_{{.ID}}"  -p 5001:5001  --name $container_name $mgmtpop_cfgsvc
 sleep 10
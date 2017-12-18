#!/bin/bash

export SSH_TESTING_KEYS="/var/cfgsvc_config/authorized_keys_testing"
export SSH_STAGING_KEYS="/var/cfgsvc_config/authorized_keys_staging"
export SSH_PRODUCTION_KEYS="/var/cfgsvc_config/authorized_keys_production"

export TESTING_KEYS="/var/cfgsvc_config/testing.env"
export STAGING_KEYS="/var/cfgsvc_config/staging.env"
export PRODUCTION_KEYS="/var/cfgsvc_config/production.env"
export SECRET_DIR="/var/cfgsvc_config"
export BOOTSTRAP_DIR="/var/cfgsvc"
aws configure set aws_access_key_id $access_key
aws configure set aws_secret_access_key $secret_key
aws configure set default.region us-east-2

cwc_image="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable:testcwc"

login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login
stopcont=`docker stop $(docker ps -aq)`
rmcont=`docker rm $(docker ps -aq)`
#docker  rmi -f $(docker images |  awk -e '{print $3}')
docker pull $cwc_image

curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/cwcget.py  -o $BOOTSTRAP_DIR/cwcget.py

CURR_HOST=`hostname -I | cut -d' ' -f1`
echo "$CURR_HOST"
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=pguser -e POSTGRES_DB=mpsdb -e  POSTGRES_USER=mpsroot --name localdb postgres 
docker run -d --restart=always -e TRUST_SVC_AUTH="CWSAuth"   -e MESSAGING_SERVER_URL="djehdje" -e CW_SERVICE_NAME=$CFGSVC_CW_SERVICE_NAME -e DB_USER=mpsroot -e CW_PRIVATE_KEY=$CFGSVC_CW_PRIVATE_KEY -e DB_PORT=5432 -e DB_HOST=$CURR_HOST -e DB_PASS=pguser -e DB_NAME=mpsdb  -p 5000:5000 -p 5002:5002 --name cwcget $cwc_image
docker cp $BOOTSTRAP_DIR/cwcget.py cwcget:/app/cfgsvc
if [ ! -d "$SECRET_DIR"  ]; then
  mkdir $SECRET_DIR
  echo "MAIN director \" $SECRET_DIR \" is created "

fi

#while read line; do    
#    echo $line 
#    IFS='=' read -r key value <<< "$line"
#    key="TST_$key"      
#    echo $key
#    echo $value
#    docker exec -t cwcget python cwcget.py cfgsvccwc upload $key $value
    
#done < 16057/testing_ssh.env
docker exec -t cwcget python cwcget.py cfgsvccwc getall $1 ""
docker cp cwcget:/app/cfgsvc/cwckeys.env $BOOTSTRAP_DIR
#grep '^TST_' cwckeys.env > tmp.env
sed 's/^.\{,4\}//' /$BOOTSTRAP_DIR/cwckeys.env > $TESTING_KEYS
grep '^'$1'_SSH' $BOOTSTRAP_DIR/cwckeys.env > $BOOTSTRAP_DIR/tmp.env
sed 's/^.\{,12\}//' $BOOTSTRAP_DIR/tmp.env > $SSH_TESTING_KEYS 

#docker exec -t cwcget python cwcget.py cfgsvccwc getall STG ""
#docker cp cwcget:/app/cfgsvc/cwckeys.env .
#grep '^STG_' cwckeys.env > tmp.env

#sed 's/^.\{,4\}//' cwckeys.env  > $STAGING_KEYS
#grep '^TST_SSH' cwckeys.env > tmp.env
#sed 's/^.\{,12\}//' tmp.env > $SSH_STAGING_KEYS


#docker exec -t cwcget python cwcget.py cfgsvccwc getall PRD ""
#docker cp cwcget:/app/cfgsvc/cwckeys.env .
#grep '^PRD_' cwckeys.env > tmp1.env
#sed 's/^.\{,4\}//' cwckeys.env > $PRODUCTION_KEYS
#grep '^PRD_SSH' cwckeys.env > tmp.env
#sed 's/^.\{,12\}//' tmp.env > $SSH_PRODUCTION_KEYS

#docker exec -it cwcget python cwcget.py cfgsvccwc upload test11 $x
#docker exec  -it cwcget python cwcget.py cfgsvccwc getvalue test

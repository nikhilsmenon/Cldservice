#!/bin/bash

export SSH_KEYS="/var/cfgsvc/authorized_keys"
export SECRETS_KEYS="/var/cfgsvc/secret.env"
export SECRET_DIR="/var/cfgsvc"
export BOOTSTRAP_DIR="/var/cfgsvc"
source /var/ecr.env

aws configure set aws_access_key_id $access_key
aws configure set aws_secret_access_key $secret_key
aws configure set default.region us-east-2

cwc_image="252210149234.dkr.ecr.us-east-2.amazonaws.com/cfg-data-dev/stable:ctestcwc"
login_cmd=` echo aws ecr get-login --registry-ids 252210149234 `
docker_login=`eval $login_cmd`
echo $docker_login
eval $docker_login
stopcont=`docker stop $(docker ps -aq)`
rmcont=`docker rm $(docker ps -aq)`
#docker  rmi -f $(docker images |  awk -e '{print $3}')
docker pull $cwc_image
if [ ! -f "$BOOTSTRAP_DIR/cwcget.py"  ]; then
echo "cwcget.py doesnot exist , hence pulling"
curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/cwcget.py  -o $BOOTSTRAP_DIR/cwcget.py
sleep 3
fi
CURR_HOST=`hostname -I | cut -d' ' -f1`
echo "$CURR_HOST"
if [ ! -f "$BOOTSTRAP_DIR/cwckeys.env"  ]; then
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=pguser -e POSTGRES_DB=mpsdb -e  POSTGRES_USER=mpsroot --name localdb postgres 
docker run -d -it --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -e TRUST_SVC_AUTH="CWSAuth"   -e MESSAGING_SERVER_URL="djehdje" --env-file /var/ecr.env -e DB_USER=mpsroot  -e DB_PORT=5432 -e DB_HOST=$CURR_HOST -e DB_PASS=pguser -e DB_NAME=mpsdb  -p 5000:5000 -p 5002:5002 --name cwcget $cwc_image
docker wait cwcget
sleep 10
docker wait cwcget
docker cp $BOOTSTRAP_DIR/cwcget.py cwcget:/app/cfgsvc
fi
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
if [ ! -f "$BOOTSTRAP_DIR/cwckeys.env"  ]; then
   #docker_exec=`docker exec -i cwcget bash -c "python cwcget.py cfgsvccwc getall $1 '' " && echo "pass" || echo "fail"`
   docker_exec=`docker exec -i cwcget bash -c "python cwcget.py cfgsvccwc getall $1 '' > log.txt " && echo "pass" || echo "fail" > log.txt`
   docker_exec=`docker exec -i cwcget bash -c "python cwcget.py cfgsvccwc getall $1 '' > log.txt " && echo "pass" || echo "fail" > log.txt`
   docker_exec=`docker exec -i cwcget bash -c "python cwcget.py cfgsvccwc getall $1 '' > log.txt " && echo "pass" || echo "fail" > log.txt`
   docker_exec=`docker exec -i cwcget bash -c "python cwcget.py cfgsvccwc getall $1 '' > log.txt " && echo "pass" || echo "fail" > log.txt`
   docker_exec=`docker exec -i cwcget bash -c "python cwcget.py cfgsvccwc getall $1 '' > log.txt " && echo "pass" || echo "fail" > log.txt`
else
 docker_exec="pass"
fi
if [[ $docker_exec == *"pass"* ]]; then
  echo "Downloading from CWC is completed"
  docker cp cwcget:/app/cfgsvc/cwckeys.env $BOOTSTRAP_DIR
  grep '^TST_' $BOOTSTRAP_DIR/cwckeys.env > $BOOTSTRAP_DIR/tmp.env
  sed 's/^.\{,4\}//' $BOOTSTRAP_DIR/cwckeys.env > $SECRETS_KEYS
  grep '^'$1'_SSH' $BOOTSTRAP_DIR/cwckeys.env > $BOOTSTRAP_DIR/tmp.env
  sed 's/^.\{,12\}//' $BOOTSTRAP_DIR/tmp.env > $SSH_KEYS 

else
   echo "Failed in downloading a keys from CWC"
   docker_exec=`docker exec -i cwcget bash -c "python cwcget.py cfgsvccwc getall $1 '' > log.txt " && echo "pass" || echo "fail" > log.txt`
fi 

#docker exec -it cwcget python cwcget.py cfgsvccwc upload test11 $x

#docker exec  -it cwcget python cwcget.py cfgsvccwc getvalue test

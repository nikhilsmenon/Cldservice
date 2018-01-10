#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export USER_NAME='nsroot'
export USER_DATA_ENV="/var/cfgsvc/user_data.env"
export CLOUD_PREFIX=""

export AUTHORIZED_KEYS="/home/nsroot/.ssh/authorized_keys"
export SSH_KEYS="/var/cfgsvc/authorized_keys"
export SECRETS_KEYS="/var/cfgsvc/secret.env"
export ENVIRONMENT_KEYS="/etc/environment"
export BOOTSTRAP_DIR="/var/cfgsvc"

echo "" > ~/.ssh/authorized_keys
echo "" > /home/nsroot/.ssh/authorized_keys
echo "" > /home/ubuntu/.ssh/authorized_keys

#export CLOUD_USER_DATA_FILE='/var/lib/cloud/instance/user-data.txt' 
export CLOUD_USER_DATA_FILE='/var/userdata.env'
if [[ "$1" == "azure" ]]; then 
 CLOUD_PLATFORM="azure"
 CLOUD_PREFIX="az"
 cat /var/lib/cloud/instance/user-data.txt > $CLOUD_USER_DATA_FILE
fi
if [[ "$1" == "aws" ]]; then
  CLOUD_PREFIX="aws"
  USER_NAME="ubuntu"
  CLOUD_PLATFORM="aws"
  AUTHORIZED_KEYS="/home/nsroot/.ssh/authorized_keys"
  CLOUD_USER_DATA_FILE='/var/userdata.env'
  
fi
if [[ -n "$1" ]]; then 
   echo ""
else 
CLOUD_PREFIX="aws"
USER_NAME="ubuntu"
CLOUD_PLATFORM="aws"
AUTHORIZED_KEYS="/home/ubuntu/.ssh/authorized_keys"
CLOUD_USER_DATA_FILE='/var/userdata.env'
fi

export bootstrap_status=0
export environment=`grep ENVIRONMENT $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
export deployment_name=`grep DEPLOYMENT_NAME  $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
export zone=`grep -e AWS_DEFAULT_REGION -e zone $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
echo "--------------------Fetching the required variable from userdata-----"
echo "environment is : $environment"
echo "deployment_name is : $deployment_name"
echo "zone is:  $zone"
echo "----------------------Cloud platform $CLOUD_PLATFORM-----------------------------------"


echo "setting the hostname" 
host_ip=`hostname -I | cut -d' ' -f1`
LABEL="-cfgsvc-"
IP=${host_ip//./-}
VMNAME=$CLOUD_PREFIX-$zone$LABEL$IP
echo "hostname : $VMNAME"
hostname $VMNAME
sudo echo "127.0.0.1 $VMNAME" >> /etc/hosts


if [ ! -d "$BOOTSTRAP_DIR"  ]; then
  mkdir $BOOTSTRAP_DIR
  echo "MAIN director \" cfgsvc \" is created " 
 else
   bootstrap_status="1"
   echo "bootstraping is done, all required are already present in /var/cfgsvc" 
fi
echo "--------------------------------------------------------------------------------------"
#echo " setting the authorization keys based on the envirnoment"
cp $CLOUD_USER_DATA_FILE $USER_DATA_ENV

bootstrap_status="0"
if [[ "$bootstrap_status" == "0" ]];then
case "$environment" in
	    "testing")
             echo " deployment type is testing , setting the requied ssh keys and secrets to env "
             if [ ! -f "$BOOTSTRAP_DIR/get_secrets.sh"  ]; then 
                echo "Get_secret not exist , hence pulling"
                curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/get_secrets.sh  -o $BOOTSTRAP_DIR/get_secrets.sh
                sleep 3
             fi
             chmod 777 $BOOTSTRAP_DIR/get_secrets.sh
             echo "executing get_secrets ......"
             bash $BOOTSTRAP_DIR/get_secrets.sh "TST" 
             sleep 2
	    shift # past argument
	    ;;
	   "staging")
            echo " deployment type is staging, setting the requied ssh keys and secrets to env "
            if [ ! -f "$BOOTSTRAP_DIR/get_secrets.sh"  ]; then
             echo "Get_secret not exist , hence pulling"
             curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/get_secrets.sh  -o $BOOTSTRAP_DIR/get_secrets.sh
             sleep 3
            fi
            chmod 777 $BOOTSTRAP_DIR/get_secrets.sh
            echo "executing get_secrets ......"
            sleep 3
            bash $BOOTSTRAP_DIR/get_secrets.sh "STG"
            sleep 2

            echo "MSG_CA_CERTS_FILE_PATH=/etc/ssl/certs/ca-certificates.crt">> $USER_DATA_ENV
	    shift # past argument
	    ;;
	    "production")
               echo " deployment type is production, setting the requied ssh keys and secrets to env "
               if [ ! -f "$BOOTSTRAP_DIR/get_secrets.sh"  ]; then
                  curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/get_secrets.sh  -o $BOOTSTRAP_DIR/get_secrets.sh
                  sleep 3
              fi
              chmod 777 $BOOTSTRAP_DIR/get_secrets.sh
              echo "executing get_secrets ......"
               bash $BOOTSTRAP_DIR/get_secrets.sh "PRD"
            echo "MSG_CA_CERTS_FILE_PATH=/etc/ssl/certs/ca-certificates.crt">> $USER_DATA_ENV
	    shift
	    ;;
esac
fi

echo "AUTHORIZED_KEYS_PATH:$AUTHORIZED_KEYS"
echo "SECRETS_KEYS_PATH :$SECRETS_KEYS"
echo "SSHKEYS_PATH: $SSH_KEYS"


if [ -f  $SSH_KEYS ]; then
 if [ ! -s $SSH_KEYS ]; then
    cp $SSH_KEYS > $AUTHORIZED_KEYS
  fi
fi
if [ -f $SECRETS_KEYS ]; then
 cat $SECRETS_KEYS
fi

fileecount=`find $BOOTSTRAP_DIR -type f | wc -l`
if [[ "$fileecount" == "1" ]]; then
echo ""  #    rm -rf /var/cfgsvc_config
fi

echo "-------------------------------sourcing the the env files---------------------------"
cat $ECR_KEYS 
source /etc/environment
cp /etc/environment $ECR_KEYS
echo "the userdata are  are copied to /etc/env"

echo "-------------------------pulling the script---------------------------------------------"

if [[ "$pop_type" == "mgmt" ]];then
   echo "pulling mgmt pop install script "
   if [ -f $BOOTSTRAP_DIR/install_pg.sh ]; then chmod 777 $BOOTSTRAP_DIR/install_pg.sh; bash $BOOTSTRAP_DIR/install_pg.sh ;
   #if [  -f $BOOTSTRAP_DIR/install_mp.sh  ]; then echo "removing the existing files ";rm -rf $BOOTSTRAP_DIR/install_mp.sh; fi
    else
      curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/install_pg.sh  -o $BOOTSTRAP_DIR/install_pg.sh
      chmod 777 $BOOTSTRAP_DIR/install_pg.sh
      dos2unix $BOOTSTRAP_DIR/install_pg.sh
      bash $BOOTSTRAP_DIR/install_pg.sh
   fi

fi
if [[ "$pop_type" == "data" ]];then
   echo "pulling data pop install script "
   if [  -f $BOOTSTRAP_DIR/install_pg.sh  ]; then chmod 777 $BOOTSTRAP_DIR/install_pg.sh; bash $BOOTSTRAP_DIR/install_pg.sh ;
   else
    curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/install_pg.sh  -o $BOOTSTRAP_DIR/install_pg.sh
    chmod 777 $BOOTSTRAP_DIR/install_pg.sh
    dos2unix $BOOTSTRAP_DIR/install_pg.sh
    bash $BOOTSTRAP_DIR/install_pg.sh
   fi
  
fi

if [ -f "/var/cwcdone.txt"  ]; then
echo "booting  is completed "
chmod 700  ~/.ssh
chmod 600  ~/.ssh/authorized_keys
#cp /var/cfgsvc/authorized_keys  ~/.ssh/authorized_keys
cat /var/cfgsvc/authorized_keys
done=`cat /var/cfgsvc/authorized_keys > ~/.ssh/authorized_keys`
cat /var/cfgsvc/authorized_keys > /home/ubuntu/.ssh/authorized_keys
cat /var/cfgsvc/authorized_keys > /home/nsroot/.ssh/authorized_keys
cat ~/.ssh/authorized_keys

fi

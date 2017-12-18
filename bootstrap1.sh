#!/bin/bash
#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export USER_NAME='nsroot'
export USER_DATA_ENV="/var/cfgsvc/user_data.env"
export CLOUD_PREFIX=""

export AUTHORIZED_KEYS="/home/$USER_NAME/.ssh/authorized_keys"

export SSH_TESTING_KEYS="/var/cfgsvc_config/authorized_keys_testing"
export SSH_STAGING_KEYS="/var/cfgsvc_config/authorized_keys_staging"
export SSH_PRODUCTION_KEYS="/var/cfgsvc_config/authorized_keys_production"

export TESTING_KEYS="/var/cfgsvc_config/testing.env"
export STAGING_KEYS="/var/cfgsvc_config/staging.env"
export PRODUCTION_KEYS="/var/cfgsvc_config/production.env"

export ENVIRONMENT_KEYS="/etc/environment"
export BOOTSTRAP_DIR="/var/cfgsvc"
export ECR_KEYS="/var/cfgsvc_config/ecr.env"
export BUILD_FILE="/var/cfgsvc/build"
export BOOTSTRAP_FILE="/var/cfgsvc/bootstrapped_cfgsvc"

export CLOUD_USER_DATA_FILE='/var/lib/cloud/instance/user-data.txt' 

export bootstrap_status=0
export environment=`grep ENVIRNOMENT $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
export deployment_name=`grep DEPLOYMENT_NAME  $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
export cfgsvc_buildno=`grep CFGSVC_BULDNO $CLOUD_USER_DATA_FILE  | cut -d'=' -f2  | tr -d '"' | tr -d ' '`
export stylebook_buildno=`grep STYLEBOOK_BUILDNO $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
export pop_type=`grep POP_TYPE $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
export service_type=`grep SERVICE_TYPE $CLOUD_USER_DATA_FILE  | cut -d'=' -f2  | tr -d '"' | tr -d ' '`
export zone=`grep AWS_DEFAULT_REGION  $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
export CLOUD_PLATFORM=`grep CLOUD_PLATFORM $CLOUD_USER_DATA_FILE  | cut -d'=' -f2 | tr -d '"' | tr -d ' '`
echo "--------------------Fetching the required variable from userdata-----"
echo "environment is : $environment"
echo "deployment_name is : $deployment_name"
echo "cfgsvc_buildno is : $cfgsvc_buildno"
echo "stylebook_buildno is : $stylebook_buildno"
echo "pop_type is : $pop_type"
echo "service_type is : $service_type"
echo "zone is:  $zone"
echo "CLOUD_PLATFORM is : $CLOUD_PLATFORM"
echo "----------------------Cloud platform $CLOUD_PLATFORM-----------------------------------"

if [[ "$CLOUD_PLATFORM" == "azure"  ]]; then
 CLOUD_PREFIX="az"
else
  CLOUD_PREFIX="aws"
  USER_NAME="ubuntu"
  AUTHORIZED_KEYS="/home/$USER_NAME/.ssh/authorized_keys"

fi
echo "setting the hostname" 
host_ip=`hostname -I | cut -d' ' -f1`
LABEL="-cfgsvc-"
IP=${host_ip//./-}
VMNAME=$CLOUD_PREFIX-$zone$LABEL$IP
echo "hostname : $VMNAME"
hostname $VMNAME
sudo echo "127.0.0.1 $VMNAME" >> /etc/hosts

#echo "Adding the user"
#adduser $USER_NAME --disabled-password
#usermod -aG sudo $USER_NAME
#sudo su - $USER_NAME
#echo "creating the ssh directory"
#mkdir .ssh
#chmod 700 .ssh
#touch .ssh/authorized_keys
#chmod 600 .ssh/authorized_keys

if [ ! -d "$BOOTSTRAP_DIR"  ]; then
  mkdir $BOOTSTRAP_DIR
  echo "MAIN director \" cfgsvc \" is created " 
 else:
   bootstrap_status=1 
fi
echo "--------------------------------------------------------------------------------------"
echo " setting the authorization keys based on the envirnoment"
cp $CLOUD_USER_DATA_FILE $USER_DATA_ENV

 
if [[ "$bootstrap_status" == "0" ]];then
case "$environment" in
	    "testing")
            curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/get_secrets.sh  -o $BOOTSTRAP_DIR/get_secrets.sh
            chmod 777 $BOOTSTRAP_DIR/get_secrets.sh
            bash $BOOTSTRAP_DIR/get_secrets.sh "TST" 
            echo " deployment type is testing , setting the requied ssh keys and secrets to env "
	    cat $SSH_TESTING_KEYS > $AUTHORIZED_KEYS
            cat $TESTING_KEYS >> $ENVIRONMENT_KEYS
            echo "AUTHORIZED_KEYS_PATH:$AUTHORIZED_KEYS"
            echo "SECRETS_KEYS_PATH : $TESTING_KEYS"
            echo "SSHKEYS_PATH: $SSH_TESTING_KEYS"
	    shift # past argument
	    ;;
	   "staging")
            curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/get_secrets.sh  -o $BOOTSTRAP_DIR/get_secrets.sh
            chmod 777 $BOOTSTRAP_DIR/get_secrets.sh
            bash $BOOTSTRAP_DIR/get_secrets.sh "STG"
            echo "deployment type is staging , setting the required ssh keys and secrets to env "
	    cat $SSH_STAGING_KEYS > $AUTHORIZED_KEYS
            cat $STAGING_KEYS >> $ENVIRONMENT_KEYS
            echo "AUTHORIZED_KEYS_PATH:$AUTHORIZED_KEYS"
            echo "SECRETS_KEYS_PATH :$STAGING_KEYS"
            echo "SSHKEYS_PATH: $SSH_STAGING_KEYS"

            echo "MSG_CA_CERTS_FILE_PATH='/etc/ssl/certs/ca-certificates.crt'">> $USER_DATA_ENV
	    shift # past argument
	    ;;
	    "production")
            curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/get_secrets.sh  -o $BOOTSTRAP_DIR/get_secrets.sh
            chmod 777 $BOOTSTRAP_DIR/get_secrets.sh
            bash$BOOTSTRAP_DIR/get_secrets.sh "PRD"
            echo "deployment type is production , setting the required ssh keys and secrets to env"
	    cat $SSH_PRODUCTION_KEYS > $AUTHORIZED_KEYS
            cat $PRODUCTION_KEYS >> $ENVIRONMENT_KEYS
            echo "AUTHORIZED_KEYS_PATH:$AUTHORIZED_KEYS"
            echo "SECRETS_KEYS_PATH :$PRODUCTION_KEYS"
            echo "SSHKEYS_PATH: $SSH_PRODUCTION_KEYS"
            echo "MSG_CA_CERTS_FILE_PATH='/etc/ssl/certs/ca-certificates.crt'">> $USER_DATA_ENV
	    shift
	    ;;
esac
fi
fileecount=`find $BOOTSTRAP_DIR -type f | wc -l`
if [[ "$fileecount" == "1" ]]; then
echo ""  #    rm -rf /var/cfgsvc_config
fi 	

echo "-------------------------------sourcing the the env files---------------------------"
cat $ECR_KEYS >> $ENVIRONMENT_KEYS
source /etc/environment


echo "-------------------------pulling the script---------------------------------------------"

if [[ "$pop_type" == "mgmt" ]];then
   echo "pulling mgmt pop install script "
   if [ -f $BOOTSTRAP_DIR/install_mp.sh ]; then bash $BOOTSTRAP_DIR/install_mp.sh ; fi
   #if [  -f $BOOTSTRAP_DIR/install_mp.sh  ]; then echo "removing the existing files ";rm -rf $BOOTSTRAP_DIR/install_mp.sh; fi
  if [ -f "bootstrap_status"  == "0"]; then 
      curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/install_mp.sh  -o $BOOTSTRAP_DIR/install_mp.sh
      chmod 777 $BOOTSTRAP_DIR/install_mp.sh
      bash $BOOTSTRAP_DIR/install_mp.sh
  fi
fi
if [[ "$pop_type" == "data" ]];then
   echo "pulling data pop install script "
   if [  -f $BOOTSTRAP_DIR/install_dp.sh  ]; then  bash  $BOOTSTRAP_DIR/install_sb.sh ; fi
   if [  -f $BOOTSTRAP_DIR/install_dp.sh  ]; then bash $BOOTSTRAP_DIR/install_dp.sh ; fi
   #if [  -f $BOOTSTRAP_DIR/install_dp.sh  ]; then echo "removing the existing files : dp"; rm -rf  $BOOTSTRAP_DIR/install_dp.sh; fi
   #if [  -f $BOOTSTRAP_DIR/install_sb.sh  ]; then echo "removing the existing file :sb"; rm -rf $BOOTSTRAP_DIR/install_sb.sh; fi
   if [[ "$bootstrap_status" == "0" ]]; then 
      curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/install_dp.sh  -o $BOOTSTRAP_DIR/install_dp.sh
      curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/install_sb.sh  -o $BOOTSTRAP_DIR/install_sb.sh
      chmod 777 *.sh
      sh  $BOOTSTRAP_DIR/install_sb.sh
      sh  $BOOTSTRAP_DIR/install_dp.sh
   fi
fi

fileecount=`find $BOOTSTRAP_DIR -type f | wc -l`
if [[ "$fileecount" == "2" || "$fileecount" == "3" ]]; then
echo "bootstrapping is done , cleanning up the workspace"
bootstrap_status=1 #    rm -rf /var/cfgsvc_config
fi
#(date) cfgsvc_bootstrap.sh: Container has been started"

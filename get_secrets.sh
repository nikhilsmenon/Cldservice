#!/bin/bash

export SSH_TESTING_KEYS="/var/cfgsvc_config/authorized_keys_testing"
export SSH_STAGING_KEYS="/var/cfgsvc_config/authorized_keys_staging"
export SSH_PRODUCTION_KEYS="/var/cfgsvc_config/authorized_keys_production"

export TESTING_KEYS="/var/cfgsvc_config/testing.env"
export STAGING_KEYS="/var/cfgsvc_config/staging.env"
export PRODUCTION_KEYS="/var/cfgsvc_config/production.env"
export SECRET_DIR="/var/cfgsvc_config"
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




CFGSVC_CW_PRIVATE_KEY="PFJTQUtleVZhbHVlPjxNb2R1bHVzPnJ2M2FDTWdZY2xyTVhjK3oxeDdoMG5BTmpXTVc0bGVqQjd3T0h1YkdSMG55UWpDMEFwS0tVd0packdOYk50My82bFJqU25WMzBnVTlSSS9MeVdCVlhPK3RtbWE5OTZIaW54dUROVzhvalVRNDdDcUV5OG9NbHNKZDgzbWRTQTc1c1Nyd042Z1kxRlZXQzdLQzd3SXA4R0w2MG93ZmE2RXY1VWprYngwNVJFZnd0b0Z1b1hkMGlIQ1kyNUxtenFXZlNlYW5CNVlSOTI5Yi9GSDRYc0ttR0hjd2ZqbmZFcjRiZ2JtUFBMZ3RSdjFEd1h2WXhPb0UvQUVJcFJhWWh1SHVlZWZiZGpJM09CWk9GK3EzRlNDbzdSWkVVNnpydTBkY0NhRVB0a2JxMHNnTzMrWXVZUDQzNFNhMEkwTEdIaGxsSkgxZUtOcU93RGhyUGZUckhoWWlPUT09PC9Nb2R1bHVzPjxFeHBvbmVudD5BUUFCPC9FeHBvbmVudD48UD4yaGEvYzJCS2NlcjY5V2I4MW50dkN2dmtvMTRETEJ2eTNQWmwyZ3JZT20xSUMzSHJDTktsNllhaVMwK3FFenA3QlU1emlNa1JNNDBuNmJ5SllSRkd1bjNGaGZIN0hQNWZ0U3lqOHpFeXcrQ2ZFNU45cVZDMUpjRWprcUtuY2dMeklDY0VFd25JSENmVGlyTVBTb1RRSXd0dG1CSThubGNJSEZJN3BIdmN6VE09PC9QPjxRPnpXazNvZmJGaWx5Y0tmU3VsUW5CaVgwb20xT0VOZ2NGTy9sQWdTQWpNVVowWUxyZG9OYndyTkY4ZFYrSkloV1dFd2xxN2JJeVFYdHNlV1g4Tld5ZEloRElCSXZ1MFpWeGpRa1ZQclJBeHVYalh5TU5rSllZN1Z4YUpZRTBGajNkWWtVR0Q0Zk1lZ25YVTd3MlhRQ1YrREdkS0NKRHNGZHpwbUdRL3grM0d1TT08L1E+PERQPmFQOEtyVUZ1bGVuTGFOcHNYOWFOWDN4bVYwQ3J4bEN1WERORVZmVmlwTDU0TVFwblhaZ015S0ZKQVhrWktLaS9FWTd6a0tjODROVFVvbk5pc0pqZ3RHaFk4R1BQd2VXMXJrUVBxc1hFNndqNWpUTTFESThPcDE2VkFjUE5XZGFSdHFrU0RSaG9meVd0Y3RsQ1ExNHQxckZwMGd6MW9rWEVZZDQxV0x0SlVvRT08L0RQPjxEUT5WVENKN2hZV0h5Z0JiRFVhSXAyRk1xeEJwd21nRDNnaDU1bWI4dkdOSnVaOVpaQ2FVaFpTZ3BudThBN0xKT09tOWdZMTNwYkUyUHVESldYeWo0V1lOWVNZTDZxSlJVcWhhVWlYRXdaV3h5YVlnZUJidzljOFIxVEIza1FUZ2hYdU5zOUJrRGRWeWxkQ2dtdlFjQW5LS01FSzJKWTlWR2t3Z1pSOU9oSEJNdGs9PC9EUT48SW52ZXJzZVE+QzhDRFBDR2p4R2VpUmxqOEhNZ1RFQWhxaDZvSWlqVWEvQU1nMmprc2w4d2xkL0ZIV2V6cG9lVFp3cWt6QlRwRWRyR2ZudlhXUWhrSVFBY0c5WDM0YUZsQWRDME83NjJQK1NYdklMZVNZSml0b1FjZklSVFg0MUR6aFFVZmdXYzhTNmdNamFlWlpzQ2hsbm54eVpyaDhnQ0xEUlZLbXVjZG5nRmNlVWM1OUZvPTwvSW52ZXJzZVE+PEQ+QXRBZTJLUkt6RS9NV0RlMkJ0Kyt0cERKanZ2SVN1UW93VCtUSklrR0ovQTIzanlGTUVObHlOYlJWVFdWcWtpZ1RBYUdRQlNxVSt4MG95MENsQjZoMEtnanJNYzVCNG1KS0pDYko5azlHQ1JBRy8vRStiZXFReVFsdVh1N2ZRU01tLzM2TlpMVXIxa2QxSHRPb29QdzQ2WGJyVlhHVFljZVMzdkQvRXRHZCtQL1drcVlDOXVrOGJudE81S2ZoenREN0w2SjhGUTFIRis4YXJBNWl6TUpLOFJhMG9wVTF2ZGxLeG1MZDNmck9vTnFZVHkvN3pvbnR6eUlYcFJ4S1c3WUgrWG9SazEzS1hqWXE0NnJPdXgzL3h2Q00xbnV6MkVSdklZRzZ0b2lFQUdnTnQ2VExBYmhLLzU4SFhRVXNWUzBlKzE2UDRyUjI5Y2lDSEtFVDhOREp3PT08L0Q+PC9SU0FLZXlWYWx1ZT4="
CFGSVC_CW_SERVICE_NAME="cfgsvctestcwc"

curl https://raw.githubusercontent.com/BinduC27/Cldservice/master/cwcget.py  -o /var/cwcget.py

CURR_HOST=`hostname -I | cut -d' ' -f1`
echo "$CURR_HOST"
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=pguser -e POSTGRES_DB=mpsdb -e  POSTGRES_USER=mpsroot --name localdb postgres 
docker run -d --restart=always -e TRUST_SVC_AUTH="CWSAuth"   -e MESSAGING_SERVER_URL="djehdje" -e CW_SERVICE_NAME=$CFGSVC_CW_SERVICE_NAME -e DB_USER=mpsroot -e CW_PRIVATE_KEY=$CFGSVC_CW_PRIVATE_KEY -e DB_PORT=5432 -e DB_HOST=$CURR_HOST -e DB_PASS=pguser -e DB_NAME=mpsdb  -p 5000:5000 -p 5002:5002 --name cwcget $cwc_image
docker cp /var/cwcget.py cwcget:/app/cfgsvc
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
docker exec -t cwcget python cwcget.py cfgsvccwc getall TST ""
docker cp cwcget:/app/cfgsvc/cwckeys.env . 
#grep '^TST_' cwckeys.env > tmp.env
sed 's/^.\{,4\}//' cwckeys.env > $TESTING_KEYS
grep '^TST_SSH' cwckeys.env > tmp.env
sed 's/^.\{,12\}//' tmp.env > $SSH_TESTING_KEYS 

docker exec -t cwcget python cwcget.py cfgsvccwc getall STG ""
docker cp cwcget:/app/cfgsvc/cwckeys.env .
#grep '^STG_' cwckeys.env > tmp.env

sed 's/^.\{,4\}//' cwckeys.env  > $STAGING_KEYS
grep '^TST_SSH' cwckeys.env > tmp.env
sed 's/^.\{,12\}//' tmp.env > $SSH_STAGING_KEYS


docker exec -t cwcget python cwcget.py cfgsvccwc getall PRD ""
docker cp cwcget:/app/cfgsvc/cwckeys.env .
#grep '^PRD_' cwckeys.env > tmp1.env
sed 's/^.\{,4\}//' cwckeys.env > $PRODUCTION_KEYS
grep '^PRD_SSH' cwckeys.env > tmp.env
sed 's/^.\{,12\}//' tmp.env > $SSH_PRODUCTION_KEYS

#docker exec -it cwcget python cwcget.py cfgsvccwc upload test11 $x
#docker exec  -it cwcget python cwcget.py cfgsvccwc getvalue test

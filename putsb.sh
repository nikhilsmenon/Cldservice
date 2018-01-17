#!/usr/bin/env bash
for docker in $(docker ps -q --filter 'name=stylebook'); 
	do
		port=$(docker port $docker | awk '{print $3}'| awk -F ":" '{print $2}') 
		curl -v http://localhost:$port/stylebook/nitro/v1/config/stylebooks -d "$(python getsb.py $1)" -H "Content-Type:application/json"; 
	done

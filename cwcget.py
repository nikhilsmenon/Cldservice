#!/usr/bin/env python

import cwc.auth
import cwc.client
import requests
import json
import sys
import os
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry


SERVICE_KEY = os.environ['CFGSVC_CW_PRIVATE_KEY']
SERVICE_NAME = os.environ['CFGSVC_CW_SERVICE_NAME']
SERVICE_NAME= SERVICE_NAME.replace("\"", "")
SERVICE_KEY = SERVICE_KEY.replace("\"","")

platform_url = "https://credentialwallet.ctxwsstgapi.net"
requests.adapters.DEFAULT_RETRIES = 5
filename = "cwckeys.env"    
key_regexp=0  

def requests_retry_session(retries=3,backoff_factor=0.3,status_forcelist=(500, 502, 504),session=None):
    session = session or requests.Session()
    retry = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session

def print_status(resp, succ_code, succ_message, error_message):
	if (resp.status_code == succ_code):
		print succ_message
	else:
		print error_message + " " + str(resp.status_code)
 
			
	      

def get_cwc_auth_headers(targetUrl):
	
	keyparams = cwc.auth.CwcServiceKeyParameters(SERVICE_KEY, SERVICE_NAME)
	settings = cwc.client.CwcRequestSettings(keyparams = keyparams)
	headers = cwc.client.getheaders(cwc.auth.CwcAuthorizationMode.servicekey, settings, targetUrl)
	return headers


def get_value(CustomerId, key):
	targetUrl = platform_url+ '/'+ CustomerId+"/secrets/"+key	
	auth_hdr = get_cwc_auth_headers(targetUrl)
        s = requests.Session()
	s.auth = auth_hdr
	#resp = requests.get(targetUrl, headers=auth_hdr, timeout=300)
        resp= requests_retry_session().get(targetUrl, headers=auth_hdr, timeout=300)
	if (resp.status_code == 200):
		res_obj = json.loads(resp.content)
		#print res_obj["name"], ':', res_obj["value"]
                return res_obj["value"]
	else:
		print_status(resp, 200, "", "Value not found ")	



def get_all_values(CustomerId):
       
	targetUrl = platform_url+ '/'+ CustomerId+"/secrets"
	auth_hdr = get_cwc_auth_headers(targetUrl)
	resp = requests.get(targetUrl, headers=auth_hdr, timeout=300)
        
       
        #s.headers.update({'x-test': 'true'})
	#print resp
	#print "*************"
	#print resp.content
	if (resp.status_code == 200):
		res_obj = json.loads(resp.content)
                if os.path.exists(filename):
                        f = file(filename, "r+")
                        f.seek(0)
                        f.truncate()
                #print "expresion : " + str(key_regexp)
		for pair in res_obj["items"]:
			#print pair
			#print pair["name"] , ':',  pair["value"] 
			# pair["value"] is returned as NULL , so you need to make a specific query
                        key=pair["name"]
                        if (key_regexp != 0):
                           if key.startswith(key_regexp):
			      value = get_value(CustomerId, pair["name"])
                              f = file(filename, "a+")
                              f.write(pair["name"] + "=" + value + "\n")
                        else:
                            value = get_value(CustomerId, pair["name"])
                            f = file(filename, "a+")
                            f.write(pair["name"] + "=" + value + "\n")

    
	else:
		print_status(resp, 200, "", "Values not found ")		
	print "*************"

	
    

def create_value(CustomerId, body):
	targetUrl = platform_url+ '/'+ CustomerId+"/secrets"
	auth_hdr = get_cwc_auth_headers(targetUrl) 
	content_header = {'content-type': 'application/json'}
	
	req_hdr = dict(auth_hdr.items() + content_header.items())
	resp = requests.post(targetUrl, headers=req_hdr, data=body, timeout=300)
	print_status(resp, 201, "Value Successfully Added", "Value Addition failed ")
	


def modify_value(CustomerId, body, key):
	targetUrl = platform_url+ '/'+ CustomerId+ "/secrets/" + key
	auth_hdr = get_cwc_auth_headers(targetUrl) 
	content_header = {'content-type': 'application/json'}

	req_hdr = dict(auth_hdr.items() + content_header.items())
	resp = requests.put(targetUrl, headers=req_hdr, data=body, timeout=300)
	print_status(resp, 200, "Value Successfully Modified", "Value Modification failed ")
	


def delete_value(CustomerId,  key):
	targetUrl = platform_url+ '/'+ CustomerId+"/secrets/" + key
	auth_hdr = get_cwc_auth_headers(targetUrl) 
	resp = requests.delete(targetUrl, headers=auth_hdr, timeout=300)
	#Note: always returns TRUE
	print_status(resp, 200, "Value Successfully deleted", "Value Deletion failed ")



def main():
        global key_regexp
        dict = {}
	CustomerId=sys.argv[1]
        cwc_operation=sys.argv[2]
        cwc_key=sys.argv[3]
        key_regexp=sys.argv[3]
        cwc_value=sys.argv[4]
        #print os.environ['CW_PRIVATE_KEY']
	if (cwc_operation == "getall" ):
               #print "get all operation"
               get_all_values(CustomerId)
        if (cwc_operation == "getvalue" ):
	       print "get operation"
               
	       get_value (CustomerId, cwc_key)
        if( cwc_operation == "upload" ):
                print "new upload operation"
                dict.clear()
		value = "cfgsvc"
		dict["name"] = cwc_key
		dict["value"] = cwc_value
		json_body = json.dumps(dict)
		print json_body
		create_value(CustomerId, json_body)
        if (cwc_operation == "update"):
              print "update operatio"
              dict.clear()
              dict["name"] = cwc_key
	      dict["value"] = cwc_value
	      json_body = json.dumps(dict)
	      modify_value(CustomerId, json_body, cwc_key)

	if( cwc_operation == "delete"):
              print "delete operation"
              dict.clear()
	      delete_value(CustomerId, cwc_key)	
			
				
	
		
		
if __name__ == '__main__':
	main()		
		

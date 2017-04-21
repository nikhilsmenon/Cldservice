from flask import Flask, jsonify, request,Response
import requests
from jsonschema import validate
import json
import logging
import uuid
import time
from datetime import datetime
 
#i = datetime.now()
 
app = Flask(__name__)
dictvar =({})


@app.errorhandler(404)
def not_found(error=None):
    message = {
            'status': 404,
            'message': 'Not Found: ' + request.url,
    }
    resp = jsonify(message)
    resp.status_code = 404

    return resp

@app.route("/store/<key>/<value>")
def foo(key,value):
    dictvar[key] = value
    #resp = Response(dictvar, status=200, mimetype='application/json')
    resp = jsonify(dictvar)
    #dictvar= json.dumps(dictvar)
    resp.status_code = 200
    return resp

@app.route('/key/<keyid>', methods = ['GET'])
def api_users(keyid):
    #users = {'1':'john', '2':'steve', '3':'bill'}
    
    if keyid in dictvar:
        return jsonify({keyid:dictvar[keyid]})
    else:
        return not_found()

@app.route("/configservicecallback", methods=["POST", "DELETE", "GET", "PUT"])
def testapi():
    print request.method
    print request.path
    print request.url
    print request.query_string
    print request.args.to_dict().items()
    #print request.data
    data = request.json  
    data['time']=datetime.now()
    print data['id'], data['resource']
    key=data['id']
    value=data
    dictvar[key]=value
    print "received response -- "
    print data
    return jsonify(errorcode=0, message="Done"), 200

def testapi(x=None):
    print x


class mycalss: 
    def __init__(self):
        pass

    @classmethod
    def testapi2(self, xx):
        print "i am test api2" + xx


myfunc = 'testapi2'
eval(compile("mycalss."+myfunc,'<str>','eval'))("YES")

myfunc1 = 'testapi2'
eval(compile("mycalss."+myfunc,'<str>','eval'))("YES")

app.run(host="10.102.107.30", port=7777, debug=True)

#!/usr/bin/env python
import sys, yaml, io, json

with open(sys.argv[1], 'r') as stream:
   json_txt=json.dumps(yaml.load(stream),sys.stdout,indent=4)

tmp = json.loads(json_txt)
print json.dumps(
	dict(
		{
			"stylebook": {
				"source":"{}".format(json.dumps(tmp, indent=4))
			}
		}
	)
)


try:
    import json
except ImportError:
    import sys
    sys.path.append('simplejson-2.3.3')
    import simplejson as json
    
import urllib



class adm:

    def __init__(self, url):
        if url != None:
            self.url = url

    def createUser(self, n, p):

        arg_hash = { 'method': 'adm.createUser',
                     'params': [n, p],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def createNode(self, n, p, np):

        arg_hash = { 'method': 'adm.createNode',
                     'params': [n, p, np],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def modifyNode(self, n, p, np):

        arg_hash = { 'method': 'adm.modifyNode',
                     'params': [n, p, np],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def listNodes(self, n, p, sp):

        arg_hash = { 'method': 'adm.listNodes',
                     'params': [n, p, sp],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result'][0]
        else:
            return None

    def viewNodes(self, n, p, id, v):

        arg_hash = { 'method': 'adm.viewNodes',
                     'params': [n, p, id, v],
                     'version': '1.1'
                     }

        body = json.dumps(arg_hash)
        resp_str = urllib.urlopen(self.url, body).read()
        resp = json.loads(resp_str)

        if 'result' in resp:
            return resp['result']
        else:
            return None




        

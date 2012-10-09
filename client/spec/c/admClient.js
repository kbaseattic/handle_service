

function adm(url) {

    var _url = url;


    this.createUser = function(n, p)
    {
	var resp = json_call_ajax_sync("adm.createUser", [n, p]);
//	var resp = json_call_sync("adm.createUser", [n, p]);
        return resp[0];
    }

    this.createUser_async = function(n, p, _callback, _error_callback)
    {
	json_call_ajax_async("adm.createUser", [n, p], 1, _callback, _error_callback)
    }

    this.createNode = function(n, p, np)
    {
	var resp = json_call_ajax_sync("adm.createNode", [n, p, np]);
//	var resp = json_call_sync("adm.createNode", [n, p, np]);
        return resp[0];
    }

    this.createNode_async = function(n, p, np, _callback, _error_callback)
    {
	json_call_ajax_async("adm.createNode", [n, p, np], 1, _callback, _error_callback)
    }

    this.modifyNode = function(n, p, np)
    {
	var resp = json_call_ajax_sync("adm.modifyNode", [n, p, np]);
//	var resp = json_call_sync("adm.modifyNode", [n, p, np]);
        return resp[0];
    }

    this.modifyNode_async = function(n, p, np, _callback, _error_callback)
    {
	json_call_ajax_async("adm.modifyNode", [n, p, np], 1, _callback, _error_callback)
    }

    this.listNodes = function(n, p, sp)
    {
	var resp = json_call_ajax_sync("adm.listNodes", [n, p, sp]);
//	var resp = json_call_sync("adm.listNodes", [n, p, sp]);
        return resp[0];
    }

    this.listNodes_async = function(n, p, sp, _callback, _error_callback)
    {
	json_call_ajax_async("adm.listNodes", [n, p, sp], 1, _callback, _error_callback)
    }

    this.viewNodes = function(n, p, id, v)
    {
	var resp = json_call_ajax_sync("adm.viewNodes", [n, p, id, v]);
//	var resp = json_call_sync("adm.viewNodes", [n, p, id, v]);
        return resp;
    }

    this.viewNodes_async = function(n, p, id, v, _callback, _error_callback)
    {
	json_call_ajax_async("adm.viewNodes", [n, p, id, v], 0, _callback, _error_callback)
    }

    function _json_call_prepare(url, method, params, async_flag)
    {
	var rpc = { 'params' : params,
		    'method' : method,
		    'version': "1.1",
	};
	
	var body = JSON.stringify(rpc);
	
	var http = new XMLHttpRequest();
	
	http.open("POST", url, async_flag);
	
	//Send the proper header information along with the request
	http.setRequestHeader("Content-type", "application/json");
	//http.setRequestHeader("Content-length", body.length);
	//http.setRequestHeader("Connection", "close");
	return [http, body];
    }

    /*
     * JSON call using jQuery method.
     */

    function json_call_ajax_sync(method, params)
    {
        var rpc = { 'params' : params,
                    'method' : method,
                    'version': "1.1",
        };
        
        var body = JSON.stringify(rpc);
        var resp_txt;
	var code;
        
        var x = jQuery.ajax({       "async": false,
                                    dataType: "text",
                                    url: _url,
                                    success: function (data, status, xhr) { resp_txt = data; code = xhr.status },
				    error: function(xhr, textStatus, errorThrown) { resp_txt = xhr.responseText, code = xhr.status },
                                    data: body,
                                    processData: false,
                                    type: 'POST',
				    });

        var result;

        if (resp_txt)
        {
	    var resp = JSON.parse(resp_txt);
	    
	    if (code >= 500)
	    {
		throw resp.error;
	    }
	    else
	    {
		return resp.result;
	    }
        }
	else
	{
	    return null;
	}
    }

    function json_call_ajax_async(method, params, num_rets, callback, error_callback)
    {
        var rpc = { 'params' : params,
                    'method' : method,
                    'version': "1.1",
        };
        
        var body = JSON.stringify(rpc);
        var resp_txt;
	var code;
        
        var x = jQuery.ajax({       "async": true,
                                    dataType: "text",
                                    url: _url,
                                    success: function (data, status, xhr)
				{
				    resp = JSON.parse(data);
				    var result = resp["result"];
				    if (num_rets == 1)
				    {
					callback(result[0]);
				    }
				    else
				    {
					callback(result);
				    }
				    
				},
				    error: function(xhr, textStatus, errorThrown)
				{
				    if (xhr.responseText)
				    {
					resp = JSON.parse(xhr.responseText);
					if (error_callback)
					{
					    error_callback(resp.error);
					}
					else
					{
					    throw resp.error;
					}
				    }
				},
                                    data: body,
                                    processData: false,
                                    type: 'POST',
				    });

    }

    function json_call_async(method, params, num_rets, callback)
    {
	var tup = _json_call_prepare(_url, method, params, true);
	var http = tup[0];
	var body = tup[1];
	
	http.onreadystatechange = function() {
	    if (http.readyState == 4 && http.status == 200) {
		var resp_txt = http.responseText;
		var resp = JSON.parse(resp_txt);
		var result = resp["result"];
		if (num_rets == 1)
		{
		    callback(result[0]);
		}
		else
		{
		    callback(result);
		}
	    }
	}
	
	http.send(body);
	
    }
    
    function json_call_sync(method, params)
    {
	var tup = _json_call_prepare(url, method, params, false);
	var http = tup[0];
	var body = tup[1];
	
	http.send(body);
	
	var resp_txt = http.responseText;
	
	var resp = JSON.parse(resp_txt);
	var result = resp["result"];
	    
	return result;
    }
}


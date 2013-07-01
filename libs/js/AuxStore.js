(function () {
    
    var root = this;
    var SHOCK = root.SHOCK = {};

    SHOCK.url = null;
    SHOCK.auth_header = {};

    SHOCK.init = function (params) {
	if (params.url !== null) {
	    SHOCK.url = params.url;
	}

	if (params.token !== null) {
	    SHOCK.set_auth(params.token);
	}
    }

    SHOCK.set_auth = function (token) {
	SHOCK.auth_header = {'Authorization': 'OAuth '+token}
    };

    SHOCK.get_node = function (node, ret) {
	var url = SHOCK.url+'/node/'+node
	var promise = jQuery.Deferred();
        jQuery.getJSON(url, { 
	    success: function(data) {
		var retval = null;
		if (data != null && data.hasOwnProperty('data')) {
		    if (data.error != null) {
			retval = null;
			console.log("error: "+data.error);
		    } else {
			retval = data.data;
		    }
		} else {
		    retval = null;
		    console.log("error: invalid return structure from SHOCK server");
		    console.log(data);
		}
		
		if (typeof ret == "function") {
		    ret(retval);
		} else {
		    ret = retval;
		}
		
		promise.resolve();
	    },
	    error: function(jqXHR, error) {
		console.log( "error: unable to connect to SHOCK server" );
		console.log(error);
	    },
	    headers: SHOCK.auth_header
	});

	return promise;
    };

    SHOCK.create_node = function (evt, attr, ret) {
	SHOCK.upload(evt, null, attr, ret);
    };

    SHOCK.update_node = function (evt, node, attr, ret) {
	SHOCK.upload(evt, node, attr, ret);
    };
    
    SHOCK.upload = function (evt, node, attr) {
	if ((typeof evt != "object") || (! evt.hasOwnProperty("target"))) {
	    console.log("error: first parameter to create node must be an event");
	    return;
	}

	if (! evt.target.hasOwnProperty("files")) {
	    console.log("error: event passed to create_node must be a file open event");
	    return;
	}

	var files = evt.target.files;
	if (files.length > 1) {
	    console.log("error: you can only submit one file at a time");
	    return;
	}

	if (attr == null) {
	    attr = {};
	}

	var method = "GET";
	var url = SHOCK.url+'/node/';
	if (node != null) {
	    url = SHOCK.url+'/node/'+node;
	    method = "POST";
	}

	var promise = jQuery.Deferred();
	var f = files[0];
	var reader = new FileReader();
	reader.onload = (function(theFile) {
	    return function(e) {
		jQuery.ajax(url, {
		    data: e.target.result,
		    success: function(data){
			var retval = null;
			if (data != null && data.hasOwnProperty('data')) {
			    if (data.error != null) {
				retval = null;
				console.log("error: "+data.error);
			    } else {
				retval = data.data;
			    }
			} else {
			    retval = null;
			    console.log("error: invalid return structure from SHOCK server");
			    console.log(data);
			}
			
			if (typeof ret == "function") {
			    ret(retval);
			} else {
			    ret = retval;
			}
			promise.resolve();
		    },
		    error: function(jqXHR, error){
			console.log( "error: unable to submit to SHOCK server" );
			console.log(error);
		    },
		    headers: SHOCK.auth_header,
		    type: method
		});
	    };
	})(f);
	reader.readAsBinaryString(f);
	
	return promise;
    }
    
}).call(this);
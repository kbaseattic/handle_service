var login_url = "http://kbase.us/services/authorization/Sessions/Login/";
var shock_url = "http://kbase.us/services/shock-api";
var upload_url = shock_url + "/node";
var cdmi_url = "http://kbase.us/services/cdmi_api/";

var cdmi_api = new CDMI_API(cdmi_url);
var cdmi_entity_api = new CDMI_EntityAPI(cdmi_url);

var defaultUserData = {
    auth_token: null,
    user_id: null
};
var filecount = 0;

$(window).load(function(){
		   //clear the default CSS associated with the blockUI loading element so we can insert ours
		   $.blockUI.defaults.css = {};
		   $(document).ajaxStop($.unblockUI);
		   $('#tabs').tab();
		   // Initialize the height of the "tallbox" div that encloses the datagrid, so that
		   // it sizes w/scrolling
		   $('.tallbox').height( $(window).height() - 250 );
		   // Initialize the browsing datagrid when it is shown
		   $('#tabs a[href="#browse"]').on('shown', function (e) {
						       $('#ShockGrid').datagrid( { dataSource: ShockDataSrc,
										   stretchHeight: true});
						       $('#ShockGrid').popover( { selector: '.has-popover',
										  trigger: 'click',
										  content: function() {
										      console.log( this);
										      return("<pre>"+$(this).attr('data-content2')+"</pre>");
										      },
										  title: 'Complete Metadata',
										  html: true,
										  placement: 'bottom',
										  template: '<div class="popover"><div class="arrow"></div><div class="popover-inner mypopover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>'
										});
						       // setup delegated click handlers for trash icons in grid
						       $('#ShockGrid').on('click', 'tbody .icon-trash', delete_confirm);
						   });
		   $(".form-signin").keypress(function(event) {
						  if (event.which == 13) {
						      event.preventDefault();
						      login($('#kbase_username').val(),$('#kbase_password').val());
						  }
					      });
		   $('#clearform').on('click',clearForm);
		   $("#upload").submit( function(event) {
					    event.preventDefault();
					    var d = new Date();
					    $("#upload_date").val(d.toJSON());
					    var attrs = Object();
					    $("#upload").find(':input').not(':button, :submit').each(function(i){
													 attrs[$(this).attr('id')] = $(this).val()
												     });
					    // Strip out unwanted form fields from attrs that go into Shock
					    [undefined,'datafile','fid','newtag'].map( function(attr) {
											   delete attrs[ attr];
										       });
					    // Read in the fields being managed by pillbox widgets
					    ['tags','related_kbid'].map( function(attr) {
									     field = $('#'+attr);
									     attrs[attr] = field.pillbox('items').map( function(item) { return(item.text) } )
									 });
					    var datafile = $("#datafile")[0];
					    
					    if ($("#datafile")[0].files[0] == undefined) {
						alert("Please choose a file for upload")
					    } else {
						$("#upload_progress").show();
						console.log( attrs);
						upload(datafile,attrs,localStorage['auth_token']);
						clearForm();
					    }
					});
		   $('#related_kbid').val("");
		   $("#fid").keypress(function(event) {
					  if (event.which == 13) {
					      event.preventDefault();
					      var newfid = $("#fid").val();
					      $('#kbid_check').attr("class","label label-info").text("Checking").show();
					      // Is this a Genome or a Gene id?
					      var validator;
					      if (newfid.match(/^kb\|g\.\d+$/)) {
						  validator = isKBaseGenome;
					      } else {
						  validator = isKBaseGene;
					      }
					      validator( newfid,
							 function() {
							     $('#kbidlist').append($('<li>').text(newfid));
							     $("#fid").val("");
							     $('#kbid_check').attr("class","label label-success").text("ID OK").fadeOut(3000);
							 },
							 function(res) {
							     console.log( newfid + " is not a legitimate KBase Genome ID");
							     $('#kbid_check').attr("class","label label-important").text("Bad ID").fadeOut(3000);
							 });
					  }
				      });
		   $("#newtag").keypress(function(event) {
					     if (event.which == 13) {
						 event.preventDefault();
						 var newtag = $("#newtag").val();
						 $('#newtag_check').attr("class","label label-info").text("Checking").show();
						 if ( newtag.match(/^\w[\w\-\:]*$/) ) {
						     $("#taglist").append($('<li>').text(newtag));
						     $("#newtag").val("");
						     $('#newtag_check').attr("class","label label-success").text("Tag OK").fadeOut(3000);
						 } else {
						     $('#newtag_check').attr("class","label label-important").text("Bad Tag").fadeOut(3000);
						 }
					     }
					 });
		   checkLogin();
	       });

function clearForm() {
    $(':input','#upload').not(':button, :submit, :hidden, :reset, [readonly]')
	.val('')
	.removeAttr('checked')
	.removeAttr('selected');
    $('#related_kbid').empty();
    $('#taglist').empty();
    $('#kbid_check').css('visibility','hidden');
    $('#tag_check').css('visibility','hidden');
    
}

function delete_file( shockid) {
    $.ajax({
	       url: upload_url+"/"+shockid,
	       type: "DELETE",
	       beforeSend: function(xhr) { xhr.setRequestHeader( 'Authorization', 'OAuth ' + userData.auth_token)},
	       success: function(data) { alert( "File successfully deleted"); },
	       error: function(jqXHR, textStatus, errorThrown) { alert( "Unable to delete : "+shockid); }
	   });

    
}


// fileInputElement is the form field where the user selected the file
// attributes is a hash containing the metadata attributes
// authToken is a legit OAuth authentication token
function upload(fileInputElement,attributes,authToken) {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', upload_url, true); // Here we would use the Shock node ID
    xhr.setRequestHeader('Authorization', 'OAuth ' + authToken);

    // Append a new row for this upload to the upload progress table
    uptable = $('#uploads').find('tbody');
    ++filecount;
    fileName = fileInputElement.files[0].name;
    uptable.append($('<tr>')
		   .append($('<td><h6>'+fileName+'</h6></td>'))
		   .append($('<td>')
			   .append($('<progress min="0" max="100" style="width: 300px;">')
				   .attr('id','progressBar'+filecount)))
		   .append($('<td>')
			   .append($('<h6>Uploading</h6>').attr('id','upload_status'+filecount)))
		   .append($('<td>')
			   .append($('<button class="btn">Cancel</button>').attr('id','cancel'+filecount)))
		  );
    $("#cancel"+filecount).on('click',function(e) {
				  $("#cancel"+filecount).hide();
				  xhr.abort();
			      });

    xhr.onload = function(e) {
	if (this.status == 200) {
	    console.log(this.response);
	    response = JSON.parse( this.response);
	    $("#upload_status"+filecount).text("Shock ID = " + response.D.id);
	    $("#cancel"+filecount).hide();
	}
    };
    var progressBar = $("#progressBar"+filecount);
    xhr.upload.onprogress = function(e) {
	if (e.lengthComputable) {
	    progressBar.val(e.loaded /e.total * 100);
	    $("#upload_status"+filecount).text(e.loaded+" of "+e.total+" bytes");
	}
    };
    xhr.addEventListener("error", function(evt) { 
			     $('#upload_status'+filecount).text('Error during upload');
			 }, false);
    xhr.addEventListener("abort", function(evt) { 
			     $('#upload_status'+filecount).text('Upload aborted');
			 }, false);
    
    var fd = new FormData();
    fd.append("upload", fileInputElement.files[0]);
    var attrFileBody = JSON.stringify(attributes); // the body of the new file...
    var attrBlob;
    try {
	attrBlob = new Blob([attrFileBody], { type: "application/json" });
    }
    catch(e) {
	window.BlobBuilder = window.BlobBuilder || 
            window.WebKitBlobBuilder || 
            window.MozBlobBuilder || 
            window.MSBlobBuilder;
	if (e.name == "TypeError" && window.BlobBuilder) {
            var bb = new BlobBuilder();
            bb.append([attrFileBody]);
            attrBlob = bb.getBlob("application/json");
	}
	else if (e.name == "InvalidStateError") {
            attrBlob = new Blob( [attrFileBody], {type : "application/json"});
	}
	else {
            console.log("This browser doesn't support Blob type");
	}
    }
    fd.append('attributes', attrBlob, fileInputElement.files[0].name + ".attributes" );
    xhr.send(fd);
    $("#progress_display").scrollTop($("#progress_display")[0].scrollHeight);
}

// bring up delete file modal dialog
var delete_confirm = function(e) {
    console.log(this);
    var dialog = $('#delete_dialog');
    var shockid = $(this).attr('data-id');
    var filename = $(this).attr('data-filename');
    $('#delete_file').html("<h6>Name : "+filename+"</h6><h6>ID : "+shockid+"</h6>");
    $('#killkillkill').attr("data-shockid", shockid);
    $('#killkillkill').click(function() { dialog.modal("hide"); delete_file( shockid); });
    dialog.modal('show');

}

// Datasource for FuelUX datagrid
var ShockDataSrc = new Object();

// Mapping function from column names to field values
ShockDataSrc._colmap = {
    'Shock ID' : function (item) { return(item.id); },
    'Actions' : function (item) {
	var info = JSON.stringify( item, undefined, 2).replace(/\n?\s*[\{\}\[\]],?/g,'');
	var html='<i rel=\"popover\" data-content2=\'' + info + '\' class="icon-search has-popover"/>' +
	         '<i id=\"trash-' + item.id + '\" data-id=\"'+item.id+'\" data-filename=\"' + item.file.name + '\" class="icon-trash"/>' +
	         '<i id=\"down-' + item.id + '\" data-id=\"'+item.id+'\" data-filename=\"' + item.file.name + '\" class="icon-arrow-down"/>';
	return( html );
    },
    'Filename' : function (item) {return(item.file.name);},
    'Size' : function (item) { return( item.file.size); },
    'Description' : function (item) { return( (item.attributes && item.attributes.Description ) ? item.attributes.Description : "None given" ); },
    'Owner' : function (item) { return( (item.attributes && item.attributes.owner) ? item.attributes.owner : "None given" );},
    'Related KBaseIDs' : function(item) { return( (item.attributes && item.attributes.related_kbid) ? item.attributes.related_kbid.join(', ') : ''); },
    'Tags' : function(item) { return( ( item.attributes && item.attributes.tags) ? item.attributes.tags.join(', ') : ''); }
}

ShockDataSrc._results = Object();

ShockDataSrc.columns = function() {
    return Object.keys(this._colmap).map( function(key) {
					      return( { property: key,
							label: key,
							sortable: true});
					      });
}

ShockDataSrc._results = Object();

ShockDataSrc.data = function( options, callback) {
    var colmap = this._colmap;

    console.log(options);
    console.log( "Page size: ",options.pageSize);
    var filter = {
		   'query': '',
		   'limit': options.pageSize ? options.pageSize : 10,
		   'skip': options.pageIndex ? options.pageIndex * options.pageSize: 0
    };
    if ($('#myself_only:checked').length) {
	filter.owner = userData.user_id;
    }
    if (options.search) {
    	// user can specify multiple search terms using whitespace, each of which
	// will be used in an "AND" fashion
	// search terms prefixed with 'fieldname=' will bind that search term to
	// the fieldname specified, otherwise we see if the string starts with
	// kb| and bind it to related_kbid or else consider it a tag and bind
	// it to the tags field
	var terms = options.search.split('\s+');
	terms.reduce( function (filter, term) {
			  var m;
			  if (term.match(/^kb\|.+/)) {
			      filter.related_kbid = term;
			  } else if (m = term.match(/^([a-zA-Z][_\w\.]+)\=([\w:_\.\|]+)$/)) {
			      filter[m[1]] = m[2];
			  } else if ( m = term.match(/^(\w[\w\-\:]*)$/)) {
			      filter.tags = m[1];
			  } else {
			      // didn't match known format, drop it
			      alert( "Unrecognized search term: " + term + ". Ignoring");
			  }
		      },
		    filter);
    }
    console.log(filter);
    $.ajax({
	       url: upload_url,
	       type: "GET",
	       data: filter,
	       dataType: "json",
	       beforeSend: function(xhr) { xhr.setRequestHeader( 'Authorization', 'OAuth ' + userData.auth_token)},
	       success: function(data) {
		   var results = data.D.map( function(item) {
						 var r = {};
						 Object.keys(colmap).map( function(attr) {
									      r[attr] = colmap[attr](item);
									  });
						 return(r);
						 });
		   var resultobj = {
		       data: results,
		       start: filter.skip,
		       end: filter.skip + results.length,
		   }
		   // we hack the count field, since we don't have an actual count
		   // if we got the full complement that we asked for then assume there
		   // is at least 1 page more than we asked for
		   if (results.length == filter.limit) {
		       resultobj.count = resultobj.end + filter.limit;
		       resultobj.page = Math.round(resultobj.end / filter.limit);
		       resultobj.pages = resultobj.page +1;
		   } else {
		       resultobj.count = resultobj.end;
		       resultobj.page = Math.round(resultobj.end / filter.limit);
		       resultobj.pages = resultobj.page;
		   }
		   callback( resultobj );
	       },
	       error: function(jqXHR, textStatus, errorThrown) { alert( textStatus + errorThrown); }
	   });


}

/* BEGIN UTILITY functions */

// Found in StackOverflow:
// http://stackoverflow.com/questions/18082/validate-numbers-in-javascript-isnumeric
// nifty one liner!
function isNumber(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
}

//override default jquery behavior to make a :contains that is case insensitive
$.expr[":"].icontains = $.expr.createPseudo(function(arg) {
						return function(elem) {
						    return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
						};
					    });


/* Filter a list of nav elements by user text.
 A timeout is used to make sure only the last call is grabbed,
 since this function will be called after every keypress.  Also, if the
 search text has not changed since the last call, we return and do nothing.
 */
function listFilter(searchbox, list) {
    if (arguments.callee.filter) {
        if (arguments.callee.filter === $(searchbox).val()) {
            return;
        }
        
        arguments.callee.filter = $(searchbox).val();
    }

    var filter = $(searchbox).val();

    if (arguments.callee.timeout) { clearTimeout(arguments.callee.timeout); }
    
    arguments.callee.timeout = setTimeout(function() {
					      var list_elements = $(list + " li");
					      
					      if (filter && filter.length > 0) {
						  list_elements.find("a:not(:icontains('" + filter + "'))").hide();
						  list_elements.find("a:icontains('" + filter + "')").show();
					      } 
					      else {
						  list_elements.find("a").show();
					      }
					  }, 500);
}


function sortByKBaseID(a, b) {
    if (parseInt(a.split(".")[1]) < parseInt(b.split(".")[1])) return -1;
    if (parseInt(a.split(".")[1]) > parseInt(b.split(".")[1])) return 1;
    return 0;
}


function isKBaseGenome(genome_id, success_function, error_function) {
    try {
	cdmi_entity_api.get_entity_Genome_async([genome_id],["id"],
						function (result) {
						    try {
							result = result[genome_id]["id"];
							success_function();
						    }
						    catch (e) {
							error_function(e);
						    }
						},
						function (error) {
						    throw Error(error);
						}
					       );
    }
    catch (e) {
	console.log("There was an error attempting to call get_entity_Genome_async() from " + cdmi_url);
	throw Error({error_object: e, message: "There was an error attempting to call get_entity_Genome_async() from " + cdmi_url});
    }
}

function isKBaseGene(gene_id, success_function, error_function) {
    try {
	cdmi_entity_api.get_entity_Feature_async([gene_id],["source_id"],
						 function (result) {
						     try {
							 result = result[gene_id]["id"];
							 success_function();
						     }
						     catch (e) {
							 error_function(e);
						     }
						 },
						 function (error) {
						     throw Error(error);
						 }
						);
    }
    catch (e) {
	console.log("There was an error attempting to call get_entity_Genome_async() from " + cdmi_url);
	throw Error({error_object: e, message: "There was an error attempting to call get_entity_Genome_async() from " + cdmi_url});
    }
}


function showLoadingSpinner(text) {
    if (text != null && text.length > 0)
	$("#loading_spinner_text").html(text);
    $("#loading_spinner").removeClass("hidden");
}	

function hideLoadingSpinner() {
    $("#loading_spinner").addClass("hidden");
    $("#loading_spinner_text").html("Loading, please wait...");
}

function showError(error) {
    console.log(error);
    $("#error_text").html(error);
    $("#error").removeClass("hidden");
}


function showLoadingMessage(message, element) {
    if (typeof element === "undefined" || element === null) {
	if (message && message.length > 0) {
	    $("#loading_message_text").empty();
	    $("#loading_message_text").append(message);
	}
	
	$.blockUI({message: $("#loading_message")});    
    }
    else {
        $(element).block({message: "<div><div>" + message + "</div><div><img src='assets/img/loading.gif'/></div></div>"});    
    }
}


function hideLoadingMessage(element) {
    if (typeof element === "undefined" || element === null) {
        $.unblockUI();
	$("#loading_message_text").empty();
	$("#loading_message_text").append("Loading, please wait...");
    }
    else {
        $(element).unblock();
    }        
}


function checkLogin() {
    //check to see if we still have authentication or not
    var hasLocalStorage = false;

    if (localStorage && localStorage !== null) {
        hasLocalStorage = true;
    }

    if (hasLocalStorage && typeof localStorage["auth_token"] !== "undefined" && localStorage["auth_token"] !== null) {
	userData = jQuery.extend(true, {}, defaultUserData);
	userData.auth_token = localStorage["auth_token"];

        var user_id = userData.auth_token.split("|")[0].split("=")[1];
	userData.user_id = user_id;

	$("#login_status").text("User : " + user_id);
	$("#login_status").effect('slide');
	$("#owner").val(user_id);
	
	$("#logout").prop('width',$('#login_status').outerWidth());
	
	$("#main_app").removeClass("hidden");
    } else {
        $('#new_login').removeClass('hidden');    
    }
}


function login(user_id, password) {
    var initializeUser = function (token) {
	userData = jQuery.extend(true, {}, defaultUserData);
	userData.auth_token = token;
        var user_id = userData.auth_token.split("|")[0].split("=")[1];
	userData.user_id = user_id;
	
	$("#login_status").text("User : " + user_id);
	$("#login_status").effect('slide');
	$("#owner").val(user_id);

	$("#logout").prop('width',$('#login_status').outerWidth());
	
	$("#new_login").addClass("hidden");
	$("#main_app").removeClass("hidden");
    };


    var hasLocalStorage = false;

    if (localStorage && localStorage !== null) {
        hasLocalStorage = true;
    }

    var options = {
	loginURL : login_url,
	possibleFields : ['verified','name','opt_in','kbase_sessionid','token','groups','user_id','email','system_admin'],
	fields : ['token', 'kbase_sessionid', 'user_id']
    };

    var args = { "user_id" : user_id, "password": password, "fields": options.fields.join(',')};
    
    login_result = $.ajax({type: "POST",
	                   url: options.loginURL,
	                   data: args,
	                   beforeSend: function (xhr) {
			       showLoadingMessage("Logging you into KBase as " + user_id);
	                   },
	                   success: function(data, textStatus, jqXHR) {
			       if (hasLocalStorage) {
				   localStorage["auth_token"] = data.token;
				   localStorage["user_id"] = data.user_id;
				   
			       }
			       
			       initializeUser(data.token);
	                   }, 
	                   error: function(jqXHR, textStatus, errorThrown) {
	                       console.log(errorThrown);
	                       $("#login_error").append(errorThrown.message);	                          
	                   },
	                   dataType: "json"});
}

function logout() {
    //resetApplication(userData);

    var hasLocalStorage = false;

    if (localStorage && localStorage !== null) {
        hasLocalStorage = true;
    }

    if (hasLocalStorage) {
        localStorage.clear();
    }
    
    userData = null;
    $("#main_app").addClass("hidden");
    $("#new_login").removeClass("hidden");   
    $('#login_status').val("Not logged in")
    location.reload(); 
}

/* END UTILITY functions */

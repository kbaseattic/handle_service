var login_url = "http://kbase.us/services/authorization/Sessions/Login/";
var defaultUserData = {
    auth_token: null,
    user_id: null
};
var upload_url = "https://kbase.us/services/shock-api/node";
var filecount = 0;

/* BEGIN UTILITY functions */

$(window).load(function(){
    //clear the default CSS associated with the blockUI loading element so we can insert ours
    $.blockUI.defaults.css = {};
    $(document).ajaxStop($.unblockUI);
    
    $(".form-signin").keypress(function(event) {
		if (event.which == 13) {
			event.preventDefault();
			login($('#kbase_username').val(),$('#kbase_password').val());
		}
    });
    $("#upload").submit( function(event) {
			     event.preventDefault();
			     var d = new Date();
			     $("#upload_date").val(d.toJSON());
			     var attrs = Object();
			     $("#upload").find(':input').not(':button, :submit').each(function(i){
								  attrs[$(this).attr('id')] = $(this).val()
							      });
			     // Strip out unwanted form fields from attrs that go into Shock
			     delete attrs[undefined];
			     delete attrs['datafile'];
			     delete attrs['fid'];
			     // Convert these fields from \n delimited string into a list
			     ['related_kbid'].map( function(attr) {
						       old = attrs[attr];
						       attrs[attr] = old.split("\n");
						   });
			     var datafile = $("#datafile")[0];
			     upload(datafile,attrs,localStorage['auth_token']);
			     // reset form
			     $(':input','#upload').not(':button, :submit, :hidden, :reset, [readonly]')
				 .val('')
				 .removeAttr('checked')
				 .removeAttr('selected');
			     $('#related_kbid').val('');
			 });
    $('#related_kbid').val("");
    $("#fid").keypress(function(event) {
		if (event.which == 13) {
			event.preventDefault();
			$('#add_genome_btn').triggerHandler("click");
		}
    });

    $("#add_genome_btn").click( function(event) {
				    var newfid = $("#fid").val();
				    var related_kbids = $('#related_kbid').val();
				    if (related_kbids == "") {
					$('#related_kbid').val( newfid);
				    } else {
					$('#related_kbid').val( related_kbids + "\n" + newfid);
				    }
				    $("#fid").val("");
				});

    checkLogin();
});


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
				  $("#upload_status"+filecount).text("Aborted!")
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
    xhr.addEventListener("error", uploadFailed, false);
    xhr.addEventListener("abort", uploadCanceled, false);
    
    var fd = new FormData();
    fd.append("upload", fileInputElement.files[0]);
    var attrFileBody = JSON.stringify(attributes); // the body of the new file...
    var attrBlob = new Blob([attrFileBody], { type: "application/json" });
    fd.append('attributes', attrBlob, fileInputElement.files[0].name + ".attributes" );
    xhr.send(fd);
    $("#progress_display").scrollTop($("#progress_display")[0].scrollHeight);
}

function uploadFailed (evt) {
  $("#upload_status").text("the upload has failed");
}

function uploadCanceled (evt) {
  $("#upload_status").text("the upload was canceled");
}


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
    if (element === undefined || element === null) {
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
    if (element === undefined || element === null) {
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

    if (hasLocalStorage && localStorage["auth_token"] !== undefined && localStorage["auth_token"] !== "null") {
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

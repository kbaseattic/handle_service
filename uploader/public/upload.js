var fu_curr_files;
var fu_curr_file = 0;
var fu_curr_offset = 0;
var fu_curr_size;
var fu_total_size;
var fu_total_uploaded = 0;
const BYTES_PER_CHUNK = 1024 * 1024 * 10; // 10 MB chunk sizes.
var incomplete_files = [];
var pending_uploads = [];

var selected_submission_file;
var selected_metadata_file;
var selected_libraries = [];
var last_directory = "";
var upload_url = "/upload";
var inbox_url = "/inbox";
var in_submission = [];
var pending = [];

// initialization
function init () {
    stm.DataStore['files'] = [],
    stm.DataStore['fileinfo'] = [],
    stm.DataStore['directories'] = [],
    stm.DataStore['messages'] = [];

    document.querySelector("#file_upload").addEventListener('change', function(e) {
	fu_curr_files = this.files;
	start_upload();
    }, false);
    update_inbox();
    
    jQuery('#json_object').popover({ 'title': "example attribute structure", 'content': '{ "type": "metagenome", "name": "Sample123", "biome": "human gut", ... }' });
}

// initialize the browser widget
function init_browser () {
    stm.init('http://api.metagenomics.anl.gov/api2.cgi').then(function() {
	Retina.init( { library_resource: "./" } ).then( function () {
	    Retina.add_widget({"name": "Browser", "resource": "/",  "filename": "widget.Browser.js" });
	    Retina.load_widget("Browser").then( function () {
		Retina.Widget.Browser.create('home');
	    });
	});
    });
}

// inbox functions
function show_file_info (filename) {
    var show_div = document.getElementById('inbox_file_info');
    var html = "<table class='table table-condensed' style='font-size: 14px;'>";
    if (stm.DataStore.fileinfo[filename]) {
	for (i in stm.DataStore.fileinfo[filename]) {
	    html += "<tr><th>"+i+"</th><td>"+stm.DataStore.fileinfo[filename][i]+"</td></tr>";
	}
    }
    html += "</table>";
    show_div.innerHTML = html;
}

function update_inbox (data, files, action) {
    if (data) {
	stm.DataStore.files = data.files;
	stm.DataStore.fileinfo = data.fileinfo;
	stm.DataStore.messages = data.messages;
	stm.DataStore.directories = data.directories;

	var flist = stm.DataStore.files;
	var dlist = stm.DataStore.directories;
	var messages = stm.DataStore.messages;
	
	var html = '<table><tr><td rowspan=2 style="padding-right: 20px; vertical-align: top;"><form class="form-horizontal">';
	html += '<select id="inbox_select" multiple style="width: 420px; height: 200px;" onchange="show_file_info(this.options[this.selectedIndex].value);">';
	for (var i=0; i<dlist.length; i++) {
	    html += "<optgroup style='font-style: normal;' title='this is a directory\nclick to toggle open / close' open=0 label='[ "+dlist[i]+" ] - "+stm.DataStore.fileinfo[dlist[i]].length+" files' onclick='if(event.originalTarget.nodeName==\"OPTGROUP\"){if(this.open){this.open=0;for(var i=0;i<this.childNodes.length;i++){this.childNodes[i].style.display=\"none\";}}else{this.open=1;for(var i=0;i<this.childNodes.length;i++){this.childNodes[i].style.display=\"\";}}}'>";
	    for (var h=0; h<stm.DataStore.fileinfo[dlist[i]].length; h++) {
		var fn = stm.DataStore.fileinfo[dlist[i]][h];
		var status = "'";
		if (stm.DataStore.fileinfo[fn]["error"]) {
		    status = " color: red;' "
		}
		if (stm.DataStore.fileinfo[fn]["submittable"]) {
		    status = " color: green;' ";
		}
		if (stm.DataStore.fileinfo[fn]["not submittable"]) {
		    status = " color: red;' ";
		}
		html += "<option style='display: none; padding-left: 35px;"+status+" value='"+dlist[i]+"/"+fn+"' onclick='show_file_info(\""+dlist[i]+"/"+fn+"\");'>"+fn+"</option>";
	    }
	    html += "</optgroup>";
	}
	for (var i=0; i<flist.length; i++) {
	    var status = "";
	    if (stm.DataStore.fileinfo[flist[i]]["error"]) {
		status = "style='color: red;' "
	    }
	    if (stm.DataStore.fileinfo[flist[i]]["submittable"]) {
		status = "style='color: green;' ";
	    }
	    if (stm.DataStore.fileinfo[flist[i]]["not submittable"]) {
		status = "style='color: red;' ";
	    }
	    if (stm.DataStore.fileinfo[flist[i]]["valid"]) {
		status = "style='color: green;' ";
	    }
	    html += "<option value='"+flist[i]+"' "+status+"onclick='show_file_info(\""+flist[i]+"\");'>"+flist[i]+"</option>";
	}
	html += '</select>';
	html += '</form></td><td id="inbox_feedback" style="vertical-align: top; font-size: 12px;"></td></tr><tr><td id="inbox_file_info" style="vertical-align: top;"></td></tr></table>';
	document.getElementById('inbox').innerHTML = html;
	
	if (messages.length) {
	    document.getElementById('inbox_feedback_msg').style.display = "";
	    document.getElementById('inbox_feedback_msg').innerHTML = "<button class='close' data-dismiss='alert' type='button'>x</button><strong>Info</strong><br>"+messages.join("<br>");
	}
    } else {
	if (action != 'upload_complete' && document.getElementById('inbox_feedback') && document.getElementById('inbox_feedback').innerHTML.match(/^\<img/)) {
	    alert('The inbox is already performing an operation.\nPlease wait for this to finish.');
	    return 0;
	}
	
	var params = "";
	var loading_info = " updating...<br><br>";
	if (action && action == "upload_complete") {
	    loading_info = "New files were added.";
	}
	if (files) {
	    params += 'faction='+action;
	    if (action == "del") {
		loading_info += "Deleting file(s):";
	    }
	    for (var i=0; i<files.length; i++) {
		params += '&fn='+files[i];
		loading_info += "<br>"+files[i];
	    }
	}
	if (document.getElementById('inbox_feedback')) {
	    document.getElementById('inbox_feedback').innerHTML = "<img src='loading.gif'>"+loading_info;
	}
	
	jQuery.ajax({
	    url: inbox_url,
	    dataType: 'json',
	    data: params,
	    success: update_inbox,
	    error: function (event, request, settings) {
		console.warn("AJAX error! ", event, request, settings);
	    }
	});
    }
}

/* data flow functions */
function select_files () {
    var files = [];
    var invalid = [];
    var filebox = document.getElementById('inbox_select');
    for (var i=0; i<filebox.options.length; i++) {
	var fn = filebox.options[i].value;
	if (filebox.options[i].selected) {
	    if (endsWith(fn, ".attributes")) {
		continue;
	    }
	    if (stm.DataStore.fileinfo[fn+'.attributes']) {
		files[files.length] = fn;
	    } else {
		invalid[invalid.length] = fn; 
	    }
	}
    }
    if (invalid.length) {
	alert("The following files do not have an associated attributes file:\n\n"+invalid.join(",\n")+"\n\nThese files can not be selected.");
    }
    var submission_box = document.getElementById('submission_box');
    for (var i=0; i<files.length; i++) {
	if (in_submission[files[i]]) {
	    alert("The file "+files[i]+" is already in the submission box.");
	} else {
	    submission_box.add(new Option(files[i], files[i]));
	    in_submission[files[i]] = 1;
	}
    }
}

function remove_submit_files () {
    var files = [];
    var filebox = document.getElementById('submission_box');
    for (var i=0; i<filebox.options.length; i++) {
	var fn = filebox.options[i].value;
	if (filebox.options[i].selected) {
	    in_submission[filebox.options[i].value] = 0;
	    filebox.remove(i);
	    i--;
	}
    }
}

function resolvePending () {
    for (i=0; i<pending.length; i++) {
	pending[i].resolve();
    }
}

function getResult (url) {
    var uid_element = document.getElementById('uid');
    var sid = uid_element.attributes.sid.value;

    var xhr = new XMLHttpRequest();
    xhr.addEventListener("progress", stm.updateProgress, false);
    if ("withCredentials" in xhr) {
	xhr.open('GET', url, true);
	xhr.setRequestHeader('Authorization', 'Globus-Goauthtoken '+sid);
    } else if (typeof XDomainRequest != "undefined") {
	xhr = new XDomainRequest();
	xhr.open('GET', url);
	xhr.setRequestHeader('Authorization', 'Globus-Goauthtoken '+sid);
    } else {
	alert("your browser does not support CORS requests");
	console.log("your browser does not support CORS requests");
	return;
    }
    xhr.onload = function() {
	var progressIndicator = document.getElementById('progressIndicator');
	if (progressIndicator) {
	    progressIndicator.style.display = "none";
	}
	var data = xhr.responseText;
	var w = window.open("", "Result Data");
	var d = w.document;
	d.open();
	d.write(data);
	d.close();
	
	return;
    };
    
    xhr.onerror = function() {
	alert('The data retrieval failed.');
	console.log("data retrieval failed");
	return;
    };
    
    xhr.onabort = function() {
	console.log("data retrieval was aborted");
	return;
    };
    
    var progressIndicator = document.getElementById('progressIndicator');
    if (progressIndicator) {
	progressIndicator.style.display = "";
	document.getElementById('progressBar').innerHTML = "requesting data...";
    }
    
    xhr.send();

    return 0;
}

function getUserData () {
    var promise = jQuery.Deferred();
    pending.push(promise);
    if (pending.length > 1) {
	return promise;
    }
    if (stm.DataStore['user_types']) {
	resolvePending();
	return promise;
    }
    var uid_element = document.getElementById('uid');
    var uid = uid_element.innerHTML;
    var aid = uid_element.attributes.aid.value + "?query&owner="+uid;
    var sid = uid_element.attributes.sid.value;

    var xhr = new XMLHttpRequest();
    xhr.addEventListener("progress", stm.updateProgress, false);
    if ("withCredentials" in xhr) {
	xhr.open('GET', aid, true);
	xhr.setRequestHeader('Authorization', 'Globus-Goauthtoken '+sid);
    } else if (typeof XDomainRequest != "undefined") {
	xhr = new XDomainRequest();
	xhr.open('GET', aid);
	xhr.setRequestHeader('Authorization', 'Globus-Goauthtoken '+sid);
    } else {
	alert("your browser does not support CORS requests");
	console.log("your browser does not support CORS requests");
	return;
    }
    xhr.onload = function() {
	var progressIndicator = document.getElementById('progressIndicator');
	if (progressIndicator) {
	    progressIndicator.style.display = "none";
	}
	var data = JSON.parse(xhr.responseText);
	stm.DataStore['user_types'] = [];
	for (i in data.D) {
	    if (data.D[i].attributes.type) {
		if (! stm.DataStore[data.D[i].attributes.type]) {
		    stm.DataStore[data.D[i].attributes.type] = [];
		    stm.DataStore['user_types'].push(data.D[i].attributes.type);
		}
		stm.DataStore[data.D[i].attributes.type][data.D[i].id] = data.D[i];
	    }
	}
	resolvePending();
	return;
    };
    
    xhr.onerror = function() {
	alert('The data retrieval failed.');
	console.log("data retrieval failed");
	resolvePending();
	return;
    };
    
    xhr.onabort = function() {
	console.log("data retrieval was aborted");
	resolvePending();
	return;
    };
    
    var progressIndicator = document.getElementById('progressIndicator');
    if (progressIndicator) {
	progressIndicator.style.display = "";
	document.getElementById('progressBar').innerHTML = "requesting data...";
    }
    
    xhr.send();

    return promise;
}

/* File Actions */
function check_delete_files () {
  if (confirm("really delete the selected files from your inbox?")) {
    var files = [];
    var filebox = document.getElementById('inbox_select');
    for (var i=0; i<filebox.options.length; i++) {
      if (filebox.options[i].selected) {
	files[files.length] = filebox.options[i].value;
      }
    }
    update_inbox(null, files, "del");
  }
}

function create_attributes_file () {
    var type = prompt("Please enter a type for your file");
    var filebox = document.getElementById('inbox_select');
    var file = filebox.options[filebox.selectedIndex].value;
    update_inbox(null, [ file ], "create_attributes&type="+type);
}

function uncompress_files () {
  var files = [];
  var filebox = document.getElementById('inbox_select');
  for (var i=0; i<filebox.options.length; i++) {
    if (filebox.options[i].selected) {
      files[files.length] = filebox.options[i].value;
    }
  }
  update_inbox(null, files, "uncompress");
}

function change_file_dir () {
  var dlist = stm.DataStore.directories;
  var files = [];
  var filebox = document.getElementById('inbox_select');
  for (var i=0; i<filebox.options.length; i++) {
    if (filebox.options[i].selected) {
      files[files.length] = filebox.options[i].value;
    }
  }
  if (files.length) {
    var dn = prompt("Select target directory, choose 'inbox' for top level", last_directory);
    if (dn) {
      if (dn == 'inbox') {
	files.unshift('inbox');
	update_inbox(null, files, 'move');
      } else {
	var existing = 0;
	for (var i=0; i<dlist.length; i++) {
	  if (dlist[i] == dn) {
	    existing = 1;
	    break;
	  }
	}
	if (existing) {
	  files.unshift(dn);
	  update_inbox(null, files, 'move');
	} else {
	  if (! dn.match(/^[\w\d_\.\s]+$/) ) {
	    alert('Directory names may only consist of letters, numbers and the "_" character.');
	    return false;
	  }
	  if (confirm('This directory does not exist. Do you want to create it?')) {
	    files.unshift(dn);
	    update_inbox(null, files, 'move');
	  }
	}
      }
    }
  } else {
    alert("You did not select any files to move.");
  }
}

/* Upload functions */

function start_upload () {
  if (fu_curr_files) {
    if (fu_curr_files.length > fu_curr_file) {
      
      var blob = fu_curr_files[fu_curr_file];
      const SIZE = blob.size;
      fu_curr_size = blob.size;
      fu_total_size = 0;
      for (var i=0; i<fu_curr_files.length; i++) {
	fu_total_size += fu_curr_files[i].size;
      }
      
      var start = fu_curr_offset;
      if (incomplete_files[blob.name]) {
	alert("partial upload of file '"+blob.name+"' detected, resuming upload.");
	start = incomplete_files[blob.name];
	incomplete_files[blob.name] = null;
      }
      var end = start + BYTES_PER_CHUNK;
      var chunk;
      document.getElementById('progress_display').style.display = "";

      if (start < SIZE) {
	if ('mozSlice' in blob) {
	  chunk = blob.mozSlice(start, end);
	} else {
	  chunk = blob.webkitSlice(start, end);
	}
	
	document.getElementById("upload_progress").style.display = "";
	document.querySelector("#upload_status").innerHTML = "<b>current file</b> " + blob.name + "<br><b>file</b> " + (fu_curr_file+1) + " of " + fu_curr_files.length + "<br><b>size</b> " + pretty_size(blob.size) + "<br><b>type</b> " + pretty_type(blob.type);
	fu_curr_offset = end;
	upload(chunk, blob.name);
      } else {
	var cfiles = document.getElementById("uploaded_files");
	cfiles.style.display = "";
	if (fu_curr_file == 0) {
	  cfiles.innerHTML = "<h4>completed files</h4>";
	}
	cfiles.innerHTML += "<p>"+blob.name+" ("+pretty_size(blob.size)+") <i class='icon-ok'></i></p>";

	fu_total_uploaded += fu_curr_files[fu_curr_file].size;
	fu_curr_file++;
	fu_curr_offset = 0;
	update_inbox();
	start_upload();
      }
    } else {
      var cfiles = document.getElementById("uploaded_files");
      cfiles.style.display = "";
      if (fu_curr_file == 0) {
	cfiles.innerHTML = "<h4>completed files</h4>";
      }
      cfiles.innerHTML += "<p>upload complete</p>";
      document.getElementById('progress_display').style.display = "none";

      fu_curr_files = null;
      fu_curr_file = 0;
      fu_curr_offset = 0;
      fu_total_uploaded = 0;
      document.querySelector("#prog1").value = 100;
      document.querySelector("#prog2").value = 100;
    }
  }
}

function upload(blobOrFile, fn) {
  var xhr = new XMLHttpRequest();
  xhr.open('POST', upload_url, true);
  xhr.onload = function(e) {
    if (this.status == 200) {
      console.log(this.response);
    }
  };
  var progressBar1 = document.querySelector("#prog1");
  var progressBar2 = document.querySelector("#prog2");
  xhr.upload.onprogress = function(e) {
    if (e.lengthComputable) {
      progressBar1.value = ((e.loaded + fu_curr_offset + fu_total_uploaded - BYTES_PER_CHUNK) / fu_total_size) * 100;
      progressBar2.value = ((e.loaded + fu_curr_offset - BYTES_PER_CHUNK) / fu_curr_size) * 100;
    }
  };
  xhr.addEventListener("load", uploadComplete, false);
  xhr.addEventListener("error", uploadFailed, false);
  xhr.addEventListener("abort", uploadCanceled, false);

  var fd = new FormData();
  fd.append("upload_file", blobOrFile);
  fd.append('filename', fn);
  if (fu_curr_offset >= fu_curr_size) {
    fd.append('last_chunk', 1);
  }
 
  xhr.send(fd);
  pending_uploads[pending_uploads.length] = xhr;
}

function cancel_upload () {
  if (confirm('do you really want to cancel the current upload?')) {
    for (var i=0; i<pending_uploads.length; i++) {
      pending_uploads[i].abort();
    }
    fu_curr_files = null;
    fu_curr_file = 0;
    fu_curr_offset = 0;
    fu_total_uploaded = 0;
  }
}

function uploadComplete (evt) {
  start_upload();
}

function uploadFailed (evt) {
  document.querySelector("#upload_status").innerHTML = "the upload has failed";
}

function uploadCanceled (evt) {
  document.querySelector("#upload_status").innerHTML = "the upload was canceled";
}

/* pipeline functionality */
function switchToPipeline (pipeline) {
    var container = document.getElementById('pipeline_container');
    for (i=0; i<container.childNodes.length; i++) {
	if (container.childNodes[i].nodeName == "DIV") {
	    if (container.childNodes[i].id == "pipeline-"+pipeline) {
		container.childNodes[i].style.display = "";
	    } else {
		container.childNodes[i].style.display = "none";
	    }
	}
    }
}

function fillSelect (select, type) {
    var typedata = stm.DataStore[type];
    var sel = document.getElementById(select);
    if (stm.DataStore[type]) {
	for (var h in typedata) {
	    if (typedata.hasOwnProperty(h)) {
		sel.add(new Option(typedata[h].file.name, typedata[h].id), null);
	    }
	}
    }
}

/* Helper Functions */

function toggle (id) {
  var item = document.getElementById(id);
  if (item.style.display == "none") {
    item.style.display = "";
  } else {
    item.style.display = "none";
  }
}

function pretty_size (size) {
  var magnitude = "B";
  if (size > 1024) {
    size = size / 1024;
    magnitude = "KB"
  }
  if (size > 1024) {
    size = size / 1024;
    magnitude = "MB";
  }
  if (size > 1024) {
    size = size / 1024;
    magnitude = "GB";
  }
  if (size > 1024) {
    size = size / 1024;
    magnitude = "TB";
  }
  size = size.toFixed(1);
  size = addCommas(size);
  size = size + " " + magnitude;

  return size;
}

function endsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

function pretty_type (type) {
  return type;
}

function addCommas(nStr) {
  nStr += '';
  x = nStr.split('.');
  x1 = x[0];
  x2 = x.length > 1 ? '.' + x[1] : '';
  var rgx = /(\d+)(\d{3})/;
  while (rgx.test(x1)) {
    x1 = x1.replace(rgx, '$1' + ',' + '$2');
  }
  return x1 + x2;
}

function selectAll(select) {
    for (i=0; i<select.options.length; i++) {
	select.options[i].selected = 1;
    }
}
var fu_curr_files;
var fu_curr_file = 0;
var fu_curr_offset = 0;
var fu_curr_size;
var fu_total_size;
var fu_total_uploaded = 0;
const BYTES_PER_CHUNK = 1024 * 1024; // 1MB chunk sizes.
var incomplete_files = [];
var pending_uploads = [];

var selected_submission_file;
var selected_metadata_file;
var selected_libraries = [];
var last_directory = "";
var DataStore = { 'files': [],
		  'fileinfo' : [],
		  'directories' : [],
		  'messages' : [] };

var is_a_submission_file_ending = /(fasta|fna|fastq|fa|faa|fq|jpg|gz)$/;
var url = "uploader/upload.cgi/user_inbox";

// initialization
function init () {
    document.querySelector("#file_upload").addEventListener('change', function(e) {
	fu_curr_files = this.files;
	start_upload();
    }, false);
    update_inbox();
    jQuery.get("uploader/pipelines.cgi", function(data) {
	document.getElementById("pipelines").innerHTML = data;
    });

}

function update_inbox (data, files, action) {
    if (data) {
	DataStore.files = data.files;
	DataStore.fileinfo = data.fileinfo;
	DataStore.messages = data.messages;
	DataStore.directories = data.directories;

	var flist = DataStore.files;
	var dlist = DataStore.directories;
	var messages = DataStore.messages;
	
	var submission_files = [];
	var metadata_files = [];
	
	var html = '<table><tr><td rowspan=2 style="padding-right: 20px;"><form class="form-horizontal">';
	html += '<select id="inbox_select" multiple style="width: 420px; height: 200px;">';
	var seq_dlist = [];
	var seqs_in_dir = false;
	for (var i=0; i<dlist.length; i++) {
	    html += "<optgroup title='this is a directory\nclick to toggle open / close' open=0 label='[ "+dlist[i]+" ] - "+DataStore.fileinfo[dlist[i]].length+" files' onclick='if(event.originalTarget.nodeName==\"OPTGROUP\"){if(this.open){this.open=0;for(var i=0;i<this.childNodes.length;i++){this.childNodes[i].style.display=\"none\";}}else{this.open=1;for(var i=0;i<this.childNodes.length;i++){this.childNodes[i].style.display=\"\";}}}'>";
	    for (var h=0; h<DataStore.fileinfo[dlist[i]].length; h++) {
		var fn = DataStore.fileinfo[dlist[i]][h];
		if (fn.match(is_a_submission_file_ending)) {
		    seq_dlist[dlist[i]] = 1;
		    seqs_in_dir = true;
		}
		html += "<option style='display: none; padding-left: 35px;' value='"+dlist[i]+"/"+fn+"'>"+fn+"</option>";
	    }
	    html += "</optgroup>";
	}
	for (var i=0; i<flist.length; i++) {
	    html += "<option>"+flist[i]+"</option>";
	    var isSeq = flist[i].match(is_a_submission_file_ending);
	    if (isSeq) {
		submission_files[submission_files.length] = flist[i];
	    }
	    var isMet = flist[i].match(/\.xlsx$/);
	    if (isMet) {
		metadata_files[metadata_files.length] = flist[i];
	    }
	}
	html += '</select>';
	html += '</form></td><td id="inbox_feedback"></td></tr><tr><td id="inbox_file_info"></td></tr></table>';
	document.getElementById('inbox').innerHTML = html;
	
	if (messages.length) {
	    document.getElementById('inbox_feedback').innerHTML = "<h4>Info</h4>"+messages.join("<br>");
	}
	
	var submission_file_select = document.getElementById('submission_file_select');
	var sub_opts_html = "";
	if ((submission_files.length || seqs_in_dir) && ! selected_submission_file) {	    
	    for (var i=0; i<submission_files.length; i++) {
		var fn = submission_files[i];
		sub_opts_html += "<option value='"+fn+"'>"+fn+"</option>";
	    }
	    submission_file_select.innerHTML = sub_opts_html;
	}
	if (! selected_metadata_file) {
	    html = "<div><h3>available metadata files</h3><table><tr><td><form class='form-horizontal'><select id='metadata_file_select' multiple style='width: 420px; height: 200px;'>";
	    for (var i=0; i<metadata_files.length; i++) {
		html += "<option>"+metadata_files[i]+"</option>";
	    }
	    html += "</select><br><p><input type='checkbox' value='no_metadata' name='no_metadata' id='no_metadata'> I do not want to supply metadata</p> <input type='button' class='btn' value='select' onclick='select_metadata_file();'></form></td><td><p id='metadata_file_info' style='margin-left: 20px;'></p></td></tr></table></div>";
	    document.getElementById("sel_mdfile_div").innerHTML = html;
	    document.getElementById('inbox_select').onchange = function () {
		var fn = this.options[this.selectedIndex].value;
		if (DataStore.fileinfo && DataStore.fileinfo[fn]) {
		    var ptext = "<h4>File Information</h4><br><table>";
		    for (i in DataStore.fileinfo[fn]) {
			ptext += "<tr><td><b>"+i+"</b></td><td style='padding-left: 5px;'>"+DataStore.fileinfo[fn][i]+"</td></tr>";
		    }
		    ptext += "</table>";
		    document.getElementById('inbox_file_info').innerHTML = ptext;
		} else {
		    document.getElementById('inbox_file_info').innerHTML = "";
		}
	    }
	}
    } else {
	if (action != 'upload_complete' && document.getElementById('inbox_feedback') && document.getElementById('inbox_feedback').innerHTML.match(/^\<img/)) {
	    alert('The inbox is already performing an operation.\nPlease wait for this to finish.');
	    return 0;
	}
	
	var params = "";
	var loading_info = " updating...<br><br>";
	if (action && action == "upload_complete") {
	    loading_info = "New files were added. If the upload contained submission files, they might be processed, which can take some time.";
	}
	if (files) {
	    params += '&faction='+action;
	    if (action == "del") {
		loading_info += "Deleting file(s):";
	    } else if (action == "convert") {
		loading_info += "Converting sff file(s) to fastq. The resulting files will be processed for statistics. This will take a few minutes, depending on the file size.<br><br>";
	    } else if (action == "demultiplex") {
		loading_info += "Demultiplexing in progress. The resulting files will be processed for statistics. This will take a few minutes, depending on the number of files and file size.<br><br>";
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
	    url: url,
	    dataType: 'json',
	    data: params,
	    success: update_inbox,
	    error: function (event, request, settings) {
		console.warn("AJAX error! ", event, request, settings);
	    }
	});
    }
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

// upload workflow
function select_submission_file () {
  var sel = document.getElementById('submission_file_select');
  selected_submission_files = [];
  var has_fasta = 0;
  var has_fastq = 0;
  for (i=0; i<sel.options.length; i++) {
    if (sel.options[i].selected) {
      selected_submission_files.push(sel.options[i].value);
    }
  }

  if (selected_submission_files.length == 0) {
    alert("You did not select a submission file");
  } else if (selected_submission_files.length > 1) {
    if (selected_libraries.length == 0) {
      if (document.getElementById("sel_md_pill").className == "pill_complete") {
	alert('WARNING: You have selected more than one submission file,\nbut your metadata file does not include the neccessary mapping information.\nEither select a single submission file, or correct your metadata file.');
	return 0;
      } else {
	alert("WARNING: You have selected more than one submission file.\nWhen you choose a metadata file, it must contain mapping\ninformation for each submission file.");
      }
    } else {
      if (selected_submission_files.length == selected_libraries.length) {
	var valid = 1;
	var broken = "";
	for (i=0;i<selected_submission_files.length; i++) {
	  var start = 0;
	  if (selected_submission_files[i].indexOf('/') > -1) {
	    start = selected_submission_files[i].lastIndexOf('/') + 1;
	  }
	  var fn = selected_submission_files[i].substr(start, selected_submission_files[i].lastIndexOf('.'));
	  var found = 0;
	  for (h=0; h<selected_libraries.length; h++) {
	    if (selected_libraries[h] == fn) {
	      found = 1;
	      break;
	    }
	  }
	  if (! found) {
	    valid = 0;
	    broken = selected_submission_files[i];
	    break;
	  }
	}
	if (! valid) {
	  alert("WARNING: The mapping in your selected metadata file does\nnot match the selected submission files, i.e. the submission\nfile "+broken+" does not have matching mapping.\nEither correct your metadata file or change your submission file selection.");
	  return 0;
	}
      } else if (selected_submission_files.length < selected_libraries.length) {
	var valid = 1;
	var broken = "";
	for (i=0;i<selected_submission_files.length; i++) {
	  var fn = selected_submission_files[i].substr(0, selected_submission_files[i].lastIndexOf('.'));
	  var found = 0;
	  for (h=0; h<selected_libraries.length; h++) {
	    if (selected_libraries[h] == fn) {
	      found = 1;
	      break;
	    }
	  }
	  if (! found) {
	    valid = 0;
	    broken = selected_submission_files[i];
	    break;
	  }
	}
	if (! valid) {
	  alert("WARNING: The file mapping in your selected metadata file dos\nnot match the selected submission files, i.e. the submission\nfile "+broken+" does not have a matching mapping.\nEither correct your metadata file or change your submission file selection.");
	  return 0;
	} else {
	  if (! confirm("WARNING: Your metadata contains more file mappings than you have submission files selected.\nHowever, all selected submission files have a matching mapping.\n\nDo you want to continue?")) {
	    return 0;
	  }
	}
      } else {
	alert("WARNING: The number of mapped files in your metadata file is less than\nthe number of selected submission files.\nEither correct your metadata file or change your submission file selection.");
	return 0;
      }
    }
  } else if (selected_libraries.length > 1) {
    alert("WARNING: You have selected a single submission file, but specified\nmultiple file mappings in your metadata file. Either update your metadata\nfile or select more submission files.");
    return 0;
  }

  var html = "<h4>selected submission files</h4><br><p><i>"+selected_submission_files.join("</i><br><i>")+"</i><br><br><input type='button' class='btn' value='unselect' onclick='unselect_submission_file();'><input type='hidden' name='subfiles' value='"+selected_submission_files.join("|")+"'>";
  document.getElementById("selected_submissions").innerHTML = html;
  document.getElementById("available_submissions").style.display = 'none';
  document.getElementById("sel_sub_pill").className = "pill_complete";
  document.getElementById("icon_step_2").style.display = "";
  check_submitable();
}

function unselect_submission_file () {
  selected_submission_file = "";
  document.getElementById("selected_submissions").innerHTML = "";
  document.getElementById("available_submissions").style.display = '';
  document.getElementById("sel_sub_pill").className = "pill_incomplete";
  document.getElementById("icon_step_2").style.display = "none";
  update_inbox();
  check_submitable();
}

function select_metadata_file () {
  if (document.getElementById('no_metadata').checked) {
    document.getElementById("sel_md_pill").className = "pill_complete";
    document.getElementById("icon_step_1").style.display = "";
    check_submitable();
  } else {

    var sel = document.getElementById('metadata_file_select');
    selected_metadata_file = sel.options[sel.selectedIndex].value;
    
    document.getElementById("sel_mdfile_div").innerHTML = "<p><img src='loading.gif'> please wait while your metadata file is being validated...</p>";
    
    jQuery.get("?action=validate_metadata&mdfn="+selected_metadata_file, function (data) {
	var result = data.split(/\|\|/);
	if (result[0] != "0") {
	  var html = "<div class='well'><h4>selected metadata file</h4><br>"+result[1]+"<br><p><i>"+selected_metadata_file+"</i><br><br><input type='button' class='btn' value='unselect' onclick='unselect_metadata_file();'><input type='hidden' name='mdfile' value='"+selected_metadata_file+"'></div>";
	  if (result.length == 3) {
	    selected_libraries = result[2].split(/@@/);
	  }
	  update_inbox();
	  document.getElementById("sel_mdfile_div").innerHTML = html;
	  document.getElementById("sel_md_pill").className = "pill_complete";
	  document.getElementById("icon_step_1").style.display = "";
	  
	  check_submitable();
	} else {
	  document.getElementById("sel_mdfile_div").innerHTML = result[1];
	  update_inbox();
	}
      });
  }
}
function unselect_metadata_file () {
  selected_metadata_file = "";
  selected_libraries = [];
  document.getElementById("sel_md_pill").className = "pill_incomplete";
  document.getElementById("icon_step_1").style.display = "none";
  update_inbox();
  check_submittable();
}

function accept_submission_options () {
  document.getElementById("sel_opt_pill").className = "pill_complete";
  document.getElementById("icon_step_3").style.display = "";
  check_submitable();
}

function check_submitable () {
  if ((document.getElementById("sel_sub_pill").className == "pill_complete") &&
      (document.getElementById("sel_md_pill").className == "pill_complete") &&
      (document.getElementById("sel_opt_pill").className == "pill_complete")) {
      document.getElementById("sub_pill").className = "pill_complete";
      document.getElementById("submit_button").disabled = false;
      document.getElementById("submit_button").focus();
      document.getElementById("sub_div").style.display = "";
  } else {
      document.getElementById("sub_pill").className = "pill_incomplete";
      document.getElementById("submit_button").disabled = true;      
  }
}

function perform_submission () {
  document.forms.submission_form.submit();
}

function toggle (id) {
  var item = document.getElementById(id);
  if (item.style.display == "none") {
    item.style.display = "";
  } else {
    item.style.display = "none";
  }
}

function change_file_dir () {
  var dlist = DataStore.directories;
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
  xhr.open('POST', "uploader/upload.cgi", true);
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

function select_pipeline () {
    var curr = document.getElementById('pipeline_select');
    while (curr = curr.nextSibling) {
	if (curr.nodeName && curr.nodeName == "DIV") {
	    curr.style.display = "none";
	}
    }
    var selected = document.getElementById('pipeline_select').options[document.getElementById('pipeline_select').selectedIndex].value;
    if (document.getElementById('pipeline_'+selected)) {
	document.getElementById('pipeline_'+selected).style.display = "";
    }
}
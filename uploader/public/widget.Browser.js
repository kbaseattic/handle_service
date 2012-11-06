(function () {
    widget = Retina.Widget.extend({
        about: function () {
            return {
                title: "Data Browser Widget",
                name: "Browser",
                author: "Tobias Paczian",
                requires: [ ]
            };
        }
    });

    widget.setup = function () {
	return [ getUserData(), Retina.add_renderer({"name": "table", "resource": "/", "filename": "renderer.table.js" }), this.loadRenderer('table') ];
    }
    
    widget.display = function (div, args) {
	var loaded_displays = {};
	
	div.innerHTML = "<legend>Your Data in the Auxiliary Store</legend>";
	var table_disp = document.createElement('div');
	var detail_disp = document.createElement('div');
	div.appendChild(table_disp);
	div.appendChild(detail_disp);

	Retina.Widget.Browser.detailSpace = detail_disp;

	Retina.Widget.Browser.show_data( { "display": table_disp } );
	
    };

    widget.tableclick = function (clicked_row, clicked_cell, clicked_row_index, clicked_cell_index) {
	var id = clicked_row[4];
	var type = clicked_row[0];
	Retina.Widget.Browser.show_details({ "id": id, "type": type });
    };

    widget.show_details = function (params) {
	Retina.Widget.Browser.detailSpace.innerHTML = "";
	var id = params["id"];
	var type = params["type"];
	var data = stm.DataStore[type][id];
	
	var object_attributes = [];
	
	var html = '\
<div class="tabbable tabs-left" style="margin-top: 25px;">\
<ul class="nav nav-tabs">\
<li class="active" style="min-width: 180px;">\
<a data-toggle="tab" href="#file">file</a>\
</li>';
	html += '\
<li>\
<a data-toggle="tab" href="#overview">overview</a>\
</li>';
	for (i in data.attributes) {
	    if (data.attributes.hasOwnProperty(i)) {
		if ((typeof(data.attributes[i]) == "object") && (typeof(data.attributes[i].join) == "undefined")) {
		    object_attributes.push(i);
		    var oname = i.replace(/ /g,"_"); 
		    var otitle = i.replace(/_/g," ");
		    html += '\
<li>\
<a data-toggle="tab" href="#' + oname + '">' + otitle + '</a>\
</li>';
		}
	    }
	}
	html += '\
</ul>\
<div class="tab-content">\
  <div id="file" class="tab-pane active">\
    <h4 style="margin-bottom: 5px;">'+type+' file information</h4>\
    <table class="table table-condensed">\
      <tr><th class="span3">filename</th><td>'+data.file.name+'</td></tr>\
      <tr><th class="span3">size</th><td>'+pretty_size(data.file.size)+'</td></tr>\
      <tr><th class="span3">md5</th><td>'+data.file.checksum.md5+'</td></tr>\
      <tr><th class="span3">download</th><td>'+data.id+'</td></tr>\
    </table>\
  </div>\
\
  <div id="overview" class="tab-pane">\
    <h4 style="margin-bottom: 5px;">'+type+' overview</h4>\
    <table class="table table-condensed">';
	for (i in data.attributes) {
	    if (data.attributes.hasOwnProperty(i)) {
		var otitle = i.replace(/_/g," ");
		if (typeof(data.attributes[i].join) != "undefined") {
		    html += '<tr><th class="span3">'+otitle+'</th><td>'+data.attributes[i].join(', ')+'</pre></td></tr>';
		} else if (typeof(data.attributes[i]) != "object") {
		    html += '<tr><th class="span3">'+otitle+'</th><td>'+data.attributes[i]+'</td></tr>';
		}
	    }
	}
	html += '</table>\
  </div>\
';
	for (i=0; i<object_attributes.length; i++) {
	    var oname = object_attributes[i].replace(/ /g,"_");
	    var suptitle = object_attributes[i].replace(/_/g," ");
	    html += '\
  <div id="'+oname+'" class="tab-pane">\
    <h4 style="margin-bottom: 5px;">'+suptitle+'</h4>\
    <table class="table table-condensed">';
	    for (h in data.attributes[object_attributes[i]]) {
		if (data.attributes[object_attributes[i]].hasOwnProperty(h)) {
		    var otitle = h.replace(/_/g," ");
		    if (typeof(data.attributes[object_attributes[i]][h]) == "object") {
			html += '<tr><th class="span3">'+otitle+'</th><td><pre>'+JSON.stringify(data.attributes[object_attributes[i]][h])+'</pre></td></tr>';
		    } else {
			html += '<tr><th class="span3">'+otitle+'</th><td>'+data.attributes[object_attributes[i]][h]+'</td></tr>';
		    }
		}
	    }
	    html += '</table>\
  </div>';
	}
	html += '</div>\
';
	
	Retina.Widget.Browser.detailSpace.innerHTML = html;
    };
    
    widget.show_data = function (params) {
	var target_disp = params["display"];
	var types = stm.DataStore["user_types"];
	var table_header = [ 'type', 'file', 'size', 'md5', 'id' ];
	var table_data = [];
	for (i=0; i<types.length; i++) {
	    for (h in stm.DataStore[types[i]]) {
		if (stm.DataStore[types[i]].hasOwnProperty(h)) {
		    if (stm.DataStore[types[i]][h].file.size > 0) {
			var row = [ types[i], stm.DataStore[types[i]][h].file.name, pretty_size(stm.DataStore[types[i]][h].file.size), stm.DataStore[types[i]][h].file.checksum.md5, h ];
			table_data.push(row);
		    } else {
			var row = [ types[i], "-", "-", "-", h ];
			table_data.push(row);
		    }
		}
	    }
	}

	Retina.Renderer.table.render( { "target": target_disp, "data": { "data": table_data, "header": table_header }, "sort_autodetect": true, "filter": {}, "filter_autodetect": true, "sorttype": {}, "onclick": Retina.Widget.Browser.tableclick } );
    }
    
})();

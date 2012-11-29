(function($) {
    var apiUrl = 'http://kbase.us/services/shock-api';

    var typesLoaded = {};  // hash from type to int (0 - not loaded, 1 - loading, 2 - loaded);
    var selectedType = null;

    // define the routes
    var app = $.sammy(function() {
        this.get('#:type', function() {
            var type = this.params['type'];
            selectType(type);
        });
    });

    $(document).ready(function() {
        // grab the available types
        var typesAjax = $.ajax({
            type: 'GET',
            url: 'types.json',
            dataType: 'json'
        });

        var countAjax = $.ajax({
            type: 'GET',
            url: 'type_counts.json',
            dataType: 'json'
        });

        $.when(typesAjax, countAjax).done(function(types, counts){
            for (var i in types[0]) {
                var type = types[0][i];
                typesLoaded[type] = 0;
            }
            addTypes(types[0], counts[0]);
            app.run();
        }).fail(ajaxError);
    });

    function addTypes(types, counts) {
        for (var i in types) {
            var type = types[i];
            $('#type-header').append('<div class="type-widget"><a href="#'+type+'" > \
                                        <div id="'+type+'-selector" class="well well-small">'+type+' \
                                        <span class="badge badge-inverse">'+counts[i]+'<br> \
                                        </div></a> \
                                    </div>');
        }
    }

    function selectType(type) {
        // make sure type is a valid type
        if (typesLoaded[type] === undefined) {
            alert("'" + type + "' is not a valid type");
            return;
        } else if (selectedType === type) {
            // type is already selected, do nothing
            return;
        }

        $('.well').removeClass('alert-success')
        $('#'+type+'-selector').addClass('alert-success')

        // hide the current type table
        if (selectedType !== null) {
            $('#' + selectedType + '_div').hide();
        }
        selectedType = type;

        // check if data has already been loaded
        if (typesLoaded[type] === 0) {
            // not loaded
            console.log('loading type data from AJAX call: ' + type);
            $('#type-table').append('<div id="' + type + '_div"></div>');
            typesLoaded[type] = 1;
            getNodesForType(type);
        } else if (typesLoaded[type] === 1) {
            // in the process of loading
            console.log('already loading type data for type: ' + type);
        } else if (typesLoaded[type] === 2) {
            // already loaded
            console.log('loading type data from cache: ' + type);
            $('#' + type + '_div').show();
        }
    }

    function getNodesForType(type) {
        // add the loading image and text to type_div
        $('#' + type + '_div').append('<div style="text-align:center"><img src="img/loading.gif" /><br />Loading...<br /><span id="progress"></span></div>');

        var xhr, myTrigger;
        $.ajax({
            type: 'GET',
            url:  apiUrl + '/node?query&type=' + type,
            xhr: function() {
                xhr = jQuery.ajaxSettings.xhr();
                myTrigger = setInterval (function () {
                    if (xhr.readyState > 2) {
                        var totalBytes = xhr.getResponseHeader ('Content-length');
                        var dlBytes = xhr.responseText.length;
                        if (dlBytes > -1) {
                            (totalBytes > 0) ?
                                $('#progress').html(Math.round ((dlBytes / totalBytes) * 100) + "%"):
                                $('#progress').html(prettySize(dlBytes));
                        }
                    }
                }, 200);
                return xhr;
            },
            complete: function () {
                clearInterval (myTrigger);
            }
        }).done(function(data) {
            // check for error
            if (data.E !== null) {
                alert('error loading data');
                console.log(data.E, data.S);
                // should we set typesLoaded to 0? or set it to 2?
            } else {
                var aaData = processData(data.D);
                loadDataTable(type, aaData);
                typesLoaded[type] = 2;
            }
        }).fail(ajaxError);
    }

    function processData(data) {
        // process the data objects
        var aaData = [];
        for (var i in data) {
            var node = data[i];
            if (node.file.size !== 0) {
                var downloadLink = apiUrl + '/node/' + node.id + '?download';
                var filename = '<a href="' + downloadLink + '">' + node.file.name + '</a>';

                var nodeData = [
                    filename,
                    node.attributes.name,
                    node.attributes.created,
                    prettySize(parseInt(node.file.size))
                ];
                aaData.push(nodeData);
            }
        }

        return aaData;
    }

    function prettySize(size) {
        var units = ['B', 'kB', 'MB', 'GB', 'TB', 'PB'];
        var count = 0;
        while (size > 1024) {
            count++;
            size = size/1024;
        }
        return Math.round(size*100)/100 + ' ' + units[count];
    }

    function loadDataTable(type, aaData) {
        var dataDict = {'aaData':aaData,
                        'aoColumns': [{'sTitle': "File Name"},
                                    {'sTitle': "Name"},
                                    {'sTitle': "Date Created"},
                                    {'sTitle': "Size"}]
                        };

        $('#' + type + '_div').empty().append('<table id="' + type + '_table"></table>');
        $('#' + type + '_table').dataTable(dataDict);
    }

    function ajaxError(jqXHR, textStatus, errorThrown) {
        alert('error with ajax call');
        console.log(jqXHR, textStatus, errorThrown);
    }
})(jQuery);

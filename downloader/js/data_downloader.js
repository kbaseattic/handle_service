(function($) {
    var typeCache = {};
    var allTypes;

    // define the routes
    var app = $.sammy(function() {
        this.get('#:type', function() {
            var type = this.params['type'];
            getNodesForType(type);
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
            allTypes = types[0];
            addTypes(types[0], counts[0]);
            app.run();
        }).fail(ajaxError);

        addTestTable()

    });

    function addTypes(types, counts) {
        for (var i in types) {
            var type = types[i];
            $('#type-header').append('<div class="type-widget"><a href="#'+type+'" > \
                                        <div class="well well-small">'+type+' \
                                        <span class="badge badge-inverse">'+counts[i]+'<br> \
                                        </div></a> \
                                      </div>');
        }
    }


    function getNodesForType(type) {
        // make sure type is a valid type
        if ($.inArray(type, allTypes) === -1) {
            alert("'" + type + "' is not a valid type");
            return;
        }

        setActiveType(type);

        // check if data has already been loaded
        if (typeCache[type]) {
            console.log('loading type data from cache: ' + type);
            loadDataTable(typeCache[type]);
        } else {
            $('#type-table').empty().append('loading...');
            console.log('loading type data from AJAX call: ' + type);
            $.ajax({
                type: 'GET',
                url:  'http://kbase.us/services/shock-api/node?query&type=' + type
            }).done(function(data) {
                // check for error
                if (data.E !== null) {
                    alert('error loading data');
                    console.log(data.E, data.S);
                } else {
                    var aaData = processData(data.D);
                    typeCache[type] = aaData;
                    loadDataTable(aaData);
                }
            }).fail(ajaxError);
        }
    }

    function processData(data) {
        // process the data objects
        // should we include nodes without a file? (file.size = 0)
        var aaData = [];
        for (var i in data) {
            var node = data[i];
            if (node.file.size !== 0) {
                var nodeData = [
                    node.file.name,
                    node.attributes.name,
                    node.attributes.created,
                    node.file.size
                ];
                aaData.push(nodeData);
            }
        }

        return aaData;
    }

    function ajaxError(jqXHR, textStatus, errorThrown) {
        alert('error with ajax call');
        console.log(jqXHR, textStatus, errorThrown);
    }

    function addTestTable() {
        $('#type-table').append('<table id="table"><thead><tr><th>Column 1</th><th>Column 2</th><th>etc</th>' +
		         '</tr></thead><tbody><tr><td>Row 1 Data 1</td><td>Row 1 Data 2</td><td>etc</td></tr><tr>' +
		         '<td>Row 2 Data 1</td><td>Row 2 Data 2</td><td>etc</td></tr></tbody></table>');
        $('#table').dataTable();
    }
})(jQuery);

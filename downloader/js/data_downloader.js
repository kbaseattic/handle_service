(function($) {
    var type_cache = {};

    // define the routes
    var app = $.sammy(function() {

        this.get('#/', function() {
            $('#main').text('');
        });
        
        this.get('#/test', function() {
            $('#main').text('Hello World');
        });
        
    });

    $(document).ready(function() {
        // grab the available types
            var typesAjax = $.ajax({
                type: 'GET',
                url:  'types.json'
            });

        var countAjax = $.ajax({
            type: 'GET',
            url:  'type_counts.json'
        });

        $.when(typesAjax, countAjax).done(function(types, counts){
            addTypeRoutes(types[0]);
            addTypes(types[0], counts[0]);
        }).fail(ajaxError);

    });

    function addTypeRoutes(types) {
    
    }


    function addTypes(types, counts) {
        for (var i in types) {
            var type = types[i];
            $('#type-header').append('<a href="'+type+'" ><div class="type-widget"> \
                                        <div class="well well-small">'+type+' \
                                        <span class="badge badge-inverse">'+counts[i]+'<br> \
                                        </div> \
                                      </div></a>');
        }
    }


    function getNodesForType(type) {
        if (type_cache[type]) {
            console.log('loading type data from cache: ' + type);
            loadDataTable(type_cache[type]);
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
                    type_cache[type] = data.D;
                    loadDataTable(data.D);
                }
            }).fail(ajaxError);
        }
    }

    function loadDataTable(data) {
        $('#type-table').empty().append('data');
        console.log(data);
    }

    function ajaxError(jqXHR, textStatus, errorThrown) {
        alert('error with ajax call');
        console.log(jqXHR, textStatus, errorThrown);
    }

    function addTestTable() {
        $('body').append('<table id="table"><thead><tr><th>Column 1</th><th>Column 2</th><th>etc</th>' +
		         '</tr></thead><tbody><tr><td>Row 1 Data 1</td><td>Row 1 Data 2</td><td>etc</td></tr><tr>' +
		         '<td>Row 2 Data 1</td><td>Row 2 Data 2</td><td>etc</td></tr></tbody></table>');
        $('#table').dataTable();
    }
})(jQuery);

// main routing file for data_downloader

$(document).ready(function() {
    // grab the available types
    $.ajax({
        type: 'GET',
        url:  'types.json'
    }).done(addTypes)
      .fail(ajaxError);
});

function addTypes(types) {
    for (var i in types) {
        var type = types[i];
        $('type-header').append('<div class="type-widget">'+type+'</div>')
    }
}

function getNodesForType(type) {
    $.ajax({
        type: 'GET',
        url:  'http://kbase.us/services/shock-api/node?query&type=' + type
    }).done(loadDataTable)
      .fail(ajaxError);
}

function loadDataTable(ajaxData) {
    // check for error
    if (ajaxData.E !== null) {
        alert('error loading data');
        console.log(ajaxData.E, ajaxData.S);
        return;
    }

    var data = ajaxData.D;
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

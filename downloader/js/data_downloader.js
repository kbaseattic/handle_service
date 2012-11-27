// main routing file for data_downloader

$(document).ready(function() {
    // grab the available types
    $.ajax({
        type: 'GET',
        url:  'types.json'
    }).done(function(types) {
        addTypes(types);
    }).fail(function(jqXHR, textStatus, errorThrown) {
        alert('error with ajax call');
        console.log(jqXHR, textStatus, errorThrown);
    });

    var button = $('<button>Add Table</button>');
    button.click(function() {
        $.ajax({
            type: 'GET',
            url:  'http://kbase.us/services/shock-api/node'
        }).done(function(data) {
            console.log(data);
        }).fail(function(jqXHR, textStatus, errorThrown) {
            alert('error with ajax call');
            console.log(jqXHR, textStatus, errorThrown);
        });
//	addTestTable();
	button.get(0).disabled = 'disabled';
    });
    $('body').append(button);
});

function addTypes(types) {
    
}

function addTestTable() {
    $('body').append('<table id="table"><thead><tr><th>Column 1</th><th>Column 2</th><th>etc</th>' +
		     '</tr></thead><tbody><tr><td>Row 1 Data 1</td><td>Row 1 Data 2</td><td>etc</td></tr><tr>' +
		     '<td>Row 2 Data 1</td><td>Row 2 Data 2</td><td>etc</td></tr></tbody></table>');
    $('#table').dataTable();
}

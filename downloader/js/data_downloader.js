// main routing file for data_downloader

$(document).ready(function() {
    var button = $('<button>Add Table</button>');
    button.click(function() {
	addTestTable();
	button.get(0).disabled = 'disabled';
    });
    $('body').append(button);
});

function addTestTable() {
    $('body').append('<table id="table"><thead><tr><th>Column 1</th><th>Column 2</th><th>etc</th>' +
		     '</tr></thead><tbody><tr><td>Row 1 Data 1</td><td>Row 1 Data 2</td><td>etc</td></tr><tr>' +
		     '<td>Row 2 Data 1</td><td>Row 2 Data 2</td><td>etc</td></tr></tbody></table>');
    $('#table').dataTable();
}

// main routing file for data_downloader

$(document).ready(function() {
    // something to make datatables look like bootstrap
    $.extend( $.fn.dataTableExt.oStdClasses, {
	"sWrapper": "dataTables_wrapper form-inline"
    });

    var button = $('<button>Add Table</button>');
    button.click(function() {
	addTestTable();
	button.get(0).disabled = 'disabled';
    });
    $('body').append(button);
});

function addTestTable() {
    $('body').append('<table cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered"' +
		     'id="table"><thead><tr><th>Column 1</th><th>Column 2</th><th>etc</th>' +
		     '</tr></thead><tbody><tr><td>Row 1 Data 1</td><td>Row 1 Data 2</td><td>etc</td></tr><tr>' +
		     '<td>Row 2 Data 1</td><td>Row 2 Data 2</td><td>etc</td></tr></tbody></table>');

    $('#table').dataTable({
        "sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>"
    });
}
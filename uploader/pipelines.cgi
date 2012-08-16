#!/kb/runtime/bin/perl

use strict;
use warnings;

use Data::Dumper;

use CGI;

use UploaderConfig;

my $cgi = new CGI;

if (opendir(my $dh, PIPELINE_DIR)) {
    my @pipelines = grep { /^.+\.html$/ && -f PIPELINE_DIR."/$_" } readdir($dh);
    closedir $dh;
    my $html = "<select name='pipeline' onchange='select_pipeline();' id='pipeline_select'><option value='0'>- do not run a pipeline -</option>";
    my $pipeline_options = "";
    foreach my $pipeline (@pipelines) {
	my ($pname) = $pipeline =~ /^(.+)\.html$/;
	$pname =~ s/_/ /g;
	if (open(FH, PIPELINE_DIR."/$pipeline")) {
	    $html .= "<option value='".$pipeline."'>".$pname."</option>";
	    $pipeline_options .= "<div id='pipeline_".$pipeline."' style='display: none; margin-top: 10px;' class='well'>";
	    while (<FH>) {
		$pipeline_options .= $_;
	    }
	    $pipeline_options .= "</div>";
	    close FH;
	} else {
	    print STDERR "Error opening pipeline file $pname: $@\n";
	}
    }
    $html .= "</select>";
    
    print $cgi->header( -type => 'text/html',
			-status => 200,
			-Access_Control_Allow_Origin => '*' );
    print $html."\n".$pipeline_options;
    exit 0;
} else {
    print $cgi->header( -type => 'text/html',
			-status => 200,
			-Access_Control_Allow_Origin => '*' );
    print qq~<br><div class="alert alert-error">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Warning</strong>
The pipeline directory could not be opened:<br> $@.
</div>~;
    exit 0;
}

exit 0;

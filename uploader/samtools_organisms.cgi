#!/kb/runtime/bin/perl

use strict;
use warnings;

use Data::Dumper;

use CGI;

use UploaderConfig;

my $cgi = new CGI;

# list genomes is currently not responding

my @genomes = `java -cp jnomics.jar:. edu.cshl.schatz.jnomics.manager.client.JnomicsKbaseClient compute list_genomes`;
shift @genomes;
map { chomp } @genomes;

#my @genomes = ( 'poplar3' );

print $cgi->header( -type => 'application/json',
		    -status => 200,
		    -Access_Control_Allow_Origin => '*' );
print '[ "'.join('", "', @genomes).'" ]';

exit 0;

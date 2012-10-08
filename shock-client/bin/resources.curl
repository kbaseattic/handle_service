
use strict;
use vars qw($base_url);
use Getopt::Long;
GetOptions (
	'url=s'  => \$base_url,
);

usage() unless $base_url;

my $cmd  = " curl -s -X GET ";
$cmd .= " http://$base_url";

print STDERR "command: $cmd\n";
system ($cmd);

sub usage {
print<<END;
GetOptions (
	'url=s'   => \$base_url,
);

END
exit;
}

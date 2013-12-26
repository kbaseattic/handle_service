use strict;
use Bio::KBase::HandleService;
use Getopt::Long; 
use JSON;
use Pod::Usage;

my $man  = 0;
my $help = 0;
my ($in, $out);

GetOptions(
	'h'	=> \$help,
	'help'	=> \$help,
	'man'	=> \$man,
	'i=s'   => \$in,
	'o=s'   => \$out,
) or pod2usage(0);
pod2usage(-exitstatus => 0,
	  -output => \*STDOUT,
	  -verbose => 2,
	  -noperldoc => 1,
	 ) if $help or $man;

# do a little validation on the parameters


my ($ih, $oh);

if ($in) {
    open $ih, "<", $in or die "Cannot open input file $in: $!";
}
else {
    $ih = \*STDIN;
}
if ($out) {
    open $oh, ">", $out or die "Cannot open output file $out: $!";
}
else {
    $oh = \*STDOUT;
}


# main logic
my $han = deserialize($ih);
my $obj = Bio::KBase::HandleService->new();
my $rv  = Bio::KBase::HandleService->download($han, $out);


sub serialize_handle {
	my $handle = shift or
		die "handle not passed to serialize_handle";
        my $json_text = to_json( $handle, { ascii => 1, pretty => 1 } );
	print $oh $json_text;
}	


sub deserialize_handle {
	my $ih = shift or
		die "in not passed to deserialize_handle";
	my ($json_text, $perl_scalar);
	$json_text .= $_ while ( <$ih> );
	$perl_scalar = from_json( $json_text, { utf8  => 1 } );
}

 

=pod

=head1	NAME

download

=head1	SYNOPSIS

download <params>

=head1	DESCRIPTION

The download command calls the download method of a Bio::KBase::HandleService object.

=head1	COMMAND-LINE OPTIONS

=over

=item	-h, --help, --man  This documentation

=item   -i

=item   -o

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;


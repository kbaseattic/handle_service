use strict;
use Bio::KBase::HandleService;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Data::Dumper;

my $man  = 0;
my $help = 0;
my ($in, $out);
my ($handle);

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'man'	=> \$man,
	'input=s'  => \$in,
	'output=s' => \$out,
	'handle=s' => \$handle,

) or pod2usage(0);


pod2usage(-exitstatus => 0,
	  -output => \*STDOUT,
	  -verbose => 1,
	  -noperldoc => 1,
	 ) if $help;

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 2,
          -noperldoc => 1,
         ) if $man;

pod2usage(-exitstatus => 0,
          -output => \*STDOUT,
          -verbose => 1,
          -noperldoc => 1,
         ) if ! $out;;

# do a little validation on the parameters


my ($ih, $oh);

if ($handle) {
    open $ih, "<", $handle or die "Cannot open handle file $handle: $!";
}
else {
    $ih = \*STDIN;
}


# main logic

my $h   = deserialize_handle($ih);
my $obj = Bio::KBase::HandleService->new();
my $rv  = $obj->download_metadata($h, $out);


sub serialize_handle {
	my $handle = shift or
		die "handle not passed to serialize_handle";
	my $oh = shift or
		die "out file handle not passed to serialize_handle";
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

download_metadata

=head1	SYNOPSIS

download_metadata <options>

=head1	DESCRIPTION

The download_metadata command calls the download_metadata method of a Bio::KBase::HandleService object.

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   --man

More detailed documentation

=item   -o, --output

The output file to download the metadata to (REQUIRED)

=item   --handle

The file containing the serialized handle in JSON format. If the --handle option is not specified, then STDIN will be used as the file containing the JSON formatted serialized handle.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;


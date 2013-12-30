use strict;
use Bio::KBase::HandleService;
use Getopt::Long; 
use JSON;
use Pod::Usage;

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
         ) if ! $in;
# do a little validation on the parameters


my ($ih, $oh);

if ($handle) {
    open $ih, "<", $handle or die "Cannot open input file $handle: $!";
}
else {
    $ih = \*STDIN;
}


# main logic

my $obj = Bio::KBase::HandleService->new();
my $h   = deserialize_handle($ih);
my $rv  = $obj->upload_metadata($h, $in);


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

upload_metadata

=head1	SYNOPSIS

upload_metadata <options>

=head1	DESCRIPTION

The upload_metadata command calls the upload_metadata method of a Bio::KBase::HandleService object.

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   --man

More detailed documentation

=item   -i, --input

The input file containing the metadata to upload (REQUIRED) 

=item   --handle

The file containing the serialized handle representing the data that the metadata specified by --input will be associated with. The handle input file defaults to STDIN if not provided as an option.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;


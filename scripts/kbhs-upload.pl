use strict;
use Bio::KBase::HandleService;
use Getopt::Long; 
use JSON;
use Pod::Usage;
use Data::Dumper;

my $man  = 0;
my $help = 0;
my ($in, $out);

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'man'	=> \$man,
	'input=s'  => \$in,
	'output=s' => \$out,

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

my $obj = Bio::KBase::HandleService->new();
my $rv  = $obj->upload($in);
serialize_handle($oh, $rv);

sub serialize_handle {
	my $oh = shift or
		die "output file handle not passed to serialize_handle";
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

upload

=head1	SYNOPSIS

upload <options>

=head1	DESCRIPTION

The upload command calls the upload method of a Bio::KBase::HandleService object. It takes as input a file to upload and returns a serialized handle in JSON format. The serialized handle is written to either SDTDOUT (if --output is not specified) or to a file specified by --output.

=head1	OPTIONS

=over

=item	-h, --help   Basic usage documentation

=item   --man        More detailed documentation

=item   -i, --input  The input file containing the data to upload

=item   -o, --output The output file containing the serialized data handle, default is STDOUT

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;


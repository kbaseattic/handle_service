use strict;
use Bio::KBase::AbstractHandle::Client;
use Getopt::Long; 
use JSON;
use Pod::Usage;

my $man  = 0;
my $help = 0;
my ($in, $out, $headers);

GetOptions(
	'h'	=> \$help,
        'i=s'   => \$in,
        'o=s'   => \$out,
	'help'	=> \$help,
	'man'	=> \$man,
	'input=s'  => \$in,
	'output=s' => \$out,
	'headers'  => \$headers,

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

my $obj = Bio::KBase::AbstractHandle::Client->new();
my $rv  = $obj->list_handles();

if ($headers) {
        printf $oh '# %-36s %-20s %-12s %-1s', "id","creation_date","created_by","file";
        print "\n";
}

foreach my $h (@$rv) {
        printf $oh '%-38s %-20s %-12s %-1s',
                $h->[0], $h->[7], $h->[6], $h->[1];
        print $oh "\n";

}


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

list_handles

=head1	SYNOPSIS

list_handles <options>

=head1	DESCRIPTION

The list_handles command calls the list_handles method of a Bio::KBase::AbstractHandle::Client object.

=head1	OPTIONS

=over

=item	-h, --help

Basic usage documentation

=item   --man

More detailed documentation

=item   -o, --output

The output file to write the handle listing, default is STDOUT

=item   --headers

If specified, a header line is written to the output.

=back

=head1	AUTHORS

Thomas Brettin

=cut

1;


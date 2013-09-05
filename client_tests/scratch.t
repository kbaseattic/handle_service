use Bio::KBase::DataStoreInterface::Client;
use Data::Dumper;
use File::Spec;
use JSON -support_by_pp;



package main;

my $infile = shift;
my $dsi    = DataStoreInterface->new();
my $handle = $dsi->upload($infile, $detached="FALSE");


my $outfile = shift;
$dsi->download($handle, $outfile);






package DataStoreInterface;
use Data::Dumper;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub upload {
    my $self   = shift;
    my $infile = shift or die "no infile provided";
    my $detached  = shift;

    $infile = File::Spec->rel2abs($infile);
    $handle = {
	 	url       => "http://localhost:7078",
		file_name => $infile,
		type      => 'shock',
		id        => '',
	      };

    # This is not working, shock-client won't support it yet.
    if(defined $detached && $detached =~ /TRUE/i) {

    }

    $cmd    = "shock-client pcreate -full=$infile -threads=4";
    print $cmd, "\n";
    my $rv  = `$cmd`;
    if ( $? ) { die "$! could not run $cmd returned $?"; }

    my $json = JSON->new->allow_nonref;
    $ref     = $json->decode($rv);
    $handle->{id} = $ref->{id};
    $handle->{server_md5} = $ref->{file}->{checksum}->{md5};
    # print "INFO: got $url from the handle\n";
    # print "INFO: return value from pcreate\n", $rv;
    # print "INFO: handle is\n", Dumper $handle, "\n";

    print Dumper $handle;
    return $handle;
}


sub download {
    my $self    = shift;
    my $handle  = shift;
    my $outfile = shift;

    # pdownload seems to lose the last chunk on download
    #$cmd    = "shock-client pdownload -threads=4 $handle->{id} $outfile";
    $cmd    = "shock-client download $handle->{id} > $outfile";
    print $cmd, "\n";
    my $rv  = `$cmd`;
    if ( $? ) { die "$! could not run $cmd returned $?"; }
}    

sub is_valid_transfer() {
    my $self = shift;
    my $handle = shift or die "bad number of args to is_valid_transfer";
    my $checksum = shift or die "bad number of args to is_valid_transfer";
    return $handle->{server_md5} eq $checksum;
}
    

1;

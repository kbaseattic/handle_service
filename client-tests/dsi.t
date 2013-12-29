use Test::More;
use Config::Simple;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Basename;
use JSON;
use Data::Dumper;

my $data = "./client-tests/test-reads.fa";
my $metadata = "./client-tests/test-metadata.json";

my $basename = basename $data;
unlink $data.download if -e $data.download;
unlink $metadata.download if -e $metadata.download;

our $cfg = {};
our ($obj, $h);

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "can not create Config object";
    print "using $ENV{KB_DEPLOYMENT_CONFIG} for configs\n";
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('handle_service.service-host', '127.0.0.1');
    $cfg->param('handle_service.service-port', '7109');
}


open (my $fh, '<', $data) or die "Can't open '$data': $!";
binmode($fh);
my $local_md5 = Digest::MD5->new->addfile($fh)->hexdigest;
close($fh);


my $url = "http://" . $cfg->param('handle_service.service-host') . 
	  ":" . $cfg->param('handle_service.service-port');


# the question here becomes which Bio::KBase::HandleService.pm file is going
# to be loaded. I shouldn't care. The envoronment should dictate
# which file gets loaded based on the PERL5LIB path. When I'm developing,
# it should be the one in the dev_container. When Mriiam tests, it should
# be in the deployment. So it comes from user-env.sh.

# what does this really mean? The url and port are passed to the HandleService
# constructor. That url is passed to the AbstractHandle constructor.
# The url must represent the host and port that the AbstractHandleImpl
# class is loaded on.

# and I want the url and port to come from the deploy.cfg or deployment.cfg
# files.

BEGIN {
	use_ok( Bio::KBase::HandleService );
	use_ok( Digest::MD5, qw(md5 md5_hex md5_base64) );
}

ok(system("curl -h > /dev/null 2>&1") == 0, "can run curl");

can_ok("Bio::KBase::HandleService", qw(
	new_handle
	localize_handle
	initialize_handle
	upload
	download
	upload_metadata
	download_metadata
	list_handles
	 )
);


isa_ok ($obj = Bio::KBase::HandleService->new($url), Bio::KBase::HandleService);

ok ($h = $obj->new_handle(), "new_handle returns defined");

ok (exists $h->{url}, "url in handle exists");

ok (defined $h->{url}, "url defined in handle $h->{url}");
 
ok (exists $h->{id}, "id in handle exists");

ok (defined $h->{id}, "id defined in handle $h->{id}");


$l = $obj->list_handles();

printf '%-38s %-20s %-12s %-1s', "id","creation_date","created_by","file";
print "\n";

foreach my $h (@$l) {
        printf '%-38s %-20s %-12s %-1s',
                $h->[0], $h->[7], $h->[6], $h->[1];
        print "\n";

}

# upload a file

ok ($h = $obj->upload($data), "upload returns defined");

ok (ref $h eq "HASH", "upload returns a hash reference");

ok (exists $h->{url}, "url in handle exists");

ok (defined $h->{url}, "url defined in handle $h->{url}");
 
ok (exists $h->{id}, "id in handle exists");

ok (defined $h->{id}, "id defined in handle $h->{id}");

ok ($h->{remote_md5} eq $local_md5, "uploaded file has correct md5");

ok ($h->{file_name} eq $basename, "file name is $basename");

$l = $obj->list_handles();

printf '%-38s %-20s %-12s %-1s', "id","creation_date","created_by","file";
print "\n";

foreach my $h (@$l) {
        printf '%-38s %-20s %-12s %-1s',
                $h->[0], $h->[7], $h->[6], $h->[1];
        print "\n";

}

# download a file

ok (! defined ($obj->download($h, $data.download)), "download returns");

open (my $dh, '<', $data.download) or die "Can't open $data.download: $!";
binmode($dh);
my $local_copy_md5 = Digest::MD5->new->addfile($dh)->hexdigest;
close($dh);

ok ($local_md5 eq $local_copy_md5, "MD5s are the same");


# check the meta_data methods

ok (ref $h eq 'HASH', "handle is a hash reference");
ok (-e $metadata, "metadata file exists");
ok (! defined ($obj->upload_metadata($h, $metadata)), "upload_metadata returns");
ok (! defined ($obj->download_metadata($h, $metadata.download)), "download_metadata returns");

ok (-e $metadata.download && (-s $metadata.download > 0), "metadata download file exits");

$l = $obj->list_handles();

printf '%-38s %-20s %-12s %-1s', "id","creation_date","created_by","file";
print "\n";

foreach my $h (@$l) {
	printf '%-38s %-20s %-12s %-1s',
		$h->[0], $h->[7], $h->[6], $h->[1];
	print "\n";
	
}
# clean up
done_testing;
# unlink $data.download;
# unlink $metadata.download;


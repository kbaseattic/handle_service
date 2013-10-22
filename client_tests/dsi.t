use Test::More;
use Config::Simple;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Basename;


my $file_name = "./client_tests/test-reads.fa";
my $basename = basename $file_name;

our $cfg = {};
our ($obj, $h);

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "can not create Config object";
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('data_store_interface.test-service-host', '127.0.0.1');
    $cfg->param('data_store_interface.test-service-port', '1212');
}


open (my $fh, '<', $file_name) or die "Can't open '$file_name': $!";
binmode($fh);
my $local_md5 = Digest::MD5->new->addfile($fh)->hexdigest;
close($fh);


my $url = "http://" . $cfg->param('data_store_interface.test-service-host') . 
	  ":" . $cfg->param('data_store_interface.test-service-port');


# the question here becomes which Bio::KBase::DSI.pm file is going
# to be loaded. I shouldn't care. The envoronment should dictate
# which file gets loaded based on the PERL5LIB path. When I'm developing,
# it should be the one in the dev_container. When Mriiam tests, it should
# be in the deployment. So it comes from user-env.sh.

# what does this really mean? The url and port are passed to the DSI
# constructor. That url is passed to the DataStoreInterface constructor.
# The url must represent the host and port that the DataStoreInterfaceImpl
# class is loaded on.

# and I want the url and port to come from the deploy.cfg or deployment.cfg
# files.

BEGIN {
	use_ok( Bio::KBase::DSI );
	use_ok( Digest::MD5, qw(md5 md5_hex md5_base64) );
}

ok(system("curl -h > /dev/null 2>&1") == 0, "can run curl");

can_ok("Bio::KBase::DSI", qw(
	new_handle
	localize_handle
	initialize_handle
	upload
	download )
);


isa_ok ($obj = Bio::KBase::DSI->new($url), Bio::KBase::DSI);

ok ($h = $obj->new_handle(), "new_handle returns defined");

ok (exists $h->{url}, "url in handle exists");

ok (defined $h->{url}, "url defined in handle $h->{url}");
 
ok (exists $h->{id}, "id in handle exists");

ok (defined $h->{id}, "id defined in handle $h->{id}");


# upload a file

ok ($h = $obj->upload($file_name), "upload returns defined");

ok (ref $h eq "HASH", "upload returns a hash reference");

ok (exists $h->{url}, "url in handle exists");

ok (defined $h->{url}, "url defined in handle $h->{url}");
 
ok (exists $h->{id}, "id in handle exists");

ok (defined $h->{id}, "id defined in handle $h->{id}");

ok ($h->{remote_md5} eq $local_md5, "uploaded file has correct md5");

ok ($h->{file_name} eq $basename, "file name is $basename");


# download a file

ok ($h = $obj->download($h, "f.tmp"), "download returns a handle");

open (my $dh, '<', 'f.tmp') or die "Can't open 'f.tmp': $!";
binmode($dh);
my $local_copy_md5 = Digest::MD5->new->addfile($dh)->hexdigest;
close($dh);

ok ($local_md5 eq $local_copy_md5, "MD5s are the same");



# clean up
done_testing;
unlink "f.tmp";


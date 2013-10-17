use Test::More;
use Config::Simple;

our $cfg = {};

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "can not create Config object";
}
else {
    $cfg = new Config::Simple(syntax=>'ini');
    $cfg->param('data_store_interface.test-service-host', '127.0.0.1');
    $cfg->param('data_store_interface.test-service-port', '1212');
}

my $file_name = "test-reads.fa";
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

can_ok("Bio::KBase::DSI", qw(
	new_handle
	locate
	initialize_handle
	upload
	download )
);


isa_ok ($obj = Bio::KBase::DSI->new($url), Bio::KBase::DSI);

ok ($h = $obj->new_handle(), "new_handle returns defined");

ok ($h = $obj->upload($file_name.upload), "upload returns a handle");

ok ($h = $obj->download($file_name.download), "download returns a handle");

ok (md5($file_name.upload) eq md5($file_name.download), "MD5s are the same");

done_testing;


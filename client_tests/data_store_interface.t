use Test::More;

BEGIN {
	use_ok( Bio::KBase::DataStoreInterface::Client );
	use_ok( Config::Simple );
}


if (! exists $ENV{KB_DEPLOYMENT_CONFIG} ) {
	$ENV{KB_DEPLOYMENT_CONFIG} = "deploy.cfg";
} 
$cfg = Config::Simple->new($ENV{KB_DEPLOYMENT_CONFIG});
$url = "http://localhost:9998";


can_ok("Bio::KBase::DataStoreInterface::Client", qw(
	new_handle
	locate
	initialize_handle)
);

isa_ok($obj = Bio::KBase::DataStoreInterface::Client->new($url),
	"Bio::KBase::DataStoreInterface::Client");

is(ref ($h = $obj->new_handle("Service") ), "HASH", "handle is a hash");

ok(exists $h->{url}, "url exists in handle");
ok(defined $h->{url}, "handle url is defined");

ok(exists $h->{id}, "id exists in handle");
ok(defined $h->{id}, "handle id is defined");

ok(exists $h->{type}, "type exists in handle");
ok(defined $h->{type}, "handle type is defined");

ok(exists $h->{file_name}, "file_name exists in handle");
ok(!defined $h->{file_name}, "handle filename is undefined");

ok( defined $obj->locate("ServiceName"), "locate returns defined" );
ok( defined $obj->initialize_handle(), "initialize_handle returns defined");


done_testing;


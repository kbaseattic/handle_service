use Test::More;
use Data::Dumper;

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
	localize
	initialize_handle)
);

isa_ok($obj = Bio::KBase::DataStoreInterface::Client->new($url),
	"Bio::KBase::DataStoreInterface::Client");

is(ref ($h = $obj->new_handle() ), "HASH", "handle is a hash");

print Dumper $h;

ok(exists $h->{url}, "url exists in handle");
ok(defined $h->{url}, "handle url is defined");

ok(exists $h->{id}, "id exists in handle");
ok(defined $h->{id}, "handle id is defined");

done_testing;


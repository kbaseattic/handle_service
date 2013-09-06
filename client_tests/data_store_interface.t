use Test::More;

BEGIN {
	use_ok( Bio::KBase::DataStoreInterface::Client );
}

can_ok("Bio::KBase::DataStoreInterface::Client", qw(
	new_handle
	locate
	initialize_handle)
);


done_testing;


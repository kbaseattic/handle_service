use Test::More;

BEGIN {
	use_ok( Bio::KBase::DSI );
}

can_ok("Bio::KBase::DSI", qw(
	new_handle
	locate
	initialize_handle
	upload
	download )
);


done_testing;


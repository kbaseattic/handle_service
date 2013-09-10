use Test::More;

BEGIN {
	use_ok( Bio::KBase::DSI );
	use_ok( Digest::MD5 );
}

$url = "http://localhost:9998";

can_ok("Bio::KBase::DSI", qw(
	new_handle
	locate
	initialize_handle
	upload
	download )
);


isa_ok ($obj = Bio::KBase::DSI->new(), Bio::KBase::DSI);

# this fails right now because under the hood the DSI object is
# delegating to a DataStoreInterface object, and the DataStoreInterface
# object isn't getting a valid url to connect to the service.
ok ($h = $obj->new_handle("ServiceName"), "new_handle returns defined");

ok ($h = $obj->upload($file_name.upload), "upload returns a handle");

ok ($h = $obj->download($file_name.download), "download returns a handle");

ok (md5($file_name.upload) eq md5($file_name.download), "MD5s are the same");

done_testing;


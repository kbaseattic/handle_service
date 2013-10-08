use Test::More;
my $file_name = "";

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


isa_ok ($obj = Bio::KBase::DSI->new(), Bio::KBase::DSI);

ok ($h = $obj->new_handle(), "new_handle returns defined");

ok ($h = $obj->upload($file_name.upload), "upload returns a handle");

ok ($h = $obj->download($file_name.download), "download returns a handle");

ok (md5($file_name.upload) eq md5($file_name.download), "MD5s are the same");

done_testing;


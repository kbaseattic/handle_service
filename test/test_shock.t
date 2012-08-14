#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 21;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Request::Common qw(POST);
use HTML::Parser;
use JSON;
my $json = new JSON;

my $HOST = "10.0.8.10";
   $HOST = "140.221.92.148";
my $PORT = "8000";
my $BASE_URL = "http://$HOST:$PORT";
my $uri = "$BASE_URL/register";
my $response;
my $response_hash;

#
#  Attribute file to be sent (in json format)
#
my $attfile  = "attributes.json";
#
#  Input file to be sent - any old ASCII file
#
my $filename = "protein.faa";

#
#	Parse the HTML response and find the node ID number
#
sub html_parse
{
	my $content = shift;
	no strict 'vars';
	local $html = '';
	my $id = '';
	my $p = HTML::Parser->new(
        'api_version' => 3,
         text_h       => [ \&text_handler,"dtext"],
         );
	$p->parse( $content );
	$p->eof();

	if ($html =~ /\//) {
		my @split = split(/\//,$html);
		$id = $split[-1];
	}
#	print "DEBUG: ID=$id and HTML=$html\n\n";
	return($id);
}

#
#  HTML Parsing Text - Only keep the line with the URI
#
sub text_handler {
    no strict 'vars';
    my ( $text) = @_;
    $html .="$text" if ($text =~ /^http/);
}

#
#	Check all of the attributes in a response to see if 
#	they match what is expected
#
sub check_response
{
	my $response = shift;
	my $attrib   = shift;
	my $id       = shift;
	my $filename = shift;
	is ($response->{'checksum'},$attrib->{'md5'}, 'Is the GET checksum right?');
	is ($response->{'size'},$attrib->{'size'}, 'Is the GET size right?');
	is ($response->{'id'},$id, 'Is the ID right?');
	is ($response->{'file_name'},$filename, 'Is the GET file name right?');

	if (ref($response->{'attributes'}) =~ /HASH/)
	{
		foreach my $key (keys(%{$response->{'attributes'}}))
		{
#			print "DEBUG: KEY=$key RSP=$response->{'attributes'}->{$key} ATTRIB=$attrib->{$key}\n";
			is ($response->{'attributes'}->{$key}, $attrib->{$key}, "Is the GET Attribute for $key right");
		}
	}
}

#-------------------------------------------------------------------------
#	Initialize
#
#	Attributes for the file being sent
#
my %attrib ;
$response       = `md5sum $filename`;
($attrib{'md5'})  = split(/ +/,$response);
$attrib{'size'} = -s $filename;

#
#	Optional set of attributes associated with the in file
#	These are in addition to the ones automatically created
#	for checksum, size, and file_name
#	They are sent as a separate file.  Decode from JSON
#	and add to the %attrib hash.
#
open (FH,$attfile) || die "Could not find $attfile";
my @lines = <FH>;
close FH;
my $file_contents = join('',@lines);
my $in_attrib = $json->decode($file_contents);
foreach my $key (keys(%$in_attrib))
{
	$attrib{$key} = $in_attrib->{$key};
#	print "DEBUG: KEY=$key VALUE=$in_attrib->{$key}\n";
}

#
#	Contents of the file being sent
#
open (FH,$filename) || die "Could not find $filename";
@lines = <FH>;
close FH;
$file_contents = join('',@lines);

#-------------------------------------------------------------------------
#	TESTING ASCII file
#
#	Set up the request
#

my $browser = LWP::UserAgent->new;
# set the http command (POST, GET, DELETE, or CHANGE)
my $req = HTTP::Request->new( 'POST', $uri );

#
#  Send POST request - was it a redirect as expected
#
$response = $browser->post(
            "$uri",
            Content_Type => 'multipart/form-data',
            Content => [ file => [undef, $filename, Content=>$file_contents ], attributes => [$attfile] ]
     );
ok( $response->is_redirect, "Did a POST job get redirected successfully?" );

my ($id) = &html_parse($response->content );

#
#  Test the ID just extracted with GET
#	with /node/<id>, the response should
#	have attributes of the file that was submitted
#
$uri = "$BASE_URL/node/$id/";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_success, "Did a GET job get submitted successfully?" );
#print "DEBUG: RESPONSE=".$response->content."\n\n";

$response_hash = $json->decode( $response->content ); 

&check_response($response_hash,\%attrib,$id,$filename);

#
#  Request a download of the contents of the file
#	Then compare to the actual file contents
#
$uri = "$BASE_URL/node/$id/?download";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_success, "Did a GET download job get submitted successfully?" );

#print "RESPONSE=".$response->content."\n FILE_CONTENTS=$file_contents \n";

is ($response->content, $file_contents, 'Is the response back the same as the input file');

#--------------------------------------------------------------------------------------
#
#	REPEAT the process with a binary file
#  	Input file to be sent - 
#
$filename = "protein.faa.psq";

#
#	Contents of the file being sent
#
open (FH,$filename) || die "Could not find $filename";
@lines = <FH>;
close FH;
$file_contents = join('',@lines);

$response       = `md5sum $filename`;
($attrib{'md5'})  = split(/ +/,$response);
$attrib{'size'} = -s $filename;
#print "DEBUG: MD5=$attrib{'md5'} and SIZE=$attrib{'size'} for FILENAME=$filename\n";

#
#	Set up the new request
#

$uri = "$BASE_URL/register";
$browser = LWP::UserAgent->new;
# set the http command (POST, GET, DELETE, or CHANGE)
$req = HTTP::Request->new( 'POST', $uri );

#
#  Send POST request - was it a redirect as expected
#
$response = $browser->post(
            "$uri",
            Content_Type => 'multipart/form-data',
            Content => [ file => [undef, $filename, Content=>$file_contents ], attributes => [$attfile] ]
     );
ok( $response->is_redirect, "Did a POST job get redirected successfully?" );

#
#  Parse the HTML response and find the node ID number
#
($id) = &html_parse($response->content);

#
#  Test the ID just extracted with GET
#	with /node/<id>, the response should
#	have attributes of the file that was submitted
#
$uri = "$BASE_URL/node/$id/";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_success, "Did a GET job get submitted successfully?" );
#print "DEBUG: RESPONSE=".$response->content."\n\n";

$response_hash = $json->decode( $response->content ); 

#
#	Check the attributes found in the response
#
&check_response($response_hash,\%attrib,$id,$filename);

#
#  Request a download of the contents of the file
#	Then compare to the actual file contents
#
$uri = "$BASE_URL/node/$id/?download";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_success, "Did a GET download job get submitted successfully?" );

#print "RESPONSE=".$response->content."\n FILE_CONTENTS=$file_contents \n";

is ($response->content, $file_contents, 'Is the response back the same as the input file');




#-----------------------------------------------------------------------------
#	Tests that should fail due to bad inputs
#

$uri = "$BASE_URL/in_valid";
$response = $browser->post(
            "$uri",
            Content_Type => 'multipart/form-data',
            Content => [ file => [undef, $filename, Content=>$file_contents ], attributes => [$attfile] ]
     );
ok( $response->is_error, "Give POST an invalid request and it should generate an error" );

TODO: {
	my $TODO = "This code is returning 'Cannot POST /in_valid' instead of returning an Error status";
#	print "DEBUG: RESPONSE=".$response->content."\n\n";
#	$response_hash = $json->decode( $response->content );
#	is($response_hash->{status},'Error', "Return - has Error 'Status' in content");
}

$uri = "$BASE_URL/node/$id/?in_valid_request";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_error, "Give GET an invalid request and it should generate an error" );

TODO: {
	my $TODO = "This code is returning data for the node instead of returning an Error status";
#	print "DEBUG: RESPONSE=".$response->content."\n\n";
#	$response_hash = $json->decode( $response->content );
#	is($response_hash->{status},'Error', "Return - has Error 'Status' in content");
}

$response = $browser->post(
            "$uri",
            Content_Type => 'multipart/form-data',
            Content => [ file => [undef, $attfile, Content=>$file_contents ], attributes => [$filename] ]
     );
ok( $response->is_error, "POST with bad attribute should fail with HTTP error code?" );

TODO: {
	my $TODO = "This code is returning instead of returning an Error status";
#	print "DEBUG: RESPONSE=".$response->content."\n\n";
#	$response_hash = $json->decode( $response->content );
#	is($response_hash->{status},'Error', "Return - has Error 'Status' in content");
}


#
#  Test the ID just extracted with GET
#	with /node/<id>, the response should
#	have attributes of the file that was submitted
#
$uri = "$BASE_URL/node/999999999/";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_success, "Unknown ID - Did a GET job submit and return successfully?" );
#print "DEBUG: RESPONSE=".$response->content."\n\n";
$response_hash = $json->decode( $response->content );
is($response_hash->{status},'Error', "Return - has Error 'Status' in content");

$uri = "$BASE_URL/node/NAN/";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_success, "String ID - Did a GET job get submitted successfully?" );
#print "DEBUG: RESPONSE=".$response->content."\n\n";
$response_hash = $json->decode( $response->content );
is($response_hash->{status},'Error', "Return - has Error 'Status' in content");

$uri = "$BASE_URL/register/";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_success, "Use 'register' in URI - Did a GET job get submitted successfully?" );
#print "DEBUG: RESPONSE=".$response->content."\n\n";
like($response->content, qr/DOCTYPE/, "Return - generates html as its return");

$uri = "$BASE_URL/in_valid/";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_error, "Use 'in_valid' in URI - Did a GET job get error?" );

TODO: {
	my $TODO = "This code is returning 'Cannot GET /in_valid/' instead of returning an Error status";
#	print "DEBUG: RESPONSE=".$response->content."\n\n";
#	$response_hash = $json->decode( $response->content );
#	is($response_hash->{status},'Error', "Return - has Error 'Status' in content");
}

$uri = "$BASE_URL/";
$req = HTTP::Request->new( 'GET', $uri );
$response = $browser->request($req);

ok( $response->is_error, "Forget 'node' - Did a GET job generate error?" );

TODO: {
	my $TODO = "This code is returning 'Cannot GET /in_valid/' instead of returning an Error status";
#	print "DEBUG: RESPONSE=".$response->content."\n\n";
#	$response_hash = $json->decode( $response->content );
#	is($response_hash->{status},'Error', "Return - has Error 'Status' in content");
}

=pod

=head1 TESTING FOR SHOCK

=head2 Test POST/GET on ASCII file

=over 

=item Did a POST job get redirected successfully?

=item Did a GET job with the same ID get submitted successfully?

=item Are the attributes right

=over 

=item Is the GET checksum right?

=item Is the GET size right?

=item Is the ID right?

=item Is the GET file name right?

=item Is the GET Attribute for source right

=item Is the GET Attribute for file_list right

=item Is the GET Attribute for fake_id right

=item Is the GET Attribute for file_name right

=item Is the GET Attribute for description right

=back

=item Did a GET download job get submitted successfully?

=item Is the response back the same as the input file

=back

=head2 Test POST/GET on Binary File

=over

=item Did a POST job get redirected successfully?

=item Did a GET job with the returned ID get submitted successfully?

=item Returned attributes

=over 

=item Is the GET checksum right?

=item Is the GET size right?

=item Is the ID right?

=item Is the GET file name right?

=item Is the GET Attribute for source right

=item Is the GET Attribute for file_list right

=item Is the GET Attribute for fake_id right

=item Is the GET Attribute for file_name right

=item Is the GET Attribute for description right

=back

=item Did a GET download option get submitted successfully?

=item Is the response back the same as the input file

=back

=head2 Tests that should fail and have predictable Error messages

=over

=item Give POST an invalid request and it should generate an HTTP error

=over

=item TODO - It would be nice if the returned content had a status of Error

=back

=item Give GET an invalid request and it should generate an error

=over

=item TODO - It would be nice if the returned content had a status of Error

=back

=item POST with bad attribute file should fail with HTTP error code?

=over

=item TODO - It would be nice if the returned content had a status of Error

=back

=item Unknown ID - Did a GET job submit and return successfully?

=item Return - has Error 'Status' in content

=item String ID - Did a GET job get submitted successfully?

=item Return - has Error 'Status' in content

=item Use 'register' in URI - Did a GET job get submitted successfully?

=item Return - generates html as its return

=item Use 'in_valid' in URI - Did a GET job get error?

=over

=item TODO - It would be nice if the returned content had a status of Error

=back

=back

=cut

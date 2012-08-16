#!/bin/env perl
#
# Tests for key/secret pair generation at the client level, which
# inadvertantly tests some functions of the directory as well.
#
# msneddon
# mwsneddon@lbl.gov
# 5/15/12

use lib "../lib/";
use lib "lib";
use Data::Dumper;
use HTTP::Daemon;
use HTTP::Request;
use LWP::UserAgent;
use Net::OAuth;
use JSON;
use Digest::MD5 qw( md5_base64);
use Test::More tests => 12;

BEGIN {
    use_ok( Bio::KBase::AuthDirectory);
    use_ok( Bio::KBase::AuthServer);
    use_ok( Bio::KBase::AuthClient);
}


sub testServer {
    my $d = shift;
    my $res = new HTTP::Response;
    my $msg = new HTTP::Message;
    my $as = new Bio::KBase::AuthServer;

    while (my $c = $d->accept()) {
	 while (my $r = $c->get_request) {
	    note( sprintf "Server: Recieved a connection: %s %s\n\t%s\n", $r->method, $r->url->path, $r->content);

	    my $body = sprintf("You sent a %s for %s.\n\n",$r->method(), $r->url->path);
	    $as->validate_request( $r);
	    if ($as->valid) {
		$res->code(200);
		$body .= sprintf( "Successfully logged in as user %s\n",
				  $as->user->user_id);
	    } else {
		$res->code(401);
		$body .= sprintf("You failed to login: %s.\n", $as->error_message);
	    }
	    $res->content( $body);
	    $c->send_response($res);
	}
	$c->close;
	undef($c);
    }
}



sub testClientKeyGen {
	my $server = shift;

	## create a new user for testing
	my $new_user_id = 'testUser44'; # + time;
	my $user = Bio::KBase::AuthUser->new(
		'email' => 'blah@somewhere.com',
		'user_id' => $new_user_id,
		'name' => 'Sir Tester 44',
	);
	my $ad = Bio::KBase::AuthDirectory->new();
	$user = $ad->create_user($user); #yes, this is ridiculous. I've filed an enhancement request with Stephen.

	## create a key pair through the directory that we can use to login
	$firstPair = $ad->new_consumer('testUser44');
	note( Dumper($firstPair));

	##############

	# First we login using key/secret for the user
	my $client = Bio::KBase::AuthClient->new(
		consumer_key => $firstPair->{'oauth_key'},
		consumer_secret => $firstPair->{'oauth_secret'});
   ok($client->{logged_in}, "Logging in with new user" );

	# Second try to generate a new key/secret pair for the new user
	my $newPair = $client->new_consumer();
   ok($newPair, "Generating new key/secret pair." );
	note( Dumper($newPair) );

	# Third lets logout and confirm that we actually did logout
	$client->logout();
	ok(!$client->{logged_in},"Logging out");

	# Fourth lets try this login thang again with my new creds
	$client = Bio::KBase::AuthClient->new(
		consumer_key => $newPair->{'oauth_key'},
		consumer_secret => $newPair->{'oauth_secret'});
   ok($client->{logged_in}, "Logging in with new pair generated at client level" );

   # Make sure that we can actually do something
   my $ua = LWP::UserAgent->new();
   my $req = HTTP::Request->new( GET => $server. "myURL" );
	ok($client->sign_request($req), "Signing HTTP request");
	note( sprintf "Client: Sending legit request: %s %s (expecting success)\n",$req->method,$req->url->as_string);

	$res = $ua->request( $req);
	ok( ($res->code >= 200) && ($res->code < 300), "Querying server with oauth creds");
	note( sprintf "Client: Recieved a response: %d %s\n", $res->code, $res->content);

	# Finally lets logout and confirm that we actually did logout
	$client->logout();
	ok(!$client->{logged_in},"Logging out");

	##############

	## delete the user
	ok($ad->delete_user($new_user_id), "User delete");

}




ok( $d = HTTP::Daemon->new( LocalAddr => '127.0.0.1'),
	"Creating a HTTP::Daemon object for handling AuthServer") || die "Could not create HTTP::Daemon";

note("Server listening at ".$d->url);

my $child = fork();
if ($child) {
    note( "Running client in parent process $$");
    testClientKeyGen($d->url);
} else {
    note( "Running server in pid $$");
    testServer( $d);
}

kill 9, $child;

done_testing();




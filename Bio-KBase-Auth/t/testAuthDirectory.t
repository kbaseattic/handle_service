#!/bin/env perl
#
# Test some basic auth calls
# sychan@lbl.gov
# 5/3/12
#

use lib "../lib/";
use lib "lib";
use Data::Dumper;
use Test::More tests => 15;

BEGIN {  use_ok( Bio::KBase::AuthDirectory); }

ok( $ad = new Bio::KBase::AuthDirectory, "Instantiate Bio::KBase::AuthDirectory object");

ok( $user = $ad->lookup_user('sychan'), "Looking up user sychan in test database");

note( Dumper( $user));

ok( $x = $ad->lookup_consumer('key1'), "Looking up consumer key 'key1'");

note( Dumper( $x ));

ok( $x = $ad->lookup_oauth2_token('token1'), "Looking up token 'token1'" );
note( Dumper( $x));

ok( $x = $ad->lookup_oauth2_token('token6'), "Looking up token 'token6'");
note( Dumper( $x));

$user = new Bio::KBase::AuthUser;
note("USER is $user\n");
$user->user_id('sychan2');
$user->name('s chan again');
$user->email('sychan2@lbl.gov');

$ad->delete_user('sychan2');


ok( $newuser = $ad->create_user( $user), "Creating a new user sychan2");

if ($newuser) {
    note(Dumper( $newuser));
} else {
    note( sprintf "Error: %s", $ad->error_message);
}

$newuser->email('sychan2@whitehouse.gov');
if (ok($ad->update_user( $newuser), "Updating email field in database")) {
    note(Dumper( $newuser));
} else {
    note(sprintf "Error: %s\n", $ad->error_message);
}    
if ( ok($ad->enable_user('sychan2'), "Enabling the new user")) {
    $user= $ad->lookup_user('sychan2');
    ok($user->enabled() == 1, "Verifying user enabled in database");
} else {
    note( sprintf "Error: %s\n", $ad->error_message);
}

if ( ok( $ad->disable_user('sychan2'), "Disabling new user")) {
    $user= $ad->lookup_user('sychan2');
    ok( $user->enabled() == 0, "user lookup returns disabled user");
} else {
    note(sprintf "Error: %s\n", $ad->error_message);
}

ok( $key = $ad->new_consumer( "sychan2"), "Adding new consumer key");

if ($key) {
    note( sprintf "oauth_key:%s\noauth_secret:%s\n", $key->{oauth_key}, $key->{oauth_secret});
} else {
    note( sprintf "Error: %s\n", $ad->error_message);
}

if (ok( $ad->delete_consumer( $key->{oauth_key}), "Deleting consumer key ".$key->{oauth_key})) {
} else {
    note( sprintf "Error: %s\n", $ad->error_message);
}

if (ok($ad->delete_user('sychan2'), "Deleting user sychan2")) {
} else {
    note( sprintf "Error: %s\n", $ad->error_message);
}

done_testing();


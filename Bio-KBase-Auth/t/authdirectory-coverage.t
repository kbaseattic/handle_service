use Test::More tests => 162;

# Hammers on Bio::KBase::AuthDirectory, mainly
# Jim Thomason (thomason@cshl.edu)
# 5/15/12

use strict;
use warnings;

use lib '../lib';
use lib 'lib';
use Bio::KBase::AuthUser;
use Bio::KBase::AuthDirectory;
use Bio::KBase::AuthClient;
use Bio::KBase::Auth;
use Data::Dumper;

my $user_id  = 'testington_1_' . time;
my $user_id2 = 'testington_2_' . time;
my $user_id3 = 'testington_3_' . time;

my $user = Bio::KBase::AuthUser->new('user_id' => $user_id);
ok($user, "Can create user");

my $ad = Bio::KBase::AuthDirectory->new();
ok($ad, "Got AuthDirectory object");
my $ad2 = Bio::KBase::AuthDirectory->new();
ok($ad2, "Got second AuthDirectory object");

is($user->user_id, $user_id, "user_id is set to $user_id via constructor");
ok(! $ad->create_user($user), "Could not create user");
is($ad->error_message, 'These fields failed validation: email,name', "Expected error message");
is($user->user_id($user_id), $user_id, "explicitly set $user_id via method");
is($ad->create_user($user), undef, "Could not create user");
is($ad->error_message, 'These fields failed validation: email,name', "Expected error message");
is($user->email('testington'), 'testington', 'set email to something invalid');
is($ad->create_user($user), undef, "Could not create user");
is($ad->error_message, 'These fields failed validation: email,name', "Expected error message");
is($user->email('testington@-testington.com'), 'testington@-testington.com', 'set email to something invalid (testington@-testington.com)');
is($ad->create_user($user), undef, "Could not create user");
is($ad->error_message, 'These fields failed validation: email,name', "Expected error message");
is($user->email('testington@testington.com'), 'testington@testington.com', 'set email to something valid (testington@testington.com)');
is($ad->create_user($user), undef, "Could not create user");
is($ad->error_message, 'These fields failed validation: name', "Expected error message");
is($user->name('Bob Testington'), 'Bob Testington', 'Properly set name to Bob Testington');
ok($ad->create_user($user), "Successfully created user");
ok(! $ad->create_user($user), "Could not create user 2x");
is ($user->user_id, $user_id, "user_id is still $user_id");
is ($user->token, undef, "token is still undefined");
is ($user->error_message, undef, "error_message is still undefined");
is ($user->enabled, 0, "enabled is 0");
is ($user->last_login_time, undef, "last_login_time is still undefined");
is ($user->last_login_ip, undef, "last_login_ip is still undefined");
is ($user->roles, undef, "roles is still undefined");
is ($user->groups, undef, "groups is still undefined");
is (ref $user->oauth_creds, 'HASH', "oauth_creds is a hashref");
is (scalar keys %{$user->oauth_creds}, 0, "oauth_creds is empty");
is ($user->name, 'Bob Testington', "name is still Bob Testington");
is ($user->given_name, undef, "given_name is still undefined");
is ($user->family_name, undef, "family_name is still undefined");
is ($user->middle_name, undef, "middle_name is still undefined");
is ($user->nickname, undef, "nickname is still undefined");
is ($user->profile, undef, "profile is still undefined");
is ($user->picture, undef, "picture is still undefined");
is ($user->website, undef, "website is still undefined");
is ($user->email, 'testington@testington.com', 'email is still testington@testington.com');
is ($user->verified, 0, "verified is 0");
is ($user->gender, undef, "gender is still undefined");
is ($user->birthday, undef, "birthday is still undefined");
is ($user->zoneinfo, undef, "zoneinfo is still undefined");
is ($user->locale, undef, "locale is still undefined");
is ($user->phone_number, undef, "phone_number is still undefined");
is ($user->address, undef, "address is still undefined");
is ($user->updated_time, undef, "updated_time is still undefined");
is ($user->phone_number('800-555-1212'), '800-555-1212', 'set phone_number to 800-555-1212');
#open (F, ">~/Desktop/err.html");
#print F $ad->error_message;
#close F;
ok ($ad->update_user($user), "Successfully updated user");
is ($user->phone_number, '800-555-1212', 'phone number still 800-555-1212');
unless (isnt($user->user_id($user_id . '22'), $user_id . '22', "Forced update of user_id to ${user_id}22")) {
    ok (! $ad->update_user($user), "Changing user_id changes user");
}
is ($user->user_id($user_id), $user_id, "reset user_id back to $user_id");

my $user2 = Bio::KBase::AuthUser->new(
    'user_id' => $user_id2,
    'name'    => 'Fred Testington',
    'email'   => 'fred@testington.com'
);
ok($user2, 'created user2 object');
ok($ad->create_user($user2), "Successfully created user 2");

is ($user2->user_id($user_id), $user_id2, "Cannot change user_ids from user2 -> user1");
ok ($ad->update_user($user2), "Successfully updated user2, grafting into user1's user_id. Dammit.");
is ($user2->name, 'Fred Testington', "user2 is still Fred");
my $newUser1;
ok ($newUser1 = $ad->lookup_user($user_id), "Re-loaded user1");
is ($newUser1->name, $user->name, "user1 and newUser1 names match");

is ($user2->user_id($user_id2), $user_id2, 'turned user2 back into user2');

is ($ad->lookup_user, undef, "Could not lookup non-existent user id");

my $user3;
ok (! $ad->create_user('foobar'), 'Could not create user w/o KBase::AuthUser object');
is ($ad->error_message, "User object required parameter", "Proper error message");
ok (! $ad->update_user('foobar'), 'Could not update user w/o KBase::AuthUser object');
is ($ad->error_message, "User object required parameter", "Proper error message");

ok ($user3 = Bio::KBase::AuthUser->new(), "Created user3");
ok (! $ad->create_user($user3), "Could not create user w/o values");
is ($ad->error_message, "These fields failed validation: email,name,user_id", "Proper error message");
is ($user3->user_id($user_id3), $user_id3, "Set user3 to user_id3");
is ($user3->name('Scott Testington'), 'Scott Testington', "Set user3 name");
is ($user3->email('scott@testington.com'), 'scott@testington.com', "Set user3 email");
ok (! $ad->update_user($user3), "Cannot update user3 - does not exist");
is ($ad->error_message, "User does not exist", "Proper error message");
ok ($ad->create_user($user3), "Created user3");
is ($user3->email(undef), undef, "Wiped out user3 email address");
ok (! $ad->update_user($user3), "Could not create user w/o values");
is ($ad->error_message, "These fields failed validation: email", "Proper error message");
is ($user3->email('scott@testington.com'), 'scott@testington.com', "Set user3 email");
ok ($ad->update_user($user3), "Successfully updated user3");
is ($user3->email('foo@'), 'foo@', "user3 email address now invalid");
ok (! $ad->update_user($user3), "Could not create user w/invalid values");
is ($ad->error_message, "These fields failed validation: email", "Proper error message");
is ($user3->email('scott@testington.com'), 'scott@testington.com', "Set user3 email");

is ($user->enabled, 0, "User1 is not enabled");
ok ($ad->enable_user($user->user_id), "enabled User1");

ok ($newUser1 = $ad->lookup_user($user->user_id), "Re-loaded user1 to a copy");
is ($newUser1->enabled, 1, "Okay, it's really enabled on the server side");

ok ($ad->disable_user($user->user_id), "disabled User1");
is ($user->enabled, 0, "User1 is disabled");
ok ($newUser1 = $ad->lookup_user($user->user_id), "Re-loaded user1 to a copy");
is ($newUser1->enabled, 0, "Okay, it's really disabled on the server side");
is ($newUser1->enabled(1), 1, "explicitly set enabled and bypassed \$ad->enable_user");
ok ($ad->update_user($newUser1), "Updated newUser");
is ($newUser1->enabled, 1, "User was enabled via a backdoor");

ok (! $ad->new_consumer, "Could not create new_consumer w/o user_id");
is ($ad->error_message, "User not found", "Expected error message");

my $consumer1;
ok ($consumer1 = $ad->new_consumer($user->user_id), "Created consumer for user1");
ok (defined $consumer1->{'oauth_key'}, "oauth_key defined");
ok (defined $consumer1->{'oauth_secret'}, "oauth_secret defined");

my $consumer2;
ok ($consumer2 = $ad->new_consumer($user->user_id, $user->user_id.'K'), "Created consumer2 for user1");
is ($consumer2->{'oauth_key'}, $user->user_id.'K', "oauth_key as specified");
ok (defined $consumer2->{'oauth_secret'}, "oauth_secret defined");

my $consumer3;
ok ($consumer3 = $ad->new_consumer($user->user_id, $user->user_id.'K2', $user->user_id.'S'), "Created consumer3 for user1");
is ($consumer3->{'oauth_key'}, $user->user_id.'K2', "oauth_key as specified");
is ($consumer3->{'oauth_secret'}, $user->user_id.'S', "oauth_secret as specified");

my $consumer4;
ok (!($consumer4 = $ad->new_consumer($user->user_id, $user->user_id.'K')), "Could not create consumer with duplicate key");
ok($newUser1 = $ad->lookup_user($user_id), "Re-loaded user1");
ok(defined $newUser1->oauth_creds->{$user->user_id.'K'}, 'user1 has consumer2');

my $consumer5;
ok (!($consumer5 = $ad->new_consumer($user2->user_id, $user->user_id.'K')), "Could not duplicate consumer key from user1 -> user2");

ok($newUser1 = $ad->lookup_user($user_id), "Re-loaded user1");
ok(defined $newUser1->oauth_creds->{$user->user_id.'K'}, 'user1 still has consumer2');

my $newUser2;
ok($newUser2 = $ad->lookup_user($user_id2), "Re-loaded user2");
ok(! defined $newUser2->oauth_creds->{$user->user_id.'K'}, 'user2 did not acquire consumer2');

ok(! $ad->lookup_consumer(), "Cannot lookup consumer w/o key");
is($ad->error_message, "Must specify consumer key", "Expeted error message");

ok(! $ad->lookup_consumer($user->user_id . $user2->user_id), "Cannot lookup consumer w/invalid key");
is($ad->error_message, "Did not find consumer_key " . $user->user_id . $user2->user_id, "Expeted error message");

my $validationUser = Bio::KBase::AuthUser->new();
$validationUser->email('bob@testington.com');
$validationUser->user_id('foobar');
$validationUser->name('Ke$ha');
ok(! $ad->_validate_user($validationUser), "User names must be [_a-zA-Z'-. ] only (" . $validationUser->name .")");
$validationUser->name('Madonna');
ok($ad->_validate_user($validationUser), "User can have single word name (" . $validationUser->name .")");
$validationUser->name('Bob Testington');
ok($ad->_validate_user($validationUser), "User can have two word name (" . $validationUser->name .")");
$validationUser->name('Bob Adams Testington');
ok($ad->_validate_user($validationUser), "User can have three word name (" . $validationUser->name .")");
$validationUser->name('Jo Smith');
ok($ad->_validate_user($validationUser), "User can have two letter name name (" . $validationUser->name .")");
$validationUser->name('J. Smith');
ok($ad->_validate_user($validationUser), "User can have one letter name name with initial (" . $validationUser->name .")");
$validationUser->name('50 cent');
ok($ad->_validate_user($validationUser), "Users can have numbers in their names (" . $validationUser->name .")");
$validationUser->name('Harry S Truman');
ok($ad->_validate_user($validationUser), "User can have one letter name name w/o initial (" . $validationUser->name .")");
$validationUser->{'user_id'} = "a";
ok(! $ad->_validate_user($validationUser), "User ids cannot be 1 character (" . $validationUser->user_id .")");
$validationUser->{'user_id'} = 'ab';
ok(! $ad->_validate_user($validationUser), "User ids cannot be 2 characters (" . $validationUser->user_id .")");
$validationUser->{'user_id'} = 'abc$';
ok(! $ad->_validate_user($validationUser), "User must be [a-zA-Z0-9_] only (" . $validationUser->user_id .")");
$validationUser->{'user_id'} = 'abc';
ok($ad->_validate_user($validationUser), "User ids can be 3 characters (" . $validationUser->user_id .")");
$validationUser->email('foo@');
ok(! $ad->_validate_user($validationUser), "Invalid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('foo@bar');
ok(! $ad->_validate_user($validationUser), "Invalid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('foo@@bar.com');
ok(! $ad->_validate_user($validationUser), "Invalid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('foo@-bar.com');
ok(! $ad->_validate_user($validationUser), "Invalid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('foo@.bar.com');
ok(! $ad->_validate_user($validationUser), "Invalid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('foo@bar...com');
ok(! $ad->_validate_user($validationUser), "Invalid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('foo@bar.com');
ok($ad->_validate_user($validationUser), "Valid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('foo(This one has comments!)@bar.com');
ok($ad->_validate_user($validationUser), "Valid - Must have valid email address (" . $validationUser->email .")");
$validationUser->email('A fully qualified email<foo(This one has comments!)@bar.com>');
ok($ad->_validate_user($validationUser), "Valid - Must have valid email address (" . $validationUser->email .")");


my $cred;
my $ac = Bio::KBase::AuthClient->new('user' => $newUser1);
ok($ac, "Got AuthClient object");
ok(! $ac->login(consumer_key => $consumer2->{'oauth_key'},
                consumer_secret => $consumer1->{'oauth_secret'}),
   "Could not login with invalid credentials");
ok(!$ac->login( consumer_key => $consumer1->{'oauth_key'}), "Could not login without secret");
ok(! $ac->login, "Could not login without key");
ok($cred = $ac->login( consumer_key => $consumer1->{'oauth_key'},
	               consumer_secret => $consumer1->{'oauth_secret'}), 
   "Got login credential");
ok (! $ad->delete_user(), "Cannot delete_user w/o user");
is ($ad->error_message, "Cannot delete_user w/o user_id", "Expected error message");
ok (! $ad->enable_user(), "Cannot enable_user w/o user");
is ($ad->error_message, "Cannot enable_user w/o user_id", "Expected error message");
ok (! $ad->disable_user(), "Cannot disable_user w/o user");
is ($ad->error_message, "Cannot disable_user w/o user_id", "Expected error message");

#cleanup
ok($ad->delete_consumer($consumer1->{'oauth_key'}), "Successfully deleted consumer1");
ok($ad->delete_consumer($consumer2->{'oauth_key'}), "Successfully deleted consumer2");
ok($ad->delete_consumer($consumer3->{'oauth_key'}), "Successfully deleted consumer3");
ok(! $ad->delete_consumer($consumer4->{'oauth_key'}), "consumer4 should not exist and not be deleted");
ok(! $ad->delete_consumer($consumer5->{'oauth_key'}), "consumer5 should not exist and not be deleted");

ok($ad->delete_user($user->user_id), "Successfully deleted user");
ok(! $ad->delete_user($user->user_id), "Could not delete non-existent user");
ok($ad->delete_user($user2->user_id), "Successfully deleted user2");
ok($ad->delete_user($user3->user_id), "Successfully deleted user3");

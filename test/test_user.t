#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More 'no_plan';
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Request::Common qw(POST);
use HTML::Parser;
use JSON;
use String::Random;
use Data::Dumper;

my $json = new JSON;

my $HOST = "10.0.8.10";
   $HOST = "140.221.92.148";
my $PORT = "8000";
my $BASE_URL = "http://$HOST:$PORT";
my $MAX_ADMIN_TEST = 100;
my $MAX_USER_TEST = 100;
my $MAX_ID_LENGTH = 20;

die "Usage: test_user.t supersupersecret_password\n" if $#ARGV != 0;
my $supersupersecret = shift @ARGV;

#-------------------------------------------------------------------------
#	Create Admin User
#
#	Set up validation account
#
my $strrd = new String::Random;
my $admin = $strrd->randregex("[a-zA-Z]{5,20}");
my $apswd = $strrd->randregex("[a-zA-Z]{5,20}");
#my $admin = $strrd->randregex("[a-zA-Z]{5,$MAX_ID_LENGTH}");
#my $apswd = $strrd->randregex("[a-zA-Z]{5,$MAX_ID_LENGTH}");

my $ires  = `curl -X POST --user $admin:$apswd:$supersupersecret $BASE_URL/user`;
my $irhs  = $json->decode($ires); 


if(! defined $irhs->{E}) {
  is($irhs->{D}->{name}, $admin, "Check the returned user name");
  is($irhs->{D}->{admin}, 1, "Check the admin status");
} else {
  die "Skip the test due to admin account creation failure\n";
}

my $uuid = $irhs->{D}->{uuid};
$ires  = `curl -X GET --user $admin:$apswd $BASE_URL/user/$uuid`;
$irhs  = $json->decode($ires); 
is($irhs->{D}->{name}, $admin, "Check the returned user name");
is($irhs->{D}->{admin}, 1, "Check the admin status");
is($irhs->{D}->{uuid}, $uuid, "Check the returned uuid");


$ires  = `curl -X POST --user $admin:$apswd:$supersupersecret $BASE_URL/user`;
$irhs  = $json->decode($ires); 


is($irhs->{E}[0], "Username not available", "Duplicated user ID generation test");

$ires  = `curl -X GET --user $admin:$apswd $BASE_URL/user`;
$irhs  = $json->decode($ires); 

ok(! defined $irhs->{E}, "Get user list");

# collect existing user name list
my $uit = 0;
my @ul =  @{$irhs->{D}};
my %un2id = ();
my %id2un = ();
while ( $uit < $#ul) {
  my $hr = $ul[$uit];
  $un2id{$hr->{name}} = $hr->{uuid};
  $un2id{$hr->{uuid}} = $hr->{name};
  $uit = $uit + 1;
}

my $tst_it = 0;
while( $tst_it < $MAX_ADMIN_TEST) {
  my $ladm = $strrd->randregex('[a-zA-Z]{5,50}');
  my $lpwd = $strrd->randregex('[a-zA-Z]{5,50}');

  if(defined $un2id{$ladm}) {
    $ires  = `curl -X GET --user $ladm:$lpwd:$supersupersecret $BASE_URL/user/$un2id{$ladm}`;
    $irhs  = $json->decode($ires); 
    
    is($irhs->{D}->{name}, $ladm, "Check the returned user name");
  } else {
    $ires  = `curl -X POST --user $ladm:$lpwd $BASE_URL/user`;
    $irhs  = $json->decode($ires); 

    ok(! defined $irhs->{E}, "Creating admin account");
    is($irhs->{D}->{name}, $ladm, "Check the returned user name");
    is($irhs->{D}->{admin}, 1, "Check the admin status");

    $uuid = $irhs->{D}->{uuid};

    # storing for the remaining test
    if(defined $uuid) {
      $un2id{$irhs->{D}->{name}} = $uuid;
      $un2id{$uuid} = $irhs->{D}->{name};
    }
    
    $ires  = `curl -X GET --user $ladm:$lpwd $BASE_URL/user/$uuid`;
    $irhs  = $json->decode($ires); 
    is($irhs->{D}->{name}, $ladm, "Check the returned user name");
    is($irhs->{D}->{admin}, 1, "Check the admin status");
    is($irhs->{D}->{uuid}, $uuid, "Check the uuid");

    $ires  = `curl -X POST --user $ladm:$lpwd:$supersupersecret $BASE_URL/user`;
    $irhs  = $json->decode($ires); 

    is($irhs->{E}[0], "Username not available", "Duplicated user ID generation test");
  }

  $tst_it = $tst_it + 1;
}

$tst_it = 0;
while( $tst_it < $MAX_USER_TEST) {
  my $ladm = $strrd->randregex('[a-zA-Z]{5,50}');
  my $lpwd = $strrd->randregex('[a-zA-Z]{5,50}');

  if(defined $un2id{$ladm}) {
    $ires  = `curl -X GET --user $admin:$apswd $BASE_URL/user/$un2id{$ladm}`;
    $irhs  = $json->decode($ires); 
    
    is($irhs->{D}->{name}, $ladm, "Check the returned user name");
    is($irhs->{D}->{uuid}, $un2id{$ladm}, "Check the returned user name");
  } else {

    # creating normal user
    $ires  = `curl -X POST --user $ladm:$lpwd $BASE_URL/user`;
    $irhs  = $json->decode($ires); 

    ok(! defined $irhs->{E}, "Creating an account");
    is($irhs->{D}->{name}, $ladm, "Check the returned user name");
    is($irhs->{D}->{admin}, 0, "Check the admin status");

    $uuid = $irhs->{D}->{uuid};

    # storing for the remaining test
    if(defined $uuid) {
      $un2id{$irhs->{D}->{name}} = $uuid;
      $un2id{$uuid} = $irhs->{D}->{name};
    }

    # get user info from uuid
    $ires  = `curl -X GET --user $admin:$apswd $BASE_URL/user/$uuid`;
    $irhs  = $json->decode($ires); 
    is($irhs->{D}->{name}, $ladm, "Check the returned user name");
    is($irhs->{D}->{admin}, 0, "Check the admin status");
    is($irhs->{D}->{uuid}, $uuid, "Check the uuid");

    # duplicated username generation as admin
    $ires  = `curl -X POST --user $ladm:$lpwd:$supersupersecret $BASE_URL/user`;
    $irhs  = $json->decode($ires); 

    is($irhs->{E}[0], "Username not available", "Duplicated user ID generation test(admin)");

    # duplicated username generation as regular user
    $ires  = `curl -X POST --user $ladm:$lpwd $BASE_URL/user`;
    $irhs  = $json->decode($ires); 

    is($irhs->{E}[0], "Username not available", "Duplicated user ID generation test(regular)");
  }


  $tst_it = $tst_it + 1;
}

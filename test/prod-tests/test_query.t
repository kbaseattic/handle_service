#!/usr/bin/perl -w

# Tests the general node IO methods associated with the Shock API.
# Make sure the $HOST and $PORT variables are set to a running Shock server
# before running any tests.
#
# The following API methods are tested by this module:
# GET /node
# POST /node
#
# As the /user commands aren't being tested, this assumes the presence of 
# a valid user (see $USER and $PW variables), though it tests invalid users
# and passwords.

use strict;
use lib "lib";
use lib "test/prod-tests";

use Test::More 'no_plan';
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Request::Common qw(POST GET);
use HTML::Parser;
use JSON;
use Data::Dumper;
use AuxTestConfig qw(getHost getPort getURL);

my $json = new JSON;

#my $HOST = "10.0.8.221";
#my $PORT = "7044";
#my $BASE_URL = "http://$HOST:$PORT";
#my $URI = "$BASE_URL/node";

# MAKE A CONNECTION (DETERMINE THE URL TO USE BASED ON THE CONFIG MODULE)
my $host=getHost(); my $port=getPort();  my $URI=getURL()."/node";
print "-> attempting to connect to:'".$URI."'\n";

my $USER = 'kbasetest';
my $PW = '@Suite525';

my $response;
my $response_hash;

# All responses should have the JSON format:
# { 
#   "D" : {<data>},
#   "E" : <error message or null>
#   "S" : <http status of response (also in headers)>
# }
# If the passed decoded hash has these fields, then this method returns ok();
sub check_node_response_format {
	my $response = shift;
	print "Checking node response format...\n";
	ok( exists( $response->{'D'} ), "Does a 'D' field exist in the /node response?" );
	ok( exists( $response->{'E'} ), "Does an 'E' field exist in the /node response?" );
	ok( exists( $response->{'S'} ), "Does an 'S' field exist in the /node response?" );
	like( $response->{'S'}, qr/^\d{3}$/, "Is 'S' a 3-digit number (HTTP status)?" );
	print "Done!\n";
}

# All nodes should have the JSON format:
# {
#   "id" : "unique_id",
#   "file" : {
#          "name" : "filename",
#          "size" : numerical_size,
#          "checksum" : {
#                 "md5" : "md5_hash",
#                 "sha1" : "sha1_hash"
#          }
#   },
#   "acl" : {
#          "read" : [ "list", "of", "user", "ids" ],
#          "write" : [ "list of user ids" ],
#          "delete" : [ "list of user ids" ]
#   },
#   "attributes" : {
#          "arbitrary" : "json"
#   },
#   "indexes" : {
#   },
#   "version" : "version_string",
#   "version_parts" : {
#          "acl_ver" : "version_string",
#          "attributes_ver" : "version_string",
#          "file_ver" : "version_string",
#   }
# }
#
#{
#   "S" : 200,
#   "D" : [
#      {
#         "version" : "1c6f9c4b03bb0fc4a74c47623d79340d",
#         "file" : {
#            "checksum" : {
#               "sha1" : "5905b9a3a343daf06c6b47d3151315b229d45df8",
#               "md5" : "8c10d21f26ecb37dbb4024d1e64ae7af"
#            },
#            "format" : "",
#            "name" : "protein.faa",
#            "virtual_parts" : [],
#            "virtual" : false,
#            "size" : 1168026
#         },
#         "id" : "d34a605c-f406-4cd2-8c81-0aaf7e0a48c1",
#         "attributes" : {
#            "source" : "ftp://no_such_url.anl.gov/no_such_file",
#            "file_list" : "test1.rev.1.txt",
#            "fake_id" : 75,
#            "file_name" : "No_name_known",
#            "description" : "File created for testing"
#         },
#         "indexes" : {}
#      }
#   ],
#   "E" : null
#}
#
#
#
# Note that if no file is loaded (i.e. just a POST /node with no other info)
# then the file:checksum hash will be empty.
#
# If the passed decoded hash has this structure, then this method returns ok();
sub check_node_format {
	my $node = shift;

#	plan tests => 36;
	print "Checking node format...\n";
	
	ok( exists( $node->{'id'} ), "Does the node have an 'id' field?" );
	ok( ref($node->{'id'}) eq "" && length($node->{'id'}) > 0, "Does the 'id' field consist of a non-empty string?" );
	
	ok( exists( $node->{'attributes'} ), "Does the node have an 'attributes' field?" );
	ok( !defined($node->{'attributes'}) || ref($node->('attributes')) eq 'HASH', "Is the 'attributes' field either a hash or undef?");
	
	
	ok( exists($node->{'file'}), "Is there a 'file' field?" );
	ok( ref($node->{'file'}) eq 'HASH', "Is the 'file' field a hash?" );
	ok( exists($node->{'file'}->{'name'}), "Does the 'file' have a 'name' field?" );
	ok( ref($node->{'file'}->{'name'}) eq '', "Is the name a scalar?" );
	ok( exists($node->{'file'}->{'size'}), "Does the 'file' have a 'size' field?" );
	like( $node->{'file'}->{'size'}, qr/^\d+$/, "Is the size numeric?" );
	ok( exists($node->{'file'}->{'checksum'}), "Does the 'file' have a 'checksum' field?" );
	ok( ref($node->{'file'}->{'checksum'}) eq 'HASH', "Is the 'checksum' a hash?" );
	
	SKIP: {
		skip "No file in node: ignoring checksum test", 4 if length($node->{'file'}->{'name'}) == 0;
		ok( exists($node->{'file'}->{'checksum'}->{'md5'}), "Does the 'checksum' have an 'md5' field?" );
		ok( length($node->{'file'}->{'checksum'}->{'md5'}) > 0, "Is the 'md5' a non-empty string?");
		ok( exists($node->{'file'}->{'checksum'}->{'sha1'}), "Does the 'checksum' have an 'sha1' field?" );
		ok( length($node->{'file'}->{'checksum'}->{'sha1'}) > 0, "Is the 'sha1' a non-empty string?");
	}
	
	ok( exists($node->{'version'}), "Does the node have a 'version' field?" );
	ok( length($node->{'version'}), "Does the version contain a non-empty string?" );
	
	ok( exists($node->{'indexes'}), "Does the node have an 'indexes' field?" );
	ok( ref($node->{'indexes'}) eq 'HASH', "Is the 'indexes' field a hash?" );
print "Done!\n";
}


my $browser = LWP::UserAgent->new;
my $req;

# Test 4: POST /node -F "attributes=@<path_to_json>"
# Test with a valid JSON file of attributes

use String::Random;
my $strrd = new String::Random;
my $NUM_TAG = 30;
my $NUM_VAL = 50;
my $NUM_ATR = 1;
my %tags = ();
my %vals = ();

while (scalar keys %tags < $NUM_TAG) {
  $tags{(time()).'-'.$strrd->randregex("[a-zA-Z]{5,500}")} = ();
}
while (scalar keys %vals < $NUM_VAL) {
  $vals{'vvvvvvvvvvvvvvvvv-'.$strrd->randregex("[a-zA-Z]{5,500}")} = 1;
}

my @taga = keys %tags;
my @vala = keys %vals;

my %tagval2ait = ();
my %ait2nid = ();
my %nid2ait = ();


# attributed node creation testing
my @al = ();
my $ait = 0;
while( $ait < $NUM_ATR) {
  my $ntags = int(rand($NUM_TAG - 1)) + 1; # at least one
  my %hs = ();

  while (scalar keys %hs < $ntags) {
    my $tag = $taga[int(rand($NUM_TAG))];
    next if( defined $hs{$tag});
    my $val = $vala[int(rand($NUM_VAL))];
    $hs{$tag} = $val;
    $tagval2ait{"$tag:$val"} = [] if(! defined $tagval2ait{"$tag:$val"});
    push @{$tagval2ait{"$tag:$val"}}, $ait;
  }
  push @al, \%hs;
  
  my $json_text = to_json(\%hs, {utf8 => 1, pretty => 1});
  $json_text =~ s/\n//g;
  `echo  '$json_text' > att-$$.json;`;
  my $res = `curl --user '$USER:$PW' -s -X POST -F \"attributes=\@att-$$.json\" $URI`;
  my $rh =  from_json($res);
  ok(! defined $rh->{E}, "Creating a document with the attributes (err_msg)");
  is($rh->{S}, 200, "Creating a document with the attributes (status)");
  is_deeply($rh->{D}->{attributes}, \%hs, "Creating a document with the attributes (attributes)");
  `rm att-$$.json`;
  $ait2nid{$ait} = $rh->{D}->{id};
  $nid2ait{$rh->{D}->{id}} = $ait;
  $ait = $ait + 1;
}

# Query test
foreach my $tagval (keys %tagval2ait) {
  my @tv = split/:/,$tagval;

  # Correct query test
  my $res = `curl --user '$USER:$PW' -s -X GET '$URI/?query&$tv[0]=$tv[1]'`;
  my $rh =  from_json($res);


  my %nidhs = ();
  my @nl =  @{$tagval2ait{$tagval}};
  foreach my $ait ( @nl  ) {
      $nidhs{$ait2nid{$ait}} = 1;
  }

  # check return status

  # check query contents
  foreach my $hr (@{$rh->{D}}) {
    is($nidhs{$hr->{id}}, 1, "Query result correctness test");
    is_deeply($hr->{attributes}, $al[$nid2ait{$hr->{id}}], "Query result's attribute should be matched");
  }
  is($#{$rh->{D}}, $#nl, "The number of query results correctness");


  # Wrong query tag test
  $res = `curl --user '$USER:$PW' -s -X GET '$URI/?query&ttt$tv[0]=$tv[1]'`;
  $rh =  from_json($res);
  # check return status

  # check query result contents
  is($#{$rh->{D}}, -1, "The number of query results correctness for wrong tag");



  # Wrong query value  test
  $res = `curl --user '$USER:$PW' -s -X GET '$URI/?query&$tv[0]=tttttttttttttttttt$tv[1]'`;
  $rh =  from_json($res);
  # check return status

  # check query result contents
  is($#{$rh->{D}}, -1, "The number of query results correctness for wrong valued query");


  # With username & password 
  $res = `curl -s -X GET --user '$USER:$PW' '$URI/?query&$tv[0]=$tv[1]'`;
  $rh =  from_json($res);
  foreach my $hr (@{$rh->{D}}) {
    is($nidhs{$hr->{id}}, 1, "Query result correctness test with username");
    is_deeply($hr->{attributes}, $al[$nid2ait{$hr->{id}}], "Query result's attribute should be matched with username");
  }
  is($#{$rh->{D}}, $#nl, "The number of query results correctness with username");
}


# Test 6: POST /node --user user:password -F "attributes=@<path_to_json>"
# Test with user and valid JSON file

#reset previous datastructures
%tags = ();
%vals = ();

while (scalar keys %tags < $NUM_TAG) {
  $tags{(time()).'-'.$strrd->randregex("[a-zA-Z]{5,500}")} = ();
}
while (scalar keys %vals < $NUM_VAL) {
  $vals{'vvvvvvvvvvvvvvvvv-'.$strrd->randregex("[a-zA-Z]{5,500}")} = 1;
}

@taga = keys %tags;
@vala = keys %vals;

%tagval2ait = ();
%ait2nid = ();
%nid2ait = ();

# attributed node creation testing
@al = ();
$ait = 0;
while( $ait < $NUM_ATR) {
  my $ntags = int(rand($NUM_TAG - 1)) + 1; # at least one
  my %hs = ();

  while (scalar keys %hs < $ntags) {
    my $tag = $taga[int(rand($NUM_TAG))];
    next if( defined $hs{$tag});
    my $val = $vala[int(rand($NUM_VAL))];
    $hs{$tag} = $val;
    $tagval2ait{"$tag:$val"} = [] if(! defined $tagval2ait{"$tag:$val"});
    push @{$tagval2ait{"$tag:$val"}}, $ait;
  }
  push @al, \%hs;
  
  my $json_text = to_json(\%hs, {utf8 => 1, pretty => 1});
  $json_text =~ s/\n//g;
  `echo  '$json_text' > att-$$.json;`;
  my $res = `curl -s -X POST --user '$USER:$PW' -F \"attributes=\@att-$$.json\" $URI`;
  my $rh =  from_json($res);
  ok(! defined $rh->{E}, "Creating a document with the attributes (err_msg, username & passwd)");
  is($rh->{S}, 200, "Creating a document with the attributes (status, username & passwd)");
  is_deeply($rh->{D}->{attributes}, \%hs, "Creating a document with the attributes (attributes, username & passwd)");
  `rm att-$$.json`;
  $ait2nid{$ait} = $rh->{D}->{id};
  $nid2ait{$rh->{D}->{id}} = $ait;
  $ait = $ait + 1;
}

# Query test
foreach my $tagval (keys %tagval2ait) {
  my @tv = split/:/,$tagval;

  # Correct query test
  my $res = `curl -s -X GET --user '$USER:$PW' '$URI/?query&$tv[0]=$tv[1]'`;
  my $rh =  from_json($res);


  my %nidhs = ();
  my @nl =  @{$tagval2ait{$tagval}};
  foreach my $ait ( @nl  ) {
      $nidhs{$ait2nid{$ait}} = 1;
  }

  # check return status

  # check query contents
  foreach my $hr (@{$rh->{D}}) {
    is($nidhs{$hr->{id}}, 1, "Query result correctness test (id&passwd)");
    is_deeply($hr->{attributes}, $al[$nid2ait{$hr->{id}}], "Query result's attribute should be matched (id&passwd)") if defined $nid2ait{$hr->{id}};
  }
  is($#{$rh->{D}}, $#nl, "The number of query results correctness (id&passwd)");


  # Wrong query tag test
  $res = `curl -s -X GET --user '$USER:$PW' '$URI/?query&ttt$tv[0]=$tv[1]'`;
  $rh =  from_json($res);
  # check return status

  # check query result contents
  is($#{$rh->{D}}, -1, "The number of query results correctness for wrong tag (id&passwd)");



  # Wrong query value  test
  $res = `curl -s -X GET --user '$USER:$PW' '$URI/?query&$tv[0]=tttttttttttttttttt$tv[1]'`;
  $rh =  from_json($res);
  # check return status

  # check query result contents
  is($#{$rh->{D}}, -1, "The number of query results correctness for wrong valued query (id&passwd)");


  # without authentification
  $res = `curl -s -X GET '$URI/?query&$tv[0]=$tv[1]'`;
  $rh =  from_json($res);
  # check return status

  # check query result contents
  is($#{$rh->{D}}, -1, "The number of query results correctness without authentification");


  # with wrong password
  $res = `curl -s -X GET --user '$USER:kkkkkkkkk$PW' '$URI/?query&$tv[0]=$tv[1]'`;
  $rh =  from_json($res);
  # check return status
  isnt($rh->{E}[0], "", "Wrong password <- unauthorized error");
  is($rh->{S}, 500, "Wrong password <- unauthorized error");

  # check query result contents
  is($#{$rh->{D}}, -1, "The number of query results correctness without authentification");
}


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

use Test::More 'no_plan';
use Test::Deep;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Request::Common qw(POST GET);
use HTML::Parser;
use JSON;
use Data::Dumper;
use Digest::MD5;
use Digest::SHA1;

my $json = new JSON;

my $HOST = "140.221.92.148";
my $PORT = "8000";
my $BASE_URL = "http://$HOST:$PORT";
my $URI = "$BASE_URL/node";
my $USER = "test";
my $PW = "test";
my $UID = "f34dc877005b84b939cfa69eda2ca90c";
my $FILE = "protein.faa";
my $ATTRIBUTES_FILE = "attributes.json";

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
# Note that if no file is loaded (i.e. just a POST /node with no other info)
# then the file:checksum hash will be empty.
#
# If the passed decoded hash has this structure, then this method returns ok();
sub check_node_format {
	my $node = shift;

#	plan tests => 36;
	print "Checking node format...\n";
	#print Dumper($node);	
	ok( exists( $node->{'id'} ), "Does the node have an 'id' field?" );
	ok( ref($node->{'id'}) eq "" && length($node->{'id'}) > 0, "Does the 'id' field consist of a non-empty string?" );
	
	ok( exists( $node->{'attributes'} ), "Does the node have an 'attributes' field?" );
	ok( (!defined($node->{'attributes'}) || (ref($node->{'attributes'}) eq 'HASH')), "Is the 'attributes' field either a hash or undef?");
	
	ok( exists($node->{'acl'}), "Does the node have an 'acl' field?" );
	ok( ref($node->{'acl'}) eq 'HASH', "Is the 'acl' field a hash?" );
	ok( exists($node->{'acl'}->{'read'}), "Does the 'acl' field have a 'read' field?" );
	ok( ref($node->{'acl'}->{'read'}) eq 'ARRAY', "Is the 'read' field an array?" );
	ok( exists($node->{'acl'}->{'write'}), "Does the 'acl' field have a 'write' field?" );
	ok( ref($node->{'acl'}->{'write'}) eq 'ARRAY', "Is the 'write' field an array?" );
	ok( exists($node->{'acl'}->{'delete'}), "Does the 'acl' field have a 'delete' field?" );
	ok( ref($node->{'acl'}->{'delete'}) eq 'ARRAY', "Is the 'delete' field an array?" );
	
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
	
	ok( exists($node->{'version_parts'}), "Does the node have a 'verison_parts' field?" );
	ok( ref($node->{'version_parts'}) eq 'HASH', "Is the 'version_parts' field a hash?" );
	ok( exists($node->{'version_parts'}->{'acl_ver'}), "Does the 'version_parts' have an 'acl_ver' field?" );
	ok( length($node->{'version_parts'}->{'acl_ver'}) > 0, "Is the 'acl_ver' a non-empty string?" );
	ok( exists($node->{'version_parts'}->{'attributes_ver'}), "Does the 'version_parts' have an 'attributes_ver' field?" );
	ok( length($node->{'version_parts'}->{'attributes_ver'}) > 0, "Is the 'attribtes_ver' a non-empty string?" );
	ok( exists($node->{'version_parts'}->{'file_ver'}), "Does the 'version_parts' have a 'file_ver' field?" );
	ok( length($node->{'version_parts'}->{'file_ver'}) > 0, "Is the 'file_ver' a non-empty string?" );
print "Done!\n";
}

sub check_node_user {
	my $uid = shift;
	my $acl = shift;
	print "Checking node user ACL...\n";
	my @priv = qw(read write delete);
	foreach my $p (@priv) {
		ok((grep { $_ eq $uid } @{ $acl->{$p} }), "Does the user have $p privileges?");
	}
	print "Done!\n";
}

sub calculate_file_md5 {
	my $file = shift;
	open FH, $file or return 0;
	binmode(FH);
	my $digest = Digest::MD5->new->addfile(*FH)->hexdigest;
	close FH;
	return $digest;
}

sub calculate_file_sha1 {
	my $file = shift;
	open FH, $file or return 0;
	binmode(FH);
	my $digest = Digest::SHA1->new->addfile(*FH)->hexdigest;
	close FH;
	return $digest;
}

sub check_node_file {
	my $file = shift;
	my $node_file = shift;
	print "Checking node file info...\n";
	ok( $node_file->{'name'} eq $file, "Was file name '$file' correctly returned?" );
	ok( $node_file->{'size'} == -s $file, "Was the correct file size returned?" );
	my $md5 = calculate_file_md5($file);
	SKIP: {
		skip "Unable to calculate md5 for local file: ignoring md5 checksum test", 1 if ($md5 eq 0);
		ok( $node_file->{'checksum'}->{'md5'} eq $md5, "Was the md5 hash correctly returned?" );
	}

	my $sha1 = calculate_file_sha1($file);
	SKIP: {
		skip "Unable to calculate sha1 hash for local file: ignoring sha1 checksum test", 1 if ($sha1 eq 0);
		ok( $node_file->{'checksum'}->{'sha1'} eq $sha1, "Was the sha1 hash correctly returned?" );
	}
	print "Done!\n";
}

sub test_file_upload {

	my ($uri, $file) = @_;
	
	print "Testing POST -F 'file=@<path_to_file>'  http://shock_ip:host/node ...\n";

	my $response = `curl -s -X POST -F "file=\@$file" $uri`;
	my $response_hash = $json->decode($response);
	ok($response_hash->{'S'} == 200, 'Successfully POSTed /node with file\n');

	subtest 'Checking response format' => sub {
        	check_node_response_format($response_hash);
	};

	subtest 'Checking node format' => sub {
        	check_node_format($response_hash->{'D'});
	};

	subtest 'Checking file information' => sub {
        	check_node_file($file, $response_hash->{'D'}->{'file'});
	};

}

sub test_get_all_nodes {
	my $uri = shift;
	my $response = `curl -s -X GET $uri`;

	my $response_hash = $json->decode( $response );
	ok( $response_hash->{'S'} == 200, "Did GET /node get submitted successfully?");

	subtest 'Checking response format' => sub {
		check_node_response_format($response_hash);
	};

	ok (ref($response_hash->{'D'}) eq 'ARRAY', "Does the GET /node 'D' field consist of an array?");
	if (exists($response_hash->{'D'}) && ref($response_hash->{'D'}) eq 'ARRAY') {
		foreach my $node (@{ $response_hash->{'D'} }) {
			subtest 'Checking node' => sub {
				check_node_format($node);
			};
		}
	}
}

sub test_post_empty_node {
	my $uri = shift;
	my $response = `curl -s -X POST $uri`;

	
	my $response_hash = $json->decode( $response );
	ok( $response_hash->{'S'} == 200, "Did POST /node get submitted successfully?" );

	subtest 'Checking response format' => sub {
        	check_node_response_format($response_hash);
	};

	subtest 'Checking node format' => sub {
        	check_node_format($response_hash->{'D'});
	};
}

sub test_post_empty_user_node {
	my $uri = shift;
	my $user = shift;
	my $pw = shift;
	my $uid = shift;

	my $response = `curl -s -X POST --user $user:$pw $uri`;

	my $response_hash = $json->decode($response);
	ok($response_hash->{'S'} == 200, 'Successfully POSTed /node with user name');
	subtest 'Checking response format' => sub {
	        check_node_response_format($response_hash);
	};

	subtest 'Checking node format' => sub {
	        check_node_format($response_hash->{'D'});
	};
	
	subtest 'Checking node user acl info' => sub {
	        check_node_user($uid, $response_hash->{'D'}->{'acl'});
	};
}

sub test_user_file_upload {
	my ($uri, $file, $user, $pw, $uid) = @_;
	my $response = `curl -s -X POST --user $user:$pw -F "file=\@$file" $uri`;
	my $response_hash = $json->decode($response);

	ok($response_hash->{'S'} == 200, 'Successfully POSTed /node with user name and file');
	subtest 'Checking response format' => sub {
		check_node_response_format($response_hash);
	};
	
	subtest 'Checking node format' => sub {
		check_node_format($response_hash->{'D'});
	};

	subtest 'Checking node user acl info' => sub {
		check_node_user($uid, $response_hash->{'D'}->{'acl'});
	};

        subtest 'Checking file information' => sub {
                check_node_file($file, $response_hash->{'D'}->{'file'});
        };
}

sub check_node_attributes {
	my $attribute_file = shift;
	my $node_attributes = shift;

	open FH, $attribute_file;
	my @lines = <FH>;
	my $atts_file = join('', @lines);
	my $file_json = $json->decode($atts_file);
	cmp_deeply($file_json, $node_attributes, "Is the attributes JSON returned correctly?");
	#is($atts_file, $json->encode($node_attributes), "Is the attributes JSON returned correctly?");
	
}

sub test_file_and_attributes_upload {
	my ($uri, $file, $atts_file) = @_;
	my $response = `curl -s -X POST -F "file=\@$file" -F "attributes=\@$atts_file" $uri`;
	my $response_hash = $json->decode($response);
	
	ok( $response_hash->{'S'} == 200, 'Successfully POSTed /node with file and attributes' );
        subtest 'Checking response format' => sub {
                check_node_response_format($response_hash);
        };

        subtest 'Checking node format' => sub {
                check_node_format($response_hash->{'D'});
        };

        subtest 'Checking file information' => sub {
                check_node_file($file, $response_hash->{'D'}->{'file'});
        };

        subtest 'Checking attributes information' => sub {
                check_node_attributes($atts_file, $response_hash->{'D'}->{'attributes'});
        };
}

sub test_user_file_attributes_upload {
	my ($uri, $file, $atts_file, $user, $pw, $uid) = @_;
	my $response = `curl -s -X POST --user $user:$pw -F "file=\@$file" -F "attributes=\@$atts_file" $uri`;
	my $response_hash = $json->decode($response);

	ok($response_hash->{'S'} == 200, 'Successfully POSTed /node with user name, file, and attributes');
	subtest 'Checking response format' => sub {
		check_node_response_format($response_hash);
	};

	subtest 'Checking node format' => sub {
		check_node_format($response_hash->{'D'});
	};

	subtest 'Checking node user acl info' => sub {
		check_node_user($uid, $response_hash->{'D'}->{'acl'});
	};

	subtest 'Checking file information' => sub {
		check_node_file($file, $response_hash->{'D'}->{'file'});
	};

	subtest 'Checking attributes information' => sub {
		check_node_attributes($atts_file, $response_hash->{'D'}->{'attributes'});
	};
}

# Test 1 : GET http://shock_ip:host/node
# Should return a list of well-formatted nodes in its "D" field.

subtest 'Testing GET http://shock_ip:host/node...\n' => sub {
	test_get_all_nodes($URI);
};


# "GOOD" data tests
# -----------------

# Test 2: POST http://shock_ip:host/node
# POST an empty node. Should return the new node.

subtest 'Testing POST http://shock_ip:host/node ...\n' => sub {
	test_post_empty_node($URI);
};

# Test 3: POST /node --user user:password
# Test post with a specific user.

subtest 'Testing POST --user user:password http://shock_ip:host/node ...\n' => sub {
	test_post_empty_user_node($URI, $USER, $PW, $UID);
};

# Test 4: POST /node -F "attributes=@<path_to_json>"
# Test with a valid JSON file of attributes

# See Shinjae's code.

# Test 5: POST /node -F "file=@<path_to_file>"
# Test with a valid file of random data

subtest 'Testing file upload...\n' => sub {
	test_file_upload($URI, $FILE);
};

# Test 6: POST /node --user user:password -F "attributes=@<path_to_json>"
# Test with user and valid JSON file

# See Shinjae's code.

# Test 7: POST /node --user user:password -F "file=@<path_to_file>"
# Test with user and valid random data file

print "Testing POST -F 'file=@<path_to_file>' --user user:password http://shock_ip:host/node ...\n";
subtest 'Testing user file upload...\n' => sub {
	test_user_file_upload($URI, $FILE, $USER, $PW, $UID);
};

# Test 8: POST /node -F "attributes=@<path_to_json>" -F "file=@<path_to_file>"
# Test with both a JSON and data file.

print "Testing POST -F 'file=@<path_to_file>' -F 'attributes=@<path_to_json>' http://shock_ip:host/node...\n";
subtest 'Testing file & attributes upload...\n' => sub {
	test_file_and_attributes_upload($URI, $FILE, $ATTRIBUTES_FILE);
};

# Test 9: POST /node --user user:password -F "file=@<path_to_file" -F "attributes=@<path_to_json>"
# Test with a user, JSON, and data file.

print "Testing POST --user user:password -F 'file=@<path_to_file>' -F 'attributes=@<path_to_json>' http://shock_ip:host/node...\n";
subtest 'Testing user file attributes upload...\n' => sub {
	test_user_file_attributes_upload($URI, $FILE, $ATTRIBUTES_FILE, $USER, $PW, $UID);
};

# "BAD" data tests
# ----------------

# Test 10: POST /node --user user:badpw
subtest 'Testing bad user password' => sub {
	my $response = `curl -s -X POST --user $USER:badpw $URI`;
	my $response_hash = $json->decode($response);

	ok($response_hash->{'S'} == 400, '400 error returned for a bad user password');
	check_node_response_format($response_hash);
};

# Test 11: Check malformed JSON uploaded as attributes.
subtest 'Testing upload of malformed JSON attributes file.' => sub {
	my $response = `curl -s -X POST -F "attributes=\@badatts.json" $URI`;
	my $response_hash = $json->decode($response);
	
	ok($response_hash->{'S'} == 400, '400 error returned for uploading a malformed attributes file');
	check_node_response_format($response_hash);
};


#!/usr/bin/env perl

use Module::Build;
Module::Build->new(
    module_name => 'Bio::KBase::Auth',
    license     => 'perl',
    requires => { 'Object::Tiny::RW' => 1.07,
		  'JSON' => 2.53,
		  'REST::Client' => 245,
		  'Digest::SHA' => 2.13,
		  'Digest::MD5' => 2.39,
		  'MIME::Base64' => 3.08,
		  'HTTP::Request' => 6.00,
		  'HTTP::Daemon' => 6.00,
		  'LWP::UserAgent' => 6.02,
		  'Net::OAuth' => 0.28,
		  'URI::Escape' => 1.60,
		  'Carp' => 1.17,
		  'Data::Dumper' => 2.1,
		  'Test::More' => 0.94,
		  'Storable' => 2.22,
		  'Test::Deep' => 0.109,
		  'Email::Valid' => 0.19,
    },
    dist_abstract => 'Classes to support OAuth based authentication for the Bio::KBase::* libraries',
    )->create_build_script;

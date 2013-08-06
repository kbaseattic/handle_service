#!/usr/bin/env perl

use Module::Build;
Module::Build->new(
    module_name => 'Bio::KBase::DataStore',
    license     => 'perl',
    requires => {'JSON' => 2.53,
        'LWP::UserAgent' => 6.02,
    },
    dist_abstract => 'Classes to support DataStore interface for the Bio::KBase::* libraries',
    )->create_build_script;
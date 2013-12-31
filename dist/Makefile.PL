use ExtUtils::MakeMaker;

WriteMakefile (
	NAME	=> 'Bio::Kbase::HandleService',
	# VERSION_FROM	=> 'lib/Bio/KBase/KIDL/KBT/KBT.pm',
	VERSION	=> '1.0',
	AUTHOR	=> 'Thomas Brettin',
	EXE_FILES	=> ['scripts/kbhs-upload.pl',
                            'scripts/kbhs-download.pl',
                            'scripts/kbhs-upload_metadata.pl',
                            'scripts/kbhs-download_metadata.pl',
                            'scripts/kbhs-list_handles.pl',
	],
	MIN_PERL_VERSION => '5.10.0',
	PREREQ_PM => {
		Getopt::Long		=> '0',
		LWP::UserAgent		=> '6.04',
		JSON::RPC::Client	=> '0.93',
		Exception::Class	=> '1.36',
		Config::Simple		=> '4.58',
		MongoDB			=> '0.503.3',
		Digest::SHA1		=> '2.13',
		Crypt::OpenSSL::RSA	=> '0.28',
		Convert::PEM		=> '0.08',
		Object::Tiny::RW	=> '1.07',
	},
	LICENSE	=> 'mit',
);

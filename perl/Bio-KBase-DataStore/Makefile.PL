use ExtUtils::MakeMaker;

WriteMakefile (
	NAME	=> 'Bio::Kbase::DataStore',
	VERSION	=> '0.0.1',
	AUTHOR	=> 'Jared Wilkening',
	EXE_FILES	=> [],
	MIN_PERL_VERSION => '5.10.0',
	PREREQ_PM => {
	    LWP::UserAgent  => '6.02',
        File::Basename  => '0',
        JSON            => '2.53',
	},
	LICENSE	=> 'mit',
);

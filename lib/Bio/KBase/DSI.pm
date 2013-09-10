package Bio::KBase::DSI;
use strict;
use Bio::KBase::DataStoreInterface::Client;
use LWP::UserAgent;
use JSON;
use Data::Dumper;



sub new {
	my $class = shift;
	bless {}, $class;
}

sub upload {
	my $self = shift;
	# implement here
}

sub download {
	my $self = shift;
	# implement here
}

sub new_handle {
	my $self = shift;
	Bio::KBase::DataStoreInterface::Client->new()->new_handle(@_);
}

sub locate {
	my $self = shift;
	Bio::KBase::DataStoreInterface::Client->new()->locate(@_);
}

sub initialize_handle {
	my $self = shift;
	Bio::KBase::DataStoreInterface::Client->new()->initialize_handle(@_);
}


1;

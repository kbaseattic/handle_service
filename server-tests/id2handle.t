use strict;
use Bio::KBase::AbstractHandle::AbstractHandleImpl;
use Test::More tests => 3;
use Data::Dumper;
use Test::Cmd;
use JSON;

my $hsi = Bio::KBase::AbstractHandle::AbstractHandleImpl->new();

ok( defined $hsi, "Check if the module is instanciated" );
my $nhd = $hsi->new_handle("Test");
ok( defined $nhd, "Check if the handle is instanciated" );
$nhd = $hsi->initialize_handle($nhd);

my $ahd = $hsi->ids_to_handles([$nhd->{id}]);
$ahd = $$ahd[0];
my $json = JSON->new();
$json = $json->canonical([]);

$ahd->{creation_date} = undef;
my %nhd = map { $_ => $nhd->{$_} } grep (defined $nhd->{$_}, sort keys %$nhd);
my %ahd = map { $_ => $ahd->{$_} } grep (defined $ahd->{$_}, sort keys %$ahd);
my $nhs = $json->encode(\%nhd);
my $ahs = $json->encode(\%ahd);

ok($nhs eq $ahs, "Check whether the same handle or not" );

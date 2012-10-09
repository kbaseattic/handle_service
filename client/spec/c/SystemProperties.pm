package SystemProperties;
use strict;

sub new {
  my $class = shift;
  my $self  = {};

  # lets try to open the properties file. first we will set it to something,
  # then we reassign $_[0] to it if $_[0] is defined and exists.
  # then we reassign $ENV{SYS_PROP_KB} to it if SYS_PROP_KB is defined and exists,

  my $properties_file = './sys.properties';
  $properties_file    = shift if (( defined $_[0] ) and ( -e $_[0] ));
  $properties_file    = $ENV{SYS_PROP_KB} if ((defined $ENV{SYS_PROP_KB}) and
                                               (-e $ENV{SYS_PROP_KB}));

  open FILE, $properties_file or die "couldn't open sys.properties $properties_file";
  while(<FILE>) {
    next if /^\s*\#/;
    next unless /\w/; 
    chomp;
    my ($key, $value) = split(/\s*=\s*/);
    if (defined $value and $value =~ /\S/) {
      $self->{$key} = $value;
    }
    else {
      $self->{$key} = undef;
    }
  }
  close FILE;
  bless $self, $class;
}

sub get {
  my $self = shift;

  if (exists $self->{$_[0]} and defined $self->{$_[0]}) {
    return $self->{$_[0]};
  }
  return;
}

sub identify {
  my $self = shift;
  my $user = shift;
  return "xxxxxxxxx";
}




1;

#!/kb/runtime/bin/perl

use strict;
use warnings;

use Config::IniFiles;

use Getopt::Long;

sub usage {
  print "setup.pl >>> set up a perl configuration file from an .ini file\n";
  print "setup.pl -input <path to .ini file> -output <path to output file>\n";
}

# get command line parameters
my %options = ();
GetOptions (\%options, 
	    "input=s",
	    "output=s" ); 


unless ($options{input} and $options{output}) {
  &usage();
  exit 0;
}

unless (-f $options{input}) {
  print "could not find input file\n";
  exit 0;
}

my $cfg = new Config::IniFiles( -file => $options{input} );

$options{output} =~ s/\.pm$//;
my $base;
(undef, $base) = $options{output} =~ /^(.+\/)?(.+)/;

if (open(FH, ">".$options{output}.".pm")) {
  my @params = $cfg->Parameters('base');
  @params = map { uc $_ } @params;

  print FH "package $base;\n\n";
  foreach my $param (@params) {
    print FH "use constant $param => '".$cfg->val('base', $param)."';\n";
  }
  print FH "\nour \@ISA = qw( Exporter );\n";
  print FH "our \@EXPORT = qw( ";
  print FH join(" ", @params);
  print FH " )";
  close FH;
} else {
  print "could not open output file for writing: $@\n";
  exit 0;  
}

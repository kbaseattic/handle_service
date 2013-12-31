This is a short introduction to using the kbase IDL compiler. At the time of this writing, the tutorial below is available on the web (and looks much better there) at: http://kbase.us/developer-zone/tutorials/developer-tutorials/my-first-service

Short Tutorial:

My First Service
Introduction

We will begin by defining a simple service that performs a very basic task: translate a string of DNA into the corresponding protein characters.

We assume here that you have either constructed a development container and have sourced its user-env file, or you are operating using a pre-built KBase deployment and have sourced its user-env file.
Creating and Compiling the Service Definition

To begin we need to define the interface to the service. It will ingest a string of DNA characters and emit a string of protein characters. We use the string type in the type language:

module MyFirstService {
    typedef string DNAString;
    typedef string ProteinString;
    funcdef translate_dna(DNAString dna) returns (ProteinString prot);
};

Create a file my_service.spec that contains the text above, and run the type compiler to generate output:

$ compile_typespec --psgi service.psgi my_service.spec my_service
my_service.spec: module MyFirstService service MyFirstService

This will generate the service code in the directory specified as the last argument:

$ ls my_service
MyFirstServiceClient.js MyFirstServiceClient.py MyFirstServiceServer.pm
MyFirstServiceClient.pm MyFirstServiceImpl.pm   service.psgi

Note that the files created are named using the module name defined in the interface document.

The files created include client libraries in Perl, Python, and Javascript (MyFirstServiceClient), a server interface library (MyFirstServiceServer), an implementation file (MyFirstServiceImpl), and a service startup program (service.psgi).
Starting the Service

At this stage we have a complete service, although it does not do anything useful. We can still start a server to host the service, however. For this we will use the plackup command that is part of the installed Perl runtime code in the KBase environment:

$ plackup --listen :9999 service.psgi
HTTP::Server::PSGI: Accepting connections at http://0:9999/

The --listen parameter defines the TCP port that the service will listen on. Don't forget to include the colon before the port number.
Invoking the Service

Now we need to invoke the service. The type compiler is able to generate command-line programs that invoke service routines that have scalar arguments. You can generate these by adding the --scripts flag to the compiler:

compile_typespec --scripts my_service --psgi service.psgi my_service.spec my_service

$ ls my_service
MyFirstServiceClient.js MyFirstServiceClient.py MyFirstServiceServer.pm simple_translate_dna.pl
MyFirstServiceClient.pm MyFirstServiceImpl.pm   service.psgi            translate_dna.pl

Note we have two new files, translate_dna.pl and simple_translate_dna.pl. Disregard translate_dna.pl for the moment - it is a skeleton for a CDM-style command line script that we won't further investigate. If you look at simple_translate_dna.pl you will find a script that expects to get a single parameter, a DNA string, and prints the JSON form of the output (this is currently quite crude but not in its final form):

$ cd my_service
$ perl simple_translate_dna.pl 
Usage: translate_dna [--port port] [--url url] dna

It also expects to receive an option that defines the location of the service it should use. This can take the form of either a full service URL or a port number. If you use a port number it expects to find the service on the local machine. We can try this now. Start the service using plackup as described above (it is useful to do this in a separate window), and then run the translation script:

$ perl simple_translate_dna.pl --port 9999 ccctag
[null]

Note that we don't receive a valid return. This makes sense, as we have not yet implemented the service.

In your window where plackup is running you will see a log of this request:

127.0.0.1 - - [12/Dec/2012:07:35:29 -0800] "POST / HTTP/1.1" 200 33 "-" "JSON::RPC::Client/0.93 beta libwww-perl/6.04"

Implementing the Service Functionality

We may now implement the service itself. Open MyFirstServiceImpl.pm in an editor. This module is invoked by the service handling code when a request for a service method is received. Each service method is represented by a function in the implementation file. You will find the translation routine to look something like this:

sub translate_dna
{
    my $self = shift;
    my($dna) = @_;

    my @_bad_arguments;
    (!ref($dna)) or push(@_bad_arguments, "Invalid type for argument \"dna\" (value was \"$dna\")");
    if (@_bad_arguments) {
        my $msg = "Invalid arguments passed to translate_dna:\n" . join("", map { "\t$_\n" } @_bad_arguments);
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                                               method_name => 'translate_dna');
    }

    my $ctx = $MyFirstServiceServer::CallContext;
    my($prot);
    #BEGIN translate_dna
    #END translate_dna
    my @_bad_returns;
    (!ref($prot)) or push(@_bad_returns, "Invalid type for return variable \"prot\" (value was \"$prot\")");
    if (@_bad_returns) {
        my $msg = "Invalid returns passed to translate_dna:\n" . join("", map { "\t$_\n" } @_bad_returns);
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                                               method_name => 'translate_dna');
    }
    return($prot);
}

There is a lot of boilerplate in there that you need not understand (it is type checking code). The key part is this pair of comments:

    #BEGIN translate_dna
    #END translate_dna

Your code will go in between the comments. Leave the comments in place - they are used by the type compiler to retain your code in the file when the compiler is rerun. The DNA option appears as the variable $dna. The return value will be placed into the variable $prot. These names are taken directly from the funcdef statement in your service specification file.

We will use a simple Perl translation module; the code for this is in the Appendix. Copy and paste the code from the appendix into a file called trans.pm and place that file in the my_service directory next to the other compiler-generated files.

Our implementation of the translation code itself is trivial:

    #BEGIN translate_dna
    $prot = translate($dna);
    #END translate_dna

However, we do need to include the translation module. Near the top of the implementation file you will find a pair of comments:

#BEGIN_HEADER
#END_HEADER

Code placed between these comments will be retained across compiles. Place a use statement for our translation utility module there:

#BEGIN_HEADER
use trans;
#END_HEADER

Kill (^C) and restart your plackup session so that it picks up the new implementation code. We may now test the service:

$ perl simple_translate_dna.pl --port 9999 ATGACAGCGCAAGAAAAACTCTACCAACTAATTCAAACTCTGCCAGAGA
["MTAQEKLYQLIQTLPE"]

We see that we have received a single item from the call, and it is a reasonable protein translation of that DNA string.
What Next?

    For a real production KBase service we would generate the code in a namespace under Bio::KBase somewhere, and we would place the files into the module directory according to the KBase coding standards. The type compiler would be invoked from the makefile using syntax like

SERVICE_NAME = MyFirstService
compile_typespec 
	-impl Bio::KBase::$(SERVICE_NAME)::Impl \
	-service Bio::KBase::$(SERVICE_NAME)::Service \
	-client Bio::KBase::$(SERVICE_NAME)::Client \
	-js $(SERVICE_NAME) \
	-py $(SERVICE_NAME) \
	my_service.spec lib

    We would include documentation in the service specification document, which would be propagated to the generated code.
    If we were implementing a service that we expected to be called many times with a large amount of data, we would define an interface where bulk requests were accepted. For instance, in the DNA translation service it might make sense to allow the translation of multiple strings of DNA in one call. The corresponding funcdef might look like this:
    funcdef translate_dna_strings(list<DNAString> dna_list) returns (list<ProteinString> prot_list)

Appendix: Simple Translation Module

sub translate {
    my($dna) = @_;
    my($i, $j, $ln);
    my($x, $y);
    my($prot);

    my $code = &standard_genetic_code();

    $ln = length($dna);
    $prot = "X" x ($ln/3);
    $dna =~ tr/a-z/A-Z/;

    for ($i=0,$j=0; ($i < ($ln-2)); $i += 3,$j++) {
        $x = substr($dna,$i,3);
        if ($y = $code->{$x}) {
            substr($prot,$j,1) = $y;
        }
    }

    if (($start) && ($ln >= 3) && (substr($dna,0,3) =~ /^[GT]TG$/)) {
        substr($prot,0,1) = 'M';
    }
    return $prot;
}
sub standard_genetic_code {

    my $code = {};

    $code->{"AAA"} = "K";
    $code->{"AAC"} = "N";
    $code->{"AAG"} = "K";
    $code->{"AAT"} = "N";
    $code->{"ACA"} = "T";
    $code->{"ACC"} = "T";
    $code->{"ACG"} = "T";
    $code->{"ACT"} = "T";
    $code->{"AGA"} = "R";
    $code->{"AGC"} = "S";
    $code->{"AGG"} = "R";
    $code->{"AGT"} = "S";
    $code->{"ATA"} = "I";
    $code->{"ATC"} = "I";
    $code->{"ATG"} = "M";
    $code->{"ATT"} = "I";
    $code->{"CAA"} = "Q";
    $code->{"CAC"} = "H";
    $code->{"CAG"} = "Q";
    $code->{"CAT"} = "H";
    $code->{"CCA"} = "P";
    $code->{"CCC"} = "P";
    $code->{"CCG"} = "P";
    $code->{"CCT"} = "P";
    $code->{"CGA"} = "R";
    $code->{"CGC"} = "R";
    $code->{"CGG"} = "R";
    $code->{"CGT"} = "R";
    $code->{"CTA"} = "L";
    $code->{"CTC"} = "L";
    $code->{"CTG"} = "L";
    $code->{"CTT"} = "L";
    $code->{"GAA"} = "E";
    $code->{"GAC"} = "D";
    $code->{"GAG"} = "E";
    $code->{"GAT"} = "D";
    $code->{"GCA"} = "A";
    $code->{"GCC"} = "A";
    $code->{"GCG"} = "A";
    $code->{"GCT"} = "A";
    $code->{"GGA"} = "G";
    $code->{"GGC"} = "G";
    $code->{"GGG"} = "G";
    $code->{"GGT"} = "G";
    $code->{"GTA"} = "V";
    $code->{"GTC"} = "V";
    $code->{"GTG"} = "V";
    $code->{"GTT"} = "V";
    $code->{"TAA"} = "*";
    $code->{"TAC"} = "Y";
    $code->{"TAG"} = "*";
    $code->{"TAT"} = "Y";
    $code->{"TCA"} = "S";
    $code->{"TCC"} = "S";
    $code->{"TCG"} = "S";
    $code->{"TCT"} = "S";
    $code->{"TGA"} = "*";
    $code->{"TGC"} = "C";
    $code->{"TGG"} = "W";
    $code->{"TGT"} = "C";
    $code->{"TTA"} = "L";
    $code->{"TTC"} = "F";
    $code->{"TTG"} = "L";
    $code->{"TTT"} = "F";

    return $code;
}
1;




Contributed by
Author: Robert Olson 

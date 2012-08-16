#!/kb/runtime/bin/perl
use warnings;
use strict;

use CGI;
use JSON;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use URI::Escape;

use Bio::KBase::AuthServer;

# config file for uploader variables
use UploaderConfig;

$Bio::KBase::Auth::AuthSvcHost = AUTH_SERVER_URL;

# initialize a cgi and json object
my $cgi = new CGI;
my $json = new JSON;
$json = $json->utf8();

# set this to 1 to disable authentication
my $no_auth = 0;

# demouser for authentication off mode
my $demouser = { user_id => "hmeier",
		 oauth_creds => { "demokey" => { oauth_secret => "geheim" } },
		 name => "Hans Meier" };

# check if we have a user set in the cookie
my $user;
my $cookie = $cgi->cookie( SESSION_COOKIE_NAME );
if ($cookie) {
  
  if ($no_auth) {
    $user = $demouser->{user_id};
  } else {
    my $as = new Bio::KBase::AuthServer;
    if ($as->validate_auth_header($cookie, request_method => "GET", request_url => AUTH_SERVER_URL )) {
      $user = $as->user->{user_id};
    }
  }
}

# set the file name endings that are valid upload files
# this should probably go into the config, not sure if this is 
# required at all in this use case
my $sub_ext = "fasta|faa|fa|ffn|frn|fna|fastq|fq|jpg|gz";

# get the REST parameters
my $rest = $cgi->url(-path_info=>1);
$rest =~ s/.*\/upload\.cgi\/(.*)/$1/;
my @rest = split m#/#, $rest;
map {$rest[$_] =~ s#forwardslash#/#gi} (0 .. $#rest);

# set the directory
my $udir = BASE_DIR."/".md5_hex($user);

# check if this is a request for the inbox or an upload
if (scalar(@rest)) {
    if ($rest[0] eq 'user_inbox') {

	# if there is no user, abort the request
	unless ($user) {
	    print "Content-Type: text/plain\n\n";
	    print "unauthorized request";
	    exit 0;
	}

	# check if the user directory exists
	&initialize_user_dir();
	
	# prepare return data structure
	my $data = { files => [], fileinfo => {}, messages => [], directories => [] };
	
	# check if we are supposed to do anything else than return the content of the inbox
	if ($cgi->param('faction')) {
	    my $action = $cgi->param('faction');
	    my @files = $cgi->param('fn');

	    # delete a list of files
	    if ($action eq 'del') {
		foreach my $file (@files) {
		    if (-f "$udir/$file") {		    
			`rm '$udir/$file'`;
			if (-f "$udir/$file.stats_info") {
			    `rm '$udir/$file.stats_info'`;
			}
			
			# check if the file is in a directory
			if ($file =~ /\//) {		      
			    my ($dn) = $file =~ /^(.*)\//;
			    $dn = $udir."/".$dn;

			    # if the directory is empty, delete it
			    my @fls = <$dn/*>;
			    if (! scalar(@fls)) {
				`rmdir $dn`;
			    }
			}
		    }
		}
	    }

	    #  move a list of files
	    if ($action eq 'move') {
		my $target_dir = shift(@files);
		if ($target_dir eq 'inbox') {
		    $target_dir = $udir."/";
		} else {
		    unless (-d "$udir/$target_dir") {
			`mkdir '$udir/$target_dir'`;
		    }
		    $target_dir = "$udir/$target_dir/";
		}
		foreach my $file (@files) {
		    `mv $udir/$file $target_dir`;
		    if (-f "$udir/$file.stats_info") {
			`mv $udir/$file.stats_info $target_dir`;
		    }
		}
	    }
	    
	    # decompress a list of files
	    if ($action eq 'unpack') {
		foreach my $file (@files) {
		    my @msg;
		    if (-f "$udir/$file") {
			if ($file =~ /\.(tar\.gz|tgz)$/) {
			    @msg = `tar -xzf '$udir/$file' -C $udir 2>&1`;
			} elsif ($file =~ /\.zip$/) {
			    @msg = `unzip -d $udir '$udir/$file' 2>&1`;
			} elsif ($file =~ /\.(tar\.bz2|tbz|tbz2|tb2)$/) {
			    @msg = `tar -xjf '$udir/$file' -C $udir 2>&1`;
			} elsif ($file =~ /\.gz$/) {
			    @msg = `gunzip -d '$udir/$file' 2>&1`;
			} elsif ($file =~ /\.bz2$/) {
			    @msg = `bunzip2 -d '$udir/$file' 2>&1`;
			}
			
			push(@{$data->{messages}}, join("<br>",@msg));
		    }
		}
	    }
	    
	    # convert a list of files from sff to fastq
	    if ($action eq 'convert') {
		foreach my $file (@files) {
		    if ($file =~ /\.sff$/) {
			if (-f "$udir/$file.fastq") {
			    push(@{$data->{messages}}, "The conversion for $file is either already finished or in progress.");
			} else {
			    my ($success, $message) = &extract_fastq_from_sff($file, $udir);
			    unless ($success) {
				push(@{$data->{messages}}, $message);
			    }
			}
		    } else {
			push(@{$data->{messages}}, "Unknown filetype for fastq conversion, currently only sff is supported.");
		    }
		}
	    }
	}
	
	# read the contents of the inbox
	my $info_files = {};
	my $submission_files = [];
	my $indir = {};
	my @ufiles;
	if (opendir(my $dh, $udir)) {
	    
	    # ignore . files and the USER file
	    @ufiles = grep { /^[^\.]/ && $_ ne "USER" } readdir($dh);
	    closedir $dh;
	    
	    # iterate over all entries in the user inbox directory
	    foreach my $ufile (@ufiles) {

		# check for sane filenames
		if ($ufile !~ /^[\/\w\.\-]+$/) {
		    my $newfilename = $ufile;
		    $newfilename =~ s/[^\/\w\.\-]+/_/g;
		    my $count = 1;
		    while (-f "$udir/$newfilename") {
			if ($count == 1) {
			    $newfilename =~ s/^(.*)(\..*)$/$1$count$2/;
			} else {
			    my $oldcount = $count - 1;
			    $newfilename =~ s/^(.*)$oldcount(\..*)$/$1$count$2/;
			}
			$count++;
		    }
		    `mv '$udir/$ufile' '$udir/$newfilename'`;
		    push(@{$data->{messages}}, "<br>The file <b>'$ufile'</b> contained invalid characters. It has been renamed to <b>'$newfilename'</b>.<br><b>WARNING</b> If this is a submission file with a mapping in your metadata, you will have to adjust the mapping in the metadata file!");
		    $ufile = $newfilename;
		}
		
		# check directories
		if (-d "$udir/$ufile") {
		    opendir(my $dh2, $udir."/".$ufile);
		    my @numfiles = grep { /^[^\.]/ && -f $udir."/".$ufile."/".$_ } readdir($dh2);
		    closedir $dh2;
		    if (scalar(@numfiles)) {
			push(@{$data->{directories}}, $ufile);
			my $dirseqs = [];
			foreach my $nf (@numfiles) {
			    unless ($nf =~ /\.stats_info$/) {
				push(@$dirseqs, $nf);
			    }
			    push(@ufiles, "$ufile/$nf");		
			}
			$data->{fileinfo}->{$ufile} = $dirseqs;
		    } else {
			`rmdir $udir/$ufile`;
		    }
		}
		# check files
		else {
		    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat("$udir/$ufile");
		    if ($size == 0) {
			`rm -f "$udir/$ufile"`;
			next;
		    }
		    if ($ufile =~ /\.($sub_ext)$/) {
			push(@$submission_files, $ufile);
		    }
		    if ($ufile =~ /^(.+)\.stats_info$/) {
			my $fn = $1;
			$info_files->{$fn} = 1;
			my $info = {};
			if (open(FH, "<$udir/$ufile")) {
			    while (<FH>) {
				chomp;
				my ($key, $val) = split /\t/;
				$key =~ s/_/ /g;
				$info->{$key} = $val;
			    }
			    close FH;
			}
			$data->{fileinfo}->{$fn} = $info;
		    } else {
			unless ($ufile =~ /\//) {
			    push(@{$data->{files}}, $ufile);
			}
		    }
		}
	    }
	}
	
	# iterate over all submission files found in the inbox
	foreach my $submission_file (@$submission_files) {

	    # create basic and extended file information if we do not yet have it
	    if (! $info_files->{$submission_file}) {
		my ($file_suffix) = $submission_file =~ /^.*\.(.+)$/;
		my $file_size = -s "$udir/$submission_file"; 
		my $info = { "suffix" => $file_suffix };
		
		open(FH, ">$udir/$submission_file.stats_info");
		print FH "suffix\t$file_suffix\n";
		close(FH);
		`chmod 666 $udir/$submission_file.stats_info`;
		
		$data->{fileinfo}->{$submission_file} = $info;
	    }
	}

	# add basic file information to all files
	foreach my $file (@ufiles) {
	    next unless (-f "$udir/$file");
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat("$udir/$file");
	    unless (exists($data->{fileinfo}->{$file})) {
		$data->{fileinfo}->{$file} = {};
	    }
	    $data->{fileinfo}->{$file}->{'creation date'} = &pretty_date($ctime);
	    $data->{fileinfo}->{$file}->{'file size'} = &pretty_size($size);
	}
	
	# sort the returned files lexigraphically
	@{$data->{files}} = sort { lc $a cmp lc $b } @{$data->{files}};
	
	# return the contents of the inbox
	print $cgi->header('application/json');
	print $json->encode( $data );
	exit 0;
    } elsif ($rest[0] eq 'spreadsheet') {
	if (open(FH, "<". METADATA_TEMPLATE_FILE ) ) {
	    my ($fn) = METADATA_TEMPLATE_FILE =~ /.*\/(.*)/;
	    print $cgi->header(-type => 'application/x-download',
			       -status => 200,
			       -Access_Control_Allow_Origin => '*',
			       -Content_Length => (stat( METADATA_TEMPLATE_FILE ))[7],
			       -Content_Disposition => "attachment;filename=$fn" );
	    while (<FH>) {
		print;
	    }
	    close FH;
	} else {
	    print $cgi->header(-type => 'text/plain',
			       -status => 400,
			       -Access_Control_Allow_Origin => '*' );
	    print "metadata spreadsheet not found: $! $@";
	}
	exit 0;
    } 
}

# if there is no user, abort the request
unless ($user) {
    print "Content-Type: text/plain\n\n";
    print "unauthorized request";
    exit 0;
}

# check if the user directory exists
&initialize_user_dir();

# If we get here, this is an actual upload
my $filename = $cgi->param('filename');
unless ($cgi->param('upload_file')) {
    print "Content-Type: text/plain\n\n";
    print "no upload file passed";
    exit 0;    
}
my $fh = $cgi->upload('upload_file')->handle;
my $bytesread;
my $buffer;

# check if this is the first block, if so, create the file
if (-f "$udir/".$filename && ! -f "$udir/$filename.part") {
    print "Content-Type: text/plain\n\n";
    print "file already exists";
    exit 0;
}
# otherwise, append to the file
else {
    if (open(FH, ">>$udir/".$filename)) {
	while ($bytesread = $fh->read($buffer,1024)) {
	    print FH $buffer;
	}
	close FH;
	`touch $udir/$filename.part`;
    }
}

# return a message to the sender
print "Content-Type: text/plain\n\n";

# if this is the last chunk, remove the partial file
if ($cgi->param('last_chunk')) {
    print "file received";
    `rm $udir/$filename.part`;
} else {
    print "chunk received";
}

exit 0;

############################
# start of methods section #
############################

# check if the user directory exists, if not create it
sub initialize_user_dir {
  unless ( -d $udir ) {
    mkdir $udir or die "could not create directory '$udir'";
    chmod 0777, $udir;
  }
  unless ( -d "$udir/.tmp") {
    mkdir "$udir/.tmp" or die "could not create directory '$udir/.tmp'";
    chmod 0777, "$udir/.temp";
  }
  my $user_file = "$udir/USER";
  if ( ! -e $user_file ) {	
    if (open(USER, ">$user_file")) {
      print USER $user."\n";
      close(USER) or die "could not close file '$user_file': $!";
      chmod 0666, $user_file;
    } else {
      die "could not open file '$user_file': $!";
    }
  }
}

##################
# Helper Methods #
##################

sub pretty_date {
    my ($date) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($date);
    $year += 1900;
    my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    $hour = $hour < 10 ? "0".$hour : $hour;
    $min = $min < 10 ? "0".$min : $min;
    $sec = $sec < 10 ? "0".$sec : $sec;
    $mday = $mday < 10 ? "0".$mday : $mday;

    my $pretty_date = "$year $abbr[$mon] $mday $hour:$min:$sec";

    return $pretty_date;
}

sub pretty_size {
    my ($size) = @_;
    my $magnitude = "B";
    if ($size > 1024) {
	$size = $size / 1024;
	$magnitude = "KB"
    }
    if ($size > 1024) {
	$size = $size / 1024;
	$magnitude = "MB";
    }
    if ($size > 1024) {
	$size = $size / 1024;
	$magnitude = "GB";
    }
    $size = sprintf("%.1f", $size);
    $size = &addCommas($size);
    $size = $size . " " . $magnitude;
    
    return $size;
}

sub addCommas {
    my ($nStr) = @_;
    $nStr .= '';
    my @x = split(/\./, $nStr);
    my $x1 = $x[0];
    my $x2 = scalar(@x) > 1 ? '.' . $x[1] : '';
    while ($x1 =~ /(\d+)(\d{3})/) {
	$x1 =~ s/(\d+)(\d{3})/$1,$2/;
    }
    return $x1 . $x2;
}

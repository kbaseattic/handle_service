use Dancer;
use JSON;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Conf;

# dancer configuration
set port => 7052;
set charset => "UTF-8";

# global variables
my $json = new JSON;

# initialize session variables
my $user;
my $udir;
my $token;

# initialize status variables
my $login_failed = 0;
my $logged_out = 0;

# the site is called without parameters, show the upload screen
any '/' => sub {

  check_login();
  
  my $init = qq~<script>jQuery(function(){init();});</script>~;

  if ($user) {
    return start_template().upload_screen().$init.end_template();
  } else {
    return start_template().login_screen().$init.end_template();
  }

};

# the user inbox is being retrieved
any '/inbox' => sub {
  
  check_login();

  # if there is no user, abort the request
  unless ($user) {
    return "unauthorized request";
  }
  
  # check if the user directory exists
  &initialize_user_dir();

  read_inbox();
};

# a file upload is being performed
any '/upload' => sub {
  
  check_login();

  # if there is no user, abort the request
  unless ($user) {
    return "unauthorized request";
  }
  
  # check if the user directory exists
  &initialize_user_dir();
  
  # If we get here, this is an actual upload
  unless (param('upload_file') ) {
    return "no upload file passed";
  }
  my $file = upload('upload_file');
  my $filename = param('filename');
    
  # check if this is the first block, if so, create the file
  if (-f "$udir/".$filename && ! -f "$udir/$filename.part") {
    return "file already exists";
  }
  # otherwise, append to the file
  else {
    my $tmpname = $file->tempname;
    `cat $tmpname >> $udir/$filename`;
    `touch $udir/$filename.part`;
  }
  
  # if this is the last chunk, remove the partial file
  if (param('last_chunk') ) {
    `rm $udir/$filename.part`;
    return "file received";
  } else {
    return "chunk received";
  }
};

# the data viewer is activated
any '/view' => sub {
  
  check_login();

  my $html = start_template().progress();
  $html .= "<div id='viewspace'></div>";
  $html .= qq~<script type="text/javascript">
    jQuery(function () {
  	stm.init().then(function() {
  	    Retina.init( { library_resource: "/" } ).then( function () {
  		Retina.add_widget({"name": "Browser", "resource": "/",  "filename": "widget.Browser.js" });
  		Retina.load_widget("Browser").then( function () {
  		    Retina.Widget.Browser.create(document.getElementById('viewspace'));
  		});
  	    });
  	});
    });
    </script>~;
  $html .= end_template();

  return $html;
};

any '/pipelines' => sub {

  check_login();
  
  my $html = start_template();
  $html .= message("info", "Pipeline Submission Screen<br><br>This still needs to be implemented.");
  $html .= end_template();

  return $html;
};

# file submission to shock
any '/submit' => sub {

  check_login();

  # get the list of files to submit
  my $files = param('submission_files');
  unless (ref($files) eq 'ARRAY') {
    $files = [ $files ];
  }

  my $html = start_template();
  foreach my $file (@$files) {
    my $retval = submit_to_shock("$udir/$file", "$udir/$file.attributes");
    if ($retval->[0] eq 'success') {
      $html .= message($retval->[0], "The file <b>".$retval->[1]->{file}->{name}."</b> was successfully submitted with id <b>".$retval->[1]->{id}."</b>");
    } else {
      $html .= message($retval->[0], "The file <b>".$file."</b> failed to submit: ".$retval->[1]);
    }
  }
  my $init = qq~<script>jQuery(function(){init();});</script>~;
  $html .= $init.upload_screen();
  $html .= end_template();

  return $html;
};

##############################
# start of templates section #
##############################

sub start_template {
  my $html = qq~
<html>

    <head>

      <title>KBase Uploader</title>
      
      <script type="text/javascript" src="~. JS_DIR .qq~jquery.min.js"></script>
      <script type="text/javascript" src="~. JS_DIR .qq~bootstrap.min.js"></script>
      <script type="text/javascript" src="~. JS_DIR .qq~upload.js"></script>
      <script type="text/javascript" src="~. JS_DIR .qq~stm.js"></script>
      <script type="text/javascript" src="~. JS_DIR .qq~retina.js"></script>

      <link rel="stylesheet" type="text/css" href="~. CSS_DIR .qq~bootstrap.min.css">

    </head>

    <body>    
    <div class="container">
      <img src="~ . IMAGE_DIR . qq~KbaseLogo.jpg">
      <div class="navbar">
	<div class="navbar-inner">
	  <div class="container">
            <a style="color: white; cursor: default;" href="#" class="brand">KBASE Uploader</a>
	    <ul class="nav">
	      <li>
		<a href="/">upload</a>
	      </li>
	      <li>
		<a href="/view">view</a>
	      </li>
	      <li>
		<a href="/pipelines">pipelines</a>
	      </li>
            </ul>
            ~.&user_display().qq~
	  </div>
	</div>
      </div>
      <div class="alert alert-info" id="inbox_feedback_msg" style="display: none;"></div>~;
  return $html;
}

sub end_template {
  return qq~  </body>
</html>
~;
}

sub user_display {
  if ($user) {
    return qq~<ul class="nav" style="float: right;">
              <li>
                <a href="#" onclick="if(confirm('Do you want to log out?')){window.top.location='?logout=1';}"><i class="icon-user icon-white"></i>&nbsp;&nbsp;<span id='uid' sid='$token' aid='~.SHOCK_URL.qq~'>~.$user.qq~</span></a>
              </li>
	    </ul>~;
  } else {
    return "";
  }
}

sub login_screen {

  my $message = "";
  if ($login_failed) {
    $message = message("error", "login failed - incorrect username or password");
  }

  if ($logged_out) {
    $message = message("info", "you have been logged out");
  }

  return qq~
<div class="well">
  <h4>Please log in with your kbase credentials</h4>$message
  <br>
  <form class="form-inline" method="post" action="http://localhost:7052">
    <input class="input-small" type="text" placeholder="Login" name="login">
    <input class="input-small" type="password" placeholder="Password" name="pass">
    <button class="btn" type="submit">Sign in</button>
  </form>
</div>~;
}

sub error {
  my ($error) = @_;

  return start_template().message($error->[0], $error->[1]).end_template();
}

sub message {
  my ($type, $message) = @_;
  
  return qq~<br><div class="alert alert-$type">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>$type</strong><br>
$message
</div>~;
}

sub progress {
  return qq~<div id="progressIndicator" class="alert alert-info" style="display: none; width: 140px; float: right; margin-right: 20px;"><b><span id="progressBar"></span></b></div>~;
}

sub upload_screen {
  return qq~
<div class="well">
  <h4 style="margin-bottom: 5px;">select files to upload</h4>
  <p>Select one or more files to upload to your private inbox folder.</p>
  <form class="form-horizontal">
    <input class="input-file" type="file" multiple size=40 id="file_upload">
  </form>

  <div id="upload_progress" style="display: none;">
    <br><h4>upload progress</h4><br>
    <div id="uploaded_files" style="display: none;" class="alert alert-info"></div>
    <div id="progress_display">
      <table>
        <tr>
          <td colspan=2>
            <div class="alert alert-success" id="upload_status"></div>
          </td>
        </tr>
        <tr>
          <td style="width: 150px;"><h5>total</h5></td>
          <td>
            <progress id="prog1" min="0" max="100" value="0" style="width: 400px;">0% complete</progress>
          </td>
        </tr>
        <tr>
          <td><h5>current file</h5></td>
          <td>
            <progress id="prog2" min="0" max="100" value="0" style="width: 400px;">0% complete</progress>
          </td>
        </tr>
      </table>
      <a class="btn btn-danger" href="#" onclick="cancel_upload();" style="position: relative; top: 9px; left: 435px;"><i class="icon-ban-circle"></i> cancel upload</a>
    </div>
  </div>

  <h4 style="margin-bottom: 5px;">private inbox</h4>
  <p>Please note that this is a temporary space. Files in here must be submitted to the auxiliary store within one week or they will be automatically deleted. Once a file is submitted to the auxiliary store, it will be removed from your inbox. Use the <b>view</b> button in the menu to view your personal files in the auxiliary store.</p>
  <p><input type="button" class="btn" value="delete selected" onclick="check_delete_files();"><input type="button" class="btn" value="uncompress selected" onclick="uncompress_files();"><input type="button" class="btn" value="change file directory" onclick="change_file_dir();"></p>
  <div id="inbox" style='margin-top: 10px;'><br><br><img src="~.IMAGE_DIR.qq~loading.gif"> loading...</div>
  <p><input type="button" class="btn" value="select for submission" onclick="select_files();" style="margin-top: -10px;"></p>

  <h4 style="margin-bottom: 5px;">submit to auxiliary store</h4>
  <p>Files uploaded to the auxiliary store need to be accompanied by a metadata file. The data must be in a <span style="cursor: pointer; color: #0088CC;" id="json_object">JSON style object</span> which has at least the attribute 'type' at the top level. The metadata file must have the exact same filename as the data file, appending the extension <b>.attributes</b>. Note that extensive metadata is essential in any further analyses or queries.</p>
  <table><tr><td><form id="submission_form" action="/submit" method="post"><select id="submission_box" name="submission_files" multiple style="width: 420px; height: 200px;"></select></form></td><td id="submission_info"></td></tr></table>
  <p><input type="button" class="btn" value="remove selected" onclick="remove_submit_files();">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="button" class="btn" value="submit to aux store" onclick="if(document.getElementById('submission_box').options.length){selectAll(document.getElementById('submission_box'));document.getElementById('submission_form').submit();}else{alert('You did not select any files');}"></p>
</div>
~;
}

############################
# start of methods section #
############################

# check if a login or logout is being performed
sub check_login {
  my $cn = SESSION_COOKIE_NAME;
  
  # get the cookie
  my $cookie = cookie $cn;

  # check if a logout is being performed
  if (param('logout')) {
    cookie $cn => '', expires => "-1d";
    $logged_out = 1;
    $user = undef;
    $token = undef;
    return;
  } else {
    $logged_out = 0;
  }

  # check if a login is being performed
  if (param('login') && param('pass')) {
    my $exec = 'curl -s -u '.param('login').':'. param('pass') .' -X POST "'.AUTH_SERVER_URL.'"';
    my $result = `$exec`;
    my $ustruct = "";
    eval {
      $ustruct = $json->decode($result);
    };
    if ($@) {
      $user = undef;
      $token = undef;
      $login_failed = 1;
    } else {
      if ($ustruct->{user_name} && $ustruct->{access_token}) {
	cookie $cn => $ustruct->{access_token}, expires => $ustruct->{expires_in} ? "+".$ustruct->{expires_in}."s" : SESSION_TIMEOUT;
	$user = $ustruct->{user_name};
	$token = $ustruct->{access_token};
	$login_failed = 0;
      } else {
	$user = undef;
	$token = undef;
	$login_failed = 1;
      }
    }
    return;
  }
  
  # check if we have a valid cookie
  if ($cookie && ! $login_failed && ! $logged_out && ! $user) {
    $token = $cookie;
    my $expires;
    ($user, $expires) = $cookie =~ /un=(\w+)\|.*\|expiry=(\d+)\|/;
    cookie $cn => $cookie, expires => $expires ? '+'.($expires - time).'s' : SESSION_TIMEOUT;
    return;
  }
}

# check if the user directory exists, if not create it
sub initialize_user_dir {

  if ($user) {
    $udir = USER_DIR."/".md5_hex($user);
  } else {
    $udir = undef;
    return;
  }

  unless ( -d $udir ) {
    unless (mkdir $udir) {
      return "could not create directory '$udir'";
    }
    chmod 0777, $udir;
  }
  unless ( -d "$udir/.tmp") {
    unless (mkdir "$udir/.tmp") {
      return "could not create directory '$udir/.tmp'";
    }
    chmod 0777, "$udir/.temp";
  }
  my $user_file = "$udir/USER";
  if ( ! -e $user_file ) {	
    if (open(USER, ">$user_file")) {
      print USER $user."\n";
      close(USER);
      chmod 0666, $user_file;
    } else {
      return "could not open file '$user_file': $!";
    }
  }
}

# submit a file with attributes to shock
sub submit_to_shock {
  my ($file, $attributes) = @_;
  
  my $url = SHOCK_URL;

  # check if all required parameters are passed
  unless ($file && $attributes) {
    return [ "error", "required parameter missing in submission call" ];
  }

  # check if the passed parameters are valid
  unless (-f $file) {
    return [ "error", "submission called with invalid file" ];
  }
  unless (-f $attributes) {
    return [ "error", "submission called with invalid attributes file" ];
  }

  # initialize the exec call
  my $exec = "curl -s -X POST";

  # check for authentication
  if ($token) {
    $exec .= ' -H "Authorization: Globus-Goauthtoken '.$token.'"';
  }

  # attach the files and url
  $exec .= ' -F "attributes=@'.$attributes.'" -F "upload=@'.$file.'" "'.$url.'"';

  # perform the upload
  my $result = `$exec`;
  
  # check the result
  eval {
    $result = $json->decode($result);
  };
  if ($@) {
    return [ "error", $@ ];
  }
  if ($result->{S} > 200) {
    return [ "error", $result->{E}->[0] ];
  } else {
    return [ "success", $result->{D} ]
  }
}

sub read_inbox {
  # prepare return data structure
  my $data = { files => [], fileinfo => {}, messages => [], directories => [] };
  
  # check if we are supposed to do anything else than return the content of the inbox
  if (param('faction')) {
    my $action = param('faction');
    my $files = param('fn');
    unless (ref($files) eq 'ARRAY') {
      $files = [ $files ];
    }
    
    # delete a list of files
    if ($action eq 'del') {
      foreach my $file (@$files) {
	if (-f "$udir/$file") {		    
	  `rm '$udir/$file'`;
	  
	  # check if the file is in a directory
	  if ($file =~ /\//) {		      
	    my ($dn) = $file =~ /^(.*)\//;
	    $dn = $udir."/".$dn;
	    
	    # if the directory is empty, delete it
	    my @fls = <$dn/*>;
	    if (! scalar(@fls)) {
	      `rm -rf $dn`;
	    }
	  }
	}
      }
    }
    
    #  move a list of files
    if ($action eq 'move') {
      my $target_dir = shift(@$files);
      if ($target_dir eq 'inbox') {
	$target_dir = $udir."/";
      } else {
	unless (-d "$udir/$target_dir") {
	  `mkdir '$udir/$target_dir'`;
	}
	$target_dir = "$udir/$target_dir/";
      }
      foreach my $file (@$files) {
	`mv $udir/$file $target_dir`;
      }
    }
    
    # decompress a list of files
    if ($action eq 'uncompress') {
      foreach my $file (@$files) {
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
	  map { $_ =~ s/$udir\///g } @msg;
	  push(@{$data->{messages}}, join("<br>",@msg));
	}
      }
    }
  }
  
  # read the contents of the inbox
  my $indir = {};
  my $attribute_files = {};
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
	push(@{$data->{messages}}, "<br>The file <b>'$ufile'</b> contained invalid characters. It has been renamed to <b>'$newfilename'</b>");
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
	    if ($nf =~ /^(.*)\.attributes$/) {
	      $attribute_files->{"$ufile/$1"} = 1;
	    }
	    push(@$dirseqs, $nf);
	    push(@ufiles, "$ufile/$nf");		
	  }
	  $data->{fileinfo}->{$ufile} = $dirseqs;
	} else {
	  `rm -rf $udir/$ufile`;
	}
      }
      # check files
      else {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat("$udir/$ufile");
	if ($size == 0) {
	  `rm -f "$udir/$ufile"`;
	  next;
	}
	if ($ufile =~ /^(.+)\.attributes$/) {
	  $attribute_files->{$1} = 1;
	}
	unless ($ufile =~ /\//) {
	  push(@{$data->{files}}, $ufile);
	}
      }
    }
  }

  # parse attribute files
  foreach my $attfile (keys(%{$attribute_files})) {
    if (open(FH, "$udir/$attfile.attributes")) {
      my $attdata = "";
      while (<FH>) {
	$attdata .= $_;
      }
      close FH;
      my $attstruct;
      eval {
	$attstruct = $json->decode($attdata);
      };
      if ($@) {
	my $error = $@;
	$error =~ s/^(.*)( at uploader\.pl.*)/$1/;
	$data->{fileinfo}->{"$attfile.attributes"}->{'error'} = "The file is not valid JSON: $error";
	$data->{fileinfo}->{"$attfile"}->{'not submittable'} = "The associated attributes file does not contain valid JSON: $error";
      } else {
	$data->{fileinfo}->{"$attfile.attributes"}->{'valid'} = "This file contains valid JSON";
	$data->{fileinfo}->{"$attfile"}->{'submittable'} = "This file has a valid attributes file";
      }
    } else {
      $data->{fileinfo}->{"$attfile.attributes"}->{'error'} = "The file could not be opened: $@";
      $data->{fileinfo}->{"$attfile"}->{'not submittable'} = "The associated attributes file could not be opened: $@";
    }
  }
    
  # add basic file information to all files
  my $file_wo_attributes = 0;
  foreach my $file (@ufiles) {
    next unless (-f "$udir/$file");
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat("$udir/$file");
    unless (exists($data->{fileinfo}->{$file})) {
      $data->{fileinfo}->{$file} = {};
    }
    $data->{fileinfo}->{$file}->{'creation date'} = &pretty_date($ctime);
    $data->{fileinfo}->{$file}->{'file size'} = &pretty_size($size);
    if ($file !~ /^(.*)\.attributes$/ && ! exists($data->{fileinfo}->{$file.".attributes"})) {
      $data->{fileinfo}->{$file}->{"not submittable"} = "This file does not have an associated attributes file";
      $file_wo_attributes = 1;
    }
  }

  # send an info message about attributes files if at least one file is missing one
  if ($file_wo_attributes) {
    push(@{$data->{messages}}, "In order to submit a file to the auxiliary store, you must supply an accompanying attributes file containing metadata. The attributes file must have the exact same name as the file to submit, appending the ending <b>.attributes</b>. The metadata must be in JSON format, i.e.<br><br><pre>{ \"type\": \"metagenome\", \"name\": \"Sample123\", \"biome\": \"human gut\", ... }</pre>");
  }

  # sort the returned files lexigraphically
  @{$data->{files}} = sort { lc $a cmp lc $b } @{$data->{files}};
  
  content_type 'application/json';

  return $json->encode($data);
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

start;

sub TO_JSON { return { %{ shift() } }; }

1;


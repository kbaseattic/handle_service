#!/kb/runtime/bin/perl

use strict;
use warnings;

use Data::Dumper;

use CGI;
use CGI::Cookie;
use JSON;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Bio::KBase::AuthServer;
use Bio::KBase::AuthClient;

# config for all uploader variables
use UploaderConfig;

$Bio::KBase::Auth::AuthSvcHost = AUTH_SERVER_URL;

# get a cgi and a json object
my $cgi = new CGI;
my $json = new JSON;
$json = $json->utf8();

# initialize cookie and user
my $cookie = $cgi->cookie( SESSION_COOKIE_NAME );
my $user = undef;

# set this to 1 to disable authentication
my $no_auth = 0;

# initialize status variables
my $login_failed = 0;
my $logged_out = 0;
my $logged_in = 0;

# check if a logout is being performed
if ($cgi->param('logout')) {
    $cookie = CGI::Cookie->new( -name    => SESSION_COOKIE_NAME ,
				-value   => '',
				-expires => "-1d" );
    $logged_out = 1;
}

# demouser for authentication off mode
my $demouser = { user_id => "hmeier",
		 oauth_creds => { "demokey" => { oauth_secret => "geheim" } },
		 name => "Hans Meier" };

# check if a login is being performed
if ($cgi->param('login') && $cgi->param('pass')) {

  if ($no_auth) {
    $user = $demouser;
    $cookie = CGI::Cookie->new( -name    => SESSION_COOKIE_NAME,
				-value   => "lsdjfhglkjh84y3jfhdkjb",
				-expires => SESSION_TIMEOUT );
  } else {
    my $ac = Bio::KBase::AuthClient->new( consumer_key => $cgi->param('login'), consumer_secret => $cgi->param('pass') );
    if ($ac->{logged_in}) {
      $user = $ac->{user};
      my $token = $ac->auth_token( request_method => 'GET', request_url => AUTH_SERVER_URL );
      $cookie = CGI::Cookie->new( -name    => SESSION_COOKIE_NAME,
				  -value   => $token,
				  -expires => SESSION_TIMEOUT );
      $logged_in = 1;
    } else {
      $login_failed = 1;
    }
  }
}

# check if we have a valid cookie
if ($cookie && ! $login_failed && ! $logged_out && ! $logged_in) {

  if ($no_auth) {
    $user = $demouser;
    $cookie = CGI::Cookie->new( -name    => SESSION_COOKIE_NAME,
				-value   => "lsdjfhglkjh84y3jfhdkjb",
				-expires => SESSION_TIMEOUT );
  } else {
    my $as = new Bio::KBase::AuthServer;
    if ($as->validate_auth_header($cookie, request_method => "GET", request_url => AUTH_SERVER_URL )) {
      $user = $as->user;
      $cookie = CGI::Cookie->new( -name    => SESSION_COOKIE_NAME,
				  -value   => $cookie,
				  -expires => SESSION_TIMEOUT );
    }
  }
}

# check for submission to shock
my $message = "";
if ($cgi->param('submit_to_shock')) {
  if ($user) {
    # set the user directory
    my $udir = BASE_DIR."/".md5_hex($user->{user_id});
    
    # get the user authentication for shock
    my $user_pass = $user->{'oauth_creds'}->{'oauth_secret'};
    my $user_name = $user->{'user_id'};
    
    # get the list of files to be submitted
    my @filenames = split(/\|/, $cgi->param('subfiles'));
    
    # check if we have a metadata file in the uploade
    my $attributes = {};
    if ($cgi->param('mdfile')) {
      # get the validated metadata
    }
    
    # iterate over the files to be submitted
    foreach my $filename (@filenames) {
      
      # check if there are attributes present for this file
      my $file_attributes = "";
      if ($attributes->{$filename}) {
	
	# we have attributes, print them to a file so we can submit them to SHOCK
	if (open(FH, ">$udir/$filename.attributes")) {
	  print FH $json->encode($attributes->{$filename});
	  close FH;
	  $file_attributes = ' -F "attributes=@'.$file_attributes.'$udir/$filename.attributes"';
	} else {
	  $message .=  qq~<br><div class="alert alert-error">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Warning</strong><br>
Your submission for $filename failed because the attributes file could not be written:<br> $@.
</div>~;
	}
      }
      
      my $stats = {};
      my $shock_id = undef;
      if (open(FH, "<$udir/$filename.stats_info")) {
	while (<FH>) {
	  chomp;
	  my ($key, $val) = split /\t/;
	  $stats->{$key} = $val;
	}
	close FH;
	if ($stats->{shock_id}) {
	  $shock_id = $stats->{shock_id};
	}
      }
      
      my $basefilename = $filename;
      if ($shock_id) {
	$message .= qq~<br><div class="alert alert-info">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Info</strong><br>
Your file had already been submitted to the KBase Auxiliary Store:<br>
<table>
<tr><th align=left>file</th><td>~.$filename.qq~</td></tr>
<tr><th align=left>checksum</th><td>~.$stats->{file_checksum}.qq~</td></tr>
<tr><th align=left>id</th><td>~.$shock_id.qq~</td></tr></table>
</div>~;
	
      } else {
	# execute the SHOCK submission via curl
	$filename = "$udir/$filename";
	my $exec_string = 'curl -X POST -F "file=@'.$filename.'" '.SHOCK_URL;
	my $retval = `$exec_string`;
	$retval = $json->decode($retval);
	if ($retval->{S} > 200) {
	  $message .= qq~<br><div class="alert alert-error">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Warning</strong><br>
Your submission failed: ~.$retval->{E}->[0].qq~
</div>~;
	} else {
	  $message .= qq~<br><div class="alert alert-success">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Info</strong><br>
Your submission to the KBase Auxiliary Store was successful:<br>
<table>
<tr><th align=left>file</th><td>~.$retval->{D}->{file}->{name}.qq~</td></tr>
<tr><th align=left>size</th><td>~.$retval->{D}->{file}->{size}.qq~</td></tr>
<tr><th align=left>checksum</th><td>~.$retval->{D}->{file}->{checksum}->{md5}.qq~</td></tr>
<tr><th align=left>id</th><td>~.$retval->{D}->{id}.qq~</td></tr></table>
</div>~;
	}
	
	$shock_id = $retval->{D}->{id};
	
	if (open(FH, ">>$udir/$filename.stats_info")) {
	  print FH "shock_id\t".$retval->{D}->{id};
	  print FH "file_checksum\t".$retval->{D}->{file}->{checksum}->{md5};
	  close FH;
	}
      }
      
      # check for pipeline execution
      if ($cgi->param('pipeline') && $cgi->param('pipeline') ne "0") {
	my $pipeline = $cgi->param('pipeline');
	$pipeline =~ s/html$/exec/;
	my ($pipeline_name) = $pipeline =~ /^(.+)\.exec/;

	if ($shock_id) {
	  
	  # read the pipeline execution file
	  if (open(FH, PIPELINE_DIR."/$pipeline")) {
	    my $pipeline_exec = <FH>;
	    chomp $pipeline_exec;
	    close FH;
	    
	    # replace the input file name
	    my $shock_file_url = SHOCK_URL."/".$shock_id."?download";
	    $pipeline_exec =~ s/INPUT_FILE/$shock_file_url/;
	    
	    # replace the output file name
	    $pipeline_exec =~ s/OUTPUT_FILE/$basefilename\.out/;
	    
	    # replace all other pipeline parameters
	    my @params = $cgi->param;
	    foreach my $param (@params) {
	      my $uc_param = uc($param);
	      my $val = $cgi->param($param);
	      $pipeline_exec =~ s/$uc_param/$val/;
	    }
	    
	    # execute the pipeline
	    my $retval = `$pipeline_exec`;

	    $message .= qq~<br><div class="alert alert-success">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Info</strong><br>
Your submission to the $pipeline_name pipeline was executed:<br>
$retval
</div>~;
	  } else {
	    $message .= qq~<br><div class="alert alert-error">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Error</strong><br>
Your submission to the $pipeline_name pipeline failed because the execution file could not be openend:<br><br> $@
</div>~;
	  }
	} else {
	  $message .= qq~<br><div class="alert alert-error">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Error</strong><br>
Your submission to the $pipeline_name pipeline failed because the upload to the KBase Auxiliary Store failed.
</div>~;
	}
      }
    }
  } else {
    $message .= qq~<br><div class="alert alert-error">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Warning</strong><br>
Your submission failed because of an authentication error.
</div>~;
  }
}


# we have a user, display the upload interface
if ($user) {
  
  print $cgi->header( -cookie => $cookie );
  print qq~<!DOCTYPE html>
<html>

  <head>

    <title>KBase Uploader</title>

    <script type="text/javascript" src="~ . JS_DIR . qq~jquery.1.7.2.min.js"></script>
    <script type="text/javascript" src="~ . JS_DIR . qq~bootstrap.min.js"></script>
    <script type="text/javascript" src="~ . JS_DIR . qq~Upload.js"></script>

    <link rel="stylesheet" type="text/css" href="~ . CSS_DIR . qq~bootstrap.min.css">
    <link rel="stylesheet" type="text/css" href="~ . CSS_DIR . qq~Upload.css">

  </head>

  <body onload="init();">
    
    <div class="container">
      <img src="~ . IMAGE_DIR . qq~KbaseLogo.jpg">
      <div class="navbar">
	<div class="navbar-inner">
	  <div class="container">
	    <ul class="nav">
	      <li class="active">
		<a href="#" style="cursor: default;">KBASE Uploader - upload your biological data to the KBase Auxiliary Store</a>
	      </li>
</ul>
<ul class="nav" style="float: right;">
              <li class="active">
                <a href="#" onclick="if(confirm('Do you want to log out?')){window.top.location='?logout=1';}"><i class="icon-user icon-white"></i>~.$user->{name}.qq~</a>
              </li>
	    </ul>
	  </div>
	</div>
      </div>$message
      <h3>Prepare Data</h3>
      
      <ul class="nav nav-pills nav-stacked">
	<li><a onclick="toggle('sel_mddownload_div');" class="pill_incomplete" id="sel_mddownload_pill" style="font-size: 17px; font-weight: bold;">1. download metadata spreadsheet template</a></li>
	<div id="sel_mddownload_div" style="display: none;" class="well">
          <h3>download metadata spreadsheet template</h3>
	  <p>Metadata (or data about the data) has become a necessity as the community generates large quantities of data sets.</p>
	  <p>Using community generated questionnaires we capture this metadata. KBASE has implemented the use of <a href='http://gensc.org/gc_wiki/index.php/MIxS' target=_blank>Minimum Information about any (X) Sequence</a> developed by the <a href='http://gensc.org' target=_blank >Genomic Standards Consortium</a> (GSC).</p>
	  <p>The best form to capture metadata is via a simple spreadsheet with 12 mandatory terms. You can download the spreadsheet file here, fill in the required data fields later upload it to your inbox.</p>
	  <p>While the MIxS required data fields capture only the most minimal metadata, many areas of study have chosen to require more elaborate questionnaires ("environmental packages") to help with analysis and comparison. These are marked as optional in the spreadsheet. If the "environmental package" for your area of study has not been created yet, please <a href="mailto:info\@kbase.us">contact KBASE staff</a> and we will forward your inquiry to the appropriate GSC working group.</p>
	  <p>Once you have filled out the template, you can upload it below and it will be validated and appear in the metadata selection section.</p>
          <p style="text-align: center;"><a href="#" class="btn btn-primary" onclick="window.open('./spreadsheet');"><i class="icon-download icon-white"></i> download metadata spreadsheet template</a></p>
        </div>
	
        <li><a onclick="toggle('sel_upload_div');" class="pill_incomplete" id="sel_upload_pill" style="font-size: 17px; font-weight: bold;">2. upload files</a></li>
	<div id="sel_upload_div" style="display: none;" class="well">
          <h3>upload files</h3>
	  <table>
	    <tr>
	      <td>
		<form class="form-horizontal">
		  <input class="input-file" type="file" multiple size=40 id="file_upload">
		</form>
	      </td>
	      <td style="padding-left: 40px;">
		<p>Select one or more files to upload to your private inbox folder.</p>
		<p>Sequence files must be fasta, fastq, or sff format.
		  Use vaild file extensions for the appropriate format: .fasta, .faa, .fa, .ffn, .frn, .fna, .fastq, .fq, .sff</p>
	      </td>
	    </tr>
	  </table>
	  <div id="upload_progress" style="display: none;">
	    <br><h3>upload progress</h3><br>
	    <div id="uploaded_files" style="display: none;" class="alert alert-info">
	    </div>
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
          
        </div>
	
        <li><a onclick="toggle('sel_inbox_div');" class="pill_incomplete" id="sel_inbox_pill" style="font-size: 17px; font-weight: bold;">3. manage inbox</a></li>
	<div id="sel_inbox_div" style="display: none;" class="well">
	  <p>You can uncompress and delete files in your inbox below or move them into a subdirectory. Submission files will automatically appear in the <i>'select submission file(s)'</i> section below. Metadata files will automatically appear in the <i>'select metadata file'</i> section below. You can click on a file to view file details. Clicking on a directory will expand / collapse its contents.</p>
          <input type="button" class="btn" value="delete selected" onclick="check_delete_files();">
          <input type="button" class="btn" value="uncompress selected" onclick="uncompress_files();">
          <input type="button" class="btn" value="change file directory" onclick="change_file_dir();">
          <input type="button" class="btn" value="update inbox" onclick="update_inbox();">
          <div id="inbox" style='margin-top: 10px;'><br><br><img src="~.IMAGE_DIR.qq~loading.gif"> loading...</div>
        </div>
      </ul>
      
      <h3>Data Submission</h3>
      
      <form class="form-horizontal" name="submission_form" method='post' action='uploader'>
	<input type="hidden" name="submit_to_shock" value="1">
	<ul class="nav nav-pills nav-stacked">
	  
	  <li><a onclick="toggle('sel_md_div');" class="pill_incomplete" id="sel_md_pill" style="font-size: 17px; font-weight: bold;">1. select metadata file <i id="icon_step_1" class="icon-ok icon-white" style="display: none;"></i></a></li>
	  
	  <div id="sel_md_div" style="display: none;" class="well">
	    <h3>available metadata files</h3>
	    <p>Select a spreadsheet with metadata for the files you want to submit. Uploaded spreedsheets will appear here after successful validation.</p>
	    <p><b>Note: metadata is required for submission</b></p>
            <div id="sel_mdfile_div"><select multiple></select><br><input type="button" class="btn" value="select"><br></div>
	  </div>
	  
	  <li><a onclick="toggle('sel_sub_div');" class="pill_incomplete" id="sel_sub_pill" style="font-size: 17px; font-weight: bold;">2. select submission file(s) <i id="icon_step_2" class="icon-ok icon-white" style="display: none;"></i></a></li>
	  <div id="sel_sub_div" style="display: none;" class='well'>
	    <div id="selected_submissions"></div>
	    <div id='available_submissions'>
	      <h3>available submission files</h3>
	      <br>
	      <select id="submission_file_select" style="width: 420px; height: 200px;" multiple=""></select>
	      <br>
	      <input type='button' class='btn' value='select' onclick='select_submission_file();'>
	    </div>
	    <div id='selected_sequences'></div>
	  </div>
	  
          <li><a onclick="toggle('sel_opt_div');" class="pill_incomplete" id="sel_opt_pill" style="font-size: 17px; font-weight: bold;">3. choose pipeline options <i id="icon_step_3" class="icon-ok icon-white" style="display: none;"></i></a></li>
	  <div id="sel_opt_div" style="display: none;" class="well">
	    <h3>selected pipeline options</h3>
	    <div class="control-group" id="pipelines">

            </div>
	    
	    <input type="button" class="btn" value="accept" onclick="accept_submission_options();" id="accept_submission_options_button">
	  </div>
	  
	  <li><a onclick="toggle('sub_div');" class="pill_incomplete" id="sub_pill" style="font-size: 17px; font-weight: bold;">4. submit <i id="icon_step_4" class="icon-ok icon-white" style="display: none;"></i></a></li>
	  <div id="sub_div" style="display: none;" class="well">
	    <h3>submit data to the KBase Auxiliary Store</h3>
	    
	    <p>Data will be private (only visible to the submitter) unless you choose to make it public.</p>
	    
	    <div style='margin-bottom: 20px;'><input type="button" class="btn" value="submit data" onclick="perform_submission();" disabled id="submit_button"><span style='margin-left: 20px;'><b>Note: You must complete all previous steps to enable submission.</b></span></div>
	    <p>Upon successful submission KBase IDs will be automatically assigned and data files will be removed from your inbox.</p>
	</ul>
      </form>
      </div>
  </body>
</html>
~;
} else {
    # there is no user

    # check if we need to overwrite the cookie with the logged out version
    if ($cookie) {
	print $cgi->header(-cookie => $cookie);
    } else {
	print $cgi->header();
    }

    # print the login screen
    print qq~<!DOCTYPE html>
<html>

  <head>

    <title>KBase Uploader</title>

    <script type="text/javascript" src="~ . JS_DIR . qq~jquery.1.7.2.min.js"></script>
    <script type="text/javascript" src="~ . JS_DIR . qq~bootstrap.min.js"></script>
    <script type="text/javascript" src="~ . JS_DIR . qq~Upload.js"></script>

    <link rel="stylesheet" type="text/css" href="~ . CSS_DIR . qq~bootstrap.min.css">
    <link rel="stylesheet" type="text/css" href="~ . CSS_DIR . qq~Upload.css">

  </head>

  <body>
    
    <div class="container">
      <img src="~ . IMAGE_DIR . qq~KbaseLogo.jpg">
      <div class="navbar">
	<div class="navbar-inner">
	  <div class="container">
	    <ul class="nav">
	      <li class="active">
		<a href="#">KBASE Uploader - upload your biological data to the KBase Auxiliary Store</a>
	      </li>
	    </ul>
	  </div>
	</div>
      </div>

      <div class="well">
         <h3>Please log in with your kbase credentials</h3>$message
~;
    
    # check if there has been an unsuccessful login and tell the user about it
    if ($login_failed) {
	print qq~<br><div class="alert alert-error">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Warning</strong><br>
Login or password incorrect.
</div>~;
    }

    # check if the user just logged out and tell about it
    if ($logged_out) {
	print qq~<br><div class="alert alert-info">
<button class="close" data-dismiss="alert" type="button">x</button>
<strong>Info</strong><br>
You have been logged out.
</div>~;
    }

    # print the login form
    print qq~
         <form class="well form-inline" action="uploader" method="post">
            <input class="input-small" type="text" placeholder="Login" name="login">
            <input class="input-small" type="password" placeholder="Password" name="pass">
            <button class="btn" type="submit">Sign in</button>
         </form>
      </div>

    </div>

  </body>
</html>
~;
}

# make sure the json->encode can handle perl hashes
sub TO_JSON { return { %{ shift() } }; }

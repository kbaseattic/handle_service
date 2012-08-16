package UploaderConfig;

use constant BASE_DIR => "/incoming";
use constant SHOCK_URL => "http://shock.mcs.anl.gov/node";
use constant AUTH_SERVER_URL => "http://140.221.92.45/profiles";
use constant SESSION_COOKIE_NAME => "kbase_session";
use constant SESSION_TIMEOUT => "+2d";
use constant METADATA_TEMPLATE_FILE => "/Templates/MetaData_template.xlsx";
use constant IMAGE_DIR => "";
use constant CSS_DIR => "";
use constant JS_DIR => "";

our @ISA = qw( Exporter );
our @EXPORT = qw( BASE_DIR SHOCK_URL AUTH_SERVER_URL SESSION_COOKIE_NAME SESSION_TIMEOUT METADATA_TEMPLATE_FILE IMAGE_DIR CSS_DIR JS_DIR );

1;

package Conf;

require Exporter;

# external sites
use constant SHOCK_URL => "http://www.kbase.us/services/shock-api/node";
use constant AUTH_SERVER_URL => "https://nexus.api.globusonline.org/goauth/token?grant_type=client_credentials";

# session management
use constant SESSION_COOKIE_NAME => "kbase_session";
use constant SESSION_TIMEOUT => "+2d";

# directories
use constant BASE_URL => 'localhost';
use constant IMAGE_DIR => '';
use constant JS_DIR => '';
use constant CSS_DIR => '';
use constant USER_DIR => '/kb/deployment/services/aux_store/uploader/incoming';

@ISA = qw(Exporter);
@EXPORT = qw(SHOCK_URL AUTH_SERVER_URL SESSION_COOKIE_NAME SESSION_TIMEOUT BASE_URL IMAGE_DIR JS_DIR CSS_DIR USER_DIR);

1;

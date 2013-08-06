"""KBase ADM client library.

adm.Client inherits from shock.Client(https://github.com/MG-RAST/Shock)

Authors:

* Jared Wilkening
"""

#-----------------------------------------------------------------------------
# Imports
#-----------------------------------------------------------------------------

import shock

#-----------------------------------------------------------------------------
# Classes
#-----------------------------------------------------------------------------

class Client(shock.Client):
    def __init__(self, *args,**kwarg):
        super(shock.Client, self).__init__(*args,**kwarg)
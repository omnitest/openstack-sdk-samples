#!/usr/bin/env python

import os
import pyrax

pyrax.set_setting("identity_type", "rackspace")
# Create the identity object
pyrax._create_identity()
# Change its endpoint
endpoint = os.getenv('OS_AUTH_URL')
if endpoint is not None:
  pyrax.identity.auth_endpoint = os.getenv('OS_AUTH_URL') + '/v2.0/'

# Authenticate
pyrax.set_credentials(os.getenv('RAX_USERNAME'), os.getenv('RAX_API_KEY'))

print "Authenticated"
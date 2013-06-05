#
# an implementation of http_get/http_post that
# uses Google AppEngine urlfetch APIs
#
# Revision
#   $Revision: #3 $ - $Date: 2008/08/08 $
#
# Author
#   Raffaele Sena
#
# Copyright
#   ADOBE SYSTEMS INCORPORATED
#     Copyright 2007 Adobe Systems Incorporated
#     All Rights Reserved.
#
#   NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
#   terms of the Adobe license agreement accompanying it.  If you have received this file from a 
#   source other than Adobe, then your use, modification, or distribution of it requires the prior 
#   written permission of Adobe.
#
from google.appengine.api import urlfetch
import lccs

def gae_http_get(url, headers = None):
  """
  implementation of lccs.http_get
  """
  if headers == None: headers = {}
  if lccs.DEBUG:
    print "gae_http_get %s" % url
    print "  %s" % headers
  resp = urlfetch.fetch(url, None, urlfetch.GET, headers)
  if resp.status_code != 200:
    raise lccs.error(resp.status_code)
  else:
    return resp.content

def gae_http_post(url, data, headers = None):
  """
  implementation of lccs.http_post
  """
  if headers == None: headers = {}
  if lccs.DEBUG: 
    print "gae_http_get %s" % url
    print "  %s" % data
    print "  %s" % headers
  resp = urlfetch.fetch(url, data, urlfetch.POST, headers)
  if resp.status_code != 200:
    raise lccs.error(resp.status_code)
  else:
    return resp.content

def use_gae():
  """
  call use_gae() to configure the lccs module to use GAE urlfetch API
  """
  lccs.http_get = gae_http_get
  lccs.http_post = gae_http_post

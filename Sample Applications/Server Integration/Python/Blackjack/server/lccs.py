#!env python

#
# Adobe LiveCycle Collaboration Service Account Management API
#
# Revision
#   $Revision: #1 $ - $Date: 2010/07/19 $
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

import httplib, urllib, re
import hashlib, hmac
import logging
from urlparse import urlsplit, urljoin
from xml.dom.minidom import parseString
from xml.sax.saxutils import escape
from base64 import standard_b64encode
from datetime import datetime
from cookielib import iso2time

DEBUG = False
VERSION = "$Revision: #1 $ - $Date: 2010/07/19 $"

class error(Exception):
  """
  RTC error
  """

  def __init__(self, value):
    self.value = value
  def __str__(self):
    return repr(self.value)

class userrole:
  """
  constants for common user roles
  """
  NONE      = 0
  LOBBY     = 5
  VIEWER    = 10
  PUBLISHER = 50
  OWNER     = 100

class nodeconfiguration:
  """
  constants for node configuration
  """
  STORAGE_SCHEME_SINGLE_ITEM = 0
  STORAGE_SCHEME_QUEUE       = 1
  STORAGE_SCHEME_MANUAL      = 2

def __http_get(url, headers = None):
  """
  local http_get, with support for redirects
  """

  if headers == None:
    headers = {}

  while True:
    if DEBUG:
      logging.info("http_get %s", url)
      logging.info("  %s", headers)

    uri = urlsplit(url)
    if uri.scheme == "https":
      if uri.port == 443:
        port=None
      else:
        port=uri.port
      conn = httplib.HTTPSConnection(uri.hostname, port)
    else:
      if uri.scheme == "http" and uri.port == 80:
        port=None
      else:
        port=uri.port
      conn = httplib.HTTPConnection(uri.hostname, port)
    conn.request("GET", "%s?%s" % (uri.path, uri.query), None, headers)
    resp = conn.getresponse()
    data = resp.read()
    conn.close()

    if resp.status == httplib.FOUND:
      redir = resp.getheader('location')
      if redir != url:
        url = redir
        continue
    
    break

  if resp.status != httplib.OK:
    raise error(resp.status)
    
  return data

def __http_post(url, data, headers=None):
  """
  local http_post. redirects are errors
  """

  uri = urlsplit(url)
  if type(data) == str or type(data) == unicode:
    params = data
  else:
    params = urllib.urlencode(data)

  if headers is None:
    headers = {}
  else:
    headers = headers.copy()

  if not headers.has_key("Content-Type"):
    headers["Content-Type"] = "application/x-www-form-urlencoded";
  if not headers.has_key("Accept"):
    headers["Accept"] = "text/*"
    
  if DEBUG:
    logging.info("http_post %s", url)
    logging.info("  %s", params)
    logging.info("  %s", headers)

  if uri.scheme == "https":
    if uri.port == 443:
      port=None
    else:
      port=uri.port
    conn = httplib.HTTPSConnection(uri.hostname, port)
  else:
    if uri.scheme == "http" and uri.port == 80:
      port=None
    else:
      port=uri.port
    conn = httplib.HTTPConnection(uri.hostname, port)

  conn.request("POST", "%s?%s" % (uri.path, uri.query), params, headers)
  resp = conn.getresponse()
  data = resp.read()
  conn.close()

  if resp.status != httplib.OK:
    raise error(resp.status)
    
  return data

def iso2datetime(s):
  """
  convert an ISO8601 formatted string to datetime
  """
  if s == None or s == 'NULL' or s == 'null' or s == '':
    return None
  s = re.sub(r'\.[0-9]+', '', s)
  return datetime.fromtimestamp(iso2time(s))

def check_status(response):
  status = response.getElementsByTagName('status')[0]
  code = status.attributes['code'].value
  if code == 'ok':
    return code
  if status.hasAttribute('subcode'):
    raise error(status.attributes['subcode'].value)
  else: 
    raise error(code)

def getElementValue(ele, name):
  return ele.getElementsByTagName(name)[0].childNodes[0].data

def getElementValueDate(ele, name):
  value = getElementValue(ele, name)
  if value == 'NULL' or value == 'null' or value == '':
    return None
  #Sun Mar 28 18:04:45 EDT 2010
  value = value.replace(' EDT ',' ').replace(' EST ',' ') # for now remove timezone
  value = value.replace(' PDT ',' ').replace(' PST ',' ') # for now remove timezone
  return datetime.strptime(value, "%a %b %d %H:%M:%S %Y")

def getRole(role):
  role = role.lower()
  if role == "none":
    return userrole.NONE
  elif role == "lobby":
    return userrole.LOBBY
  elif role == "viewer":
    return userrole.VIEWER
  elif role == "publisher":
    return userrole.PUBLISHER
  elif role == "owner":
    return userrole.OWNER
  elif role.isdigit():
    return int(role)
  else:
    raise error("invalid-role")
  
def fromXML(xml):
  hash = {}
  
  for e in xml:
    if e.tagName == 'item':
      name = e.getAttribute('id')
      value = fromXML(e.childNodes)
    else:
      value = None
      
      if e.tagName == 'field':
        name = e.getAttribute('var')  # field
      else:
        name = e.getAttribute('name')  # property
        
      v = e.getElementsByTagName('value')
      if v.length > 0:
        v = v[0]
        type = v.getAttribute('type')
        
        if v.hasChildNodes() and hasattr(v.childNodes[0], 'data'):
          value = v.childNodes[0].data
    
        if type == 'boolean':
          value = (value == "true")
        elif type == 'int' or type == 'long':
          value = int(value)
        elif type == 'double':
          value = float(value)
        elif type == 'xml':
          value = parseString(value).documentElement
        elif type == 'object':
          value = fromXML(v.childNodes)
        elif type == 'array':
          value = fromXML(v.childNodes)
           
    hash[name] = value
    
  return hash
  
def toXML(hash, root=None):
  result = ""

  if root:
    if root == 'item':
      if 'itemID' in hash:
        id = hash['itemID']
      else:
        id = 'item'
      result += "<%s id=\"%s\">" % (root, id)
    else:
      result += "<%s>" % root

  if isinstance(hash, dict):
    enum = hash.iteritems()
    if root == 'configuration':
      ele = 'field'
      attr = 'var'
    else:
      ele = 'property'
      attr = 'name'
  else:
    enum = enumerate(hash)
    ele = 'item'
    attr = 'index'

  for name,value in enum:
    result += "<%s %s=\"%s\">" % (ele, attr, name)

    if value == None:
	    value = ''

    if isinstance(value, bool):
      type = "boolean"
    elif isinstance(value, int):
      type = "int"
    elif isinstance(value, long):
      type = "long"
    elif isinstance(value, float):
      type = "double"
    elif isinstance(value, str) or isinstance(value, unicode):
      type = "string"
    elif isinstance(value, dict):
      type = "object"
    elif isinstance(value, list):
      type = "array"
    else:
      #type = "undefined:%s" % type(value)
      type = "undefined"

    result += "<value type=\"%s\">" % type

    if isinstance(value, dict) or isinstance(value, list):
      result += toXML(value)
    elif isinstance(value, str) or isinstance(value, unicode):
      result += escape(value)
    else:
      result += str(value)

    result += "</value>"
    result += "</%s>" % ele

  if root:
    result += "</%s>" % root
      
  return result

class authenticator:
  """
  a class that generates RTC authentication tokens
  """

  __authURL = None

  def __init__(self, url):
    self.__authURL = url

  def login(self, user, password, headers = None):
    """
    Get an RTC authentication token give login and password.
    """

    if headers == None:
      headers = {}
    else:
      headers = headers.copy()

    headers.update({ "Content-Type" : "text/xml" })
    data = "<request><username>%s</username><password>%s</password></request>"\
      % (user, password)
    
    resp = http_post(self.__authURL, data, headers)

    result = parseString(resp).documentElement
    if result.attributes['status'].value == "ok":
      tok = result.getElementsByTagName('authtoken')[0]
      auth = tok.childNodes[0].data
      type = tok.attributes['type'].value
      if type == "COOKIE":
        return "", { "Cookie" : auth }
      else:
        return "gak=%s" % standard_b64encode(auth), {}
      end
    else:
      raise error(resp)

  def guestLogin(self, user):
    """
    Get a guest authentication token.
    """
    return "guk=%s" %  standard_b64encode("g:%s:" % user)
  
class item:
  """
  A class that contains room or template item information.
  """

  def __init__(self, name, desc, created = None):
    self.name = name
    self.desc = desc
    self.created = iso2datetime(created)
    
  def __str__(self):
    return "%s %s %s", (self.name, self.desc, self.created)

class roominfo:
  """
  A class that contains room session info
  """
  isConnected = False
  userCount = 0
  bytesUp = 0
  bytesDown = 0
  messages = 0
  peakUsers = 0
  dateCreated = None
  dateStarted = None
  dateEnded = None
  dateExpired = None
  
  def __str__(self):
    return "{isConnected:%s, userCount:%d, bytesUp:%d, bytesDown:%d, messages:%d, peakUsers:%d, dateCreated:%s, dateStarted:%s, dateEnded:%s, dateExpired:%s}" % (self.isConnected, self.userCount, self.bytesUp, self.bytesDown, self.messages, self.peakUsers, self.dateCreated, self.dateStarted, self.dateEnded, self.dateExpired)

class accountinfo:
  """
  A class that contains account session info
  """
  userCount = 0
  bytesUp = 0
  bytesDown = 0
  messages = 0
  peakUsers = 0
  userTime = None
  dateCreated = None
  dateExpired = None
  activeRooms = None

  def __str__(self):
    return "{userCount:%d, bytesUp:%d, bytesDown:%d, messages:%d, peakUsers:%d, userTime:%s, dateCreated:%s, dateExpired:%s}" % (self.userCount, self.bytesUp, self.bytesDown, self.messages, self.peakUsers, self.userTime, self.dateCreated, self.dateExpired)

class session:
  """
  a class that manages meeting sessions and external authentication
  """

  def __init__(self, instance, account, room):
    self.__instance = instance.replace('#room#', room)
    self.__account = account
    self.__room = room

  def getAuthenticationToken(self, accountSecret, name, id, role):
    """
    get an external authentication token
    """
    if (not type(role) is int) or role < userrole.NONE or role > userrole.OWNER:
      raise error("invalid-role")
    token = "x:%s::%s:%s:%s:%s" % (name, self.__account, id, self.__room, role)
    signed = "%s:%s" % (token, self.__sign(accountSecret, token))

    # unencoded
    #return "ext=%s" % signed

    # encoded
    return "exx=%s" % standard_b64encode(signed)

  def getUserID(id):
    """
    get the userId that the server will generate for this user
    """
    return ("EXT-%s-%s" % (self.__account, id)).upper()

  def getSecret(self, baseURL, authToken, authHeaders):
    data = http_get("%sapp/session?instance=%s&%s" % (baseURL, self.__instance, authToken), authHeaders)

    if DEBUG: logging.info(data)

    response = parseString(data).documentElement
    self.__secret = getElementValue(response, "session-secret")

  def invalidate(self, baseURL, authToken, authHeaders):
    data = "action=delete&instance=%s&%s" % (self.__instance, authToken)
    resp = http_post("%sapp/session" % baseURL, data, authHeaders)
    if DEBUG: logging.info(resp)


    self.__instance = None
    self.__account = None
    self.__room = None
    self.__secret = None
    response = parseString(resp).documentElement
    return check_status(response)
 
  def __sign(self, acctSecret, data):
    secret = "%s:%s" % (acctSecret, self.__secret)
    mac = hmac.new(secret.encode('utf-8'), data.encode('utf-8'), hashlib.sha1)
    return mac.hexdigest()

class accountmanager:
  """
  a class that deals with account information and provisioning
  """

  ROOM_ITEMS     = "meetings"
  TEMPLATE_ITEMS = "templates"

  def __contentURL(self):
    return "%sapp/content%s" % (self.__baseURL, self.__contentPath)

  def __init__(self, url):
      self.url = url
      self.__authToken = None
      self.__authHeaders = None
      self.__authenticator = None
      self.__baseURL = None
      self.__contentPath = None
      self.__roomInstance = None

      logging.info(VERSION)

      self.__initialize()

  def login(self, user, password=None):
      """
      login method
      """

      if password != None:
        self.__authToken, self.__authHeaders = self.__authenticator.login(user, password)
      else:
        self.__authToken = self.guestLogin(user)

      self.__initialize()

  def keepalive(self, user=None, password=None):
      """
      keep the authentication token alive by accessing the account.
      """
      self.__contentPath = None
      if self.__initialize(): return True
      if user != None: self.login(user, password)
      return False

  def createRoom(self, room, template=None):
    """
    create a room
    """

    if template == None: template = "default"
    data = "mode=xml&room=%s&template=%s&%s" % (room, template, self.__authToken)
    resp = http_post(self.url, data, self.__authHeaders)
    if DEBUG: logging.info(resp)

    info = parseString(resp).documentElement
    if info.tagName != 'meeting-info':
      raise error(resp)
    else:
      return "ok"

  def list(self, type=None):
    """
    list rooms or templates
    """

    if type == None:
      type = ROOM_ITEMS
    elif type != accountmanager.TEMPLATE_ITEMS and type != accountmanager.ROOM_ITEMS:
      raise error("invalid-type")

    data = http_get("%s/%s/?%s" % (self.__contentURL(), type, self.__authToken), self.__authHeaders)

    if DEBUG: logging.info(data)

    response = parseString(data).documentElement
    children = response.getElementsByTagName('children')
    if not children:
      return []

    nodes = children[0].getElementsByTagName('node')
    items = []

    for n in nodes[:]:
      name = getElementValue(n, 'name')
      desc = None
      created = None
      props = n.getElementsByTagName('properties')[0].getElementsByTagName('property')
      for p in props[:]:
        if p.attributes['name'].value == "cr:description":
          desc = getElementValue(p, 'value')
        elif p.attributes['name'].value == "jcr:created":
          created = getElementValue(p, 'value')
    
        items.append(item(name, desc, created))

    return items

  def delete(self, item, type=None, list=False):
    """
    delete a room or a template
    """

    if type == None:
      type = accountmanager.ROOM_ITEMS
    elif type != accountmanager.TEMPLATE_ITEMS and type != accountmanager.ROOM_ITEMS:
      raise error("invalid-type")
      
    if list:
      limitCount = ""
    else:
      limitCount = "&count=0"

    url = "%s/%s/%s" % (self.__contentURL(), type, item)
    data = "action=delete&response=inline%s&%s" % (limitCount, self.__authToken)
      
    return http_post(url, data, self.__authHeaders)

  def listRooms(self):
    """
    list rooms
    """

    return self.list(accountmanager.ROOM_ITEMS)

  def listTemplates(self):
    """
    list templates
    """

    return self.list(accountmanager.TEMPLATE_ITEMS)

  def deleteRoom(self, r, list=False):
    """
    delete a room
    """
    if r == None:
      raise error("parameter-required")
      
    return self.delete(r.lower(), accountmanager.ROOM_ITEMS, list)

  def deleteTemplate(self, t, list=False):
    """
    delete a template
    """
    if t == None:
      raise error("parameter-required")

    return self.delete(t, accountmanager.TEMPLATE_ITEMS, list)

  def getSession(self, room):
    """
    return a room session for external authentication
    """
    sess = session(self.__roomInstance, self.url.split("/")[-1], room)
    sess.getSecret(self.__baseURL, self.__authToken, self.__authHeaders)
    return sess

  def invalidateSession(self, session):
    """
    invalidate room session
    """
    return session.invalidate(self.__baseURL, self.__authToken, self.__authHeaders)

  def getNodeConfiguration(self, room, coll, node):
    """
    Return the node configuration
    """
    instance = self.__roomInstance.replace('#room#', room)
    path = "/%s/nodes/%s/configuration" % (coll, node)
    resp = http_get("%sapp/rtc?instance=%s&path=%s&%s" % (self.__baseURL, instance, path, self.__authToken), self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    check_status(response)

    # /collections/node[@id='coll']/collection/nodes/node[@id='node']/collection/configuration
    
    nl = response.getElementsByTagName("node")    
    if nl.length < 1 or nl[0].getAttribute("id") != coll:
      raise error("invalid-collection")

    if nl.length < 2 or nl[1].getAttribute("id") != node:
      raise error("invalid-node")

    return fromXML(nl[1].getElementsByTagName("configuration")[0].childNodes)
      
  def fetchItems(self, room, coll, node, items=None):
    """
    Return the RTC nodes @ path.
    """
    instance = self.__roomInstance.replace('#room#', room)
    params = "instance=%s&collection=%s&node=%s" % (instance, coll, node)
    if items != None:
      if not hasattr(items, '__iter__'):
        items = [ items ]
      for i in items: 
        params += ("&item=%s" % i)
    params += ("&%s" % self.__authToken)

    resp = http_get("%sapp/rtc?%s" % (self.__baseURL, params), self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    check_status(response)

    # /collections/node[@id='coll']/collection/nodes/node[@id='node']/collection/items

    nl = response.getElementsByTagName("node")    
    if nl.length < 1 or nl[0].getAttribute("id") != coll:
      raise error("invalid-collection")

    if nl.length < 2 or nl[1].getAttribute("id") != node:
      raise error("invalid-node")

    return fromXML(nl[1].getElementsByTagName("items")[0].childNodes)

  def registerHook(self, endpoint=None, token=None):
    """
    Register endpoint URL for webhooks
    """
    acctid = self.__roomInstance.split("/")[0]
    data = "account=%s&action=registerhook" % acctid
    if endpoint:
      data += "&endpoint=%s" % urllib.quote_plus(endpoint)
    if token:
      data += "&token=%s" % urllib.quote_plus(token)
    data += "&%s" % self.__authToken
    resp = http_post("%sapp/rtc" % self.__baseURL, data, self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def unregisterHook(self):
    """
    Unregister endpoint URL for webhooks
    """
    return self.registerHook()

  def getHookInfo(self):
    """
    Return the webhook information
    """
    acctid = self.__roomInstance.split("/")[0]
    resp = http_get("%sapp/rtc?action=hookinfo&account=%s&%s" % (self.__baseURL, acctid, self.__authToken), self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    check_status(response)

    result = {}
    
    params = response.getElementsByTagName("param")
    for p in params:
      name = p.getAttribute("name")
      if p.hasChildNodes():
        value = p.childNodes[0].data
      else:
        value = None
      if name == 'registerHookEndpoint':
        result['endpoint'] = value
      elif name == 'registerHookToken':
        result['token'] = value

    return result
      
  def subscribeCollection(self, room, collection, nodes=None):
    """
    Subscribe to collection events
    """
    instance = self.__roomInstance.replace('#room#', room)
    params="collection=%s" % collection
    if nodes != None:
      if not hasattr(nodes, '__iter__'):
        nodes = [ nodes ]
      for n in nodes: 
        params += ("&node=%s" % n)
    data = "instance=%s&action=subscribe&%s&%s" % (instance, params, self.__authToken)
    resp = http_post("%sapp/rtc" % self.__baseURL, data, self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def unsubscribeCollection(self, room, collection, nodes=None):
    """
    Unsubscribe to collection events
    """
    instance = self.__roomInstance.replace('#room#', room)
    params="collection=%s" % collection
    if nodes != None:
      if not hasattr(nodes, '__iter__'):
        nodes = [ nodes ]
      for n in nodes: 
        params += ("&node=%s" % n)
    data = "instance=%s&action=unsubscribe&%s&%s" % (instance, params, self.__authToken)
    resp = http_post("%sapp/rtc" % self.__baseURL, data, self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def publishItem(self, room, collection, node, item, overwrite = False):
    """
    Publish an item
    """
    instance = self.__roomInstance.replace('#room#', room)
    headers = { "Content-Type" : "text/xml" }
    headers.update(self.__authHeaders)

    params = "instance=%s&action=publish&collection=%s&node=%s" % (instance, collection, node)
    if overwrite:
      params += "&overwrite=true"
    params += "&%s" % self.__authToken
    data = "<request>" + toXML(item, "item") + "</request>"
    resp = http_post("%sapp/rtc?%s" % (self.__baseURL, params), data, headers)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def retractItem(self, room, collection, node, item):
    """
    Retract an item
    """
    instance = self.__roomInstance.replace('#room#', room)

    data = "instance=%s&collection=%s&node=%s&item=%s&%s" % (instance, collection, node, item, self.__authToken)
    resp = http_post("%sapp/rtc" % self.__baseURL, data, self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def createNode(self, room, collection, node, configuration=None):
    """
    Create a node
    """
    instance = self.__roomInstance.replace('#room#', room)

    params = "instance=%s&action=configure&collection=%s&node=%s&%s" % (instance, collection, node, self.__authToken)

    if configuration:
      headers = { "Content-Type" : "text/xml" }
      headers.update(self.__authHeaders)

      data = "<request>" + toXML(configuration, "configuration") + "</request>"
      resp = http_post("%sapp/rtc?%s" % (self.__baseURL, params), data, headers)
    else:
      resp = http_post("%sapp/rtc" % self.__baseURL, params, self.__authHeaders)

    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def removeNode(self, room, collection, node=None):
    """
    Remove a node or collection
    """
    instance = self.__roomInstance.replace('#room#', room)
    data = "instance=%s&action=remove&collection=%s" % (instance, collection)
    if node:
      data += "&node=%s" % node
    data += "&%s" % self.__authToken
    resp = http_post("%sapp/rtc" % self.__baseURL, data, self.__authHeaders)

    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def setNodeConfiguration(self, room, collection, node, configuration):
    """
    Configure a node
    """
    instance = self.__roomInstance.replace('#room#', room)
    params = "instance=%s&action=configure&collection=%s&node=%s&%s" % (instance, collection, node, self.__authToken)

    headers = { "Content-Type" : "text/xml" }
    headers.update(self.__authHeaders)

    data = "<request>" + toXML(configuration, "configuration") + "</request>"
    resp = http_post("%sapp/rtc?%s" % (self.__baseURL, params), data, headers)

    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def setUserRole(self, room, user, role, collection=None, node=None):
    """
    Set user role
    """
    instance = self.__roomInstance.replace('#room#', room)
    data = "instance=%s&action=setrole&user=%s&role=%d" % (instance, user, int(role))

    if collection:
      data += "&collection=%s" % collection
    if node:
      data += "&node=%s" % node
    
    data += "&%s" % self.__authToken
    resp = http_post("%sapp/rtc" % self.__baseURL, data, self.__authHeaders)

    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    return check_status(response)

  def getAccountInfo(self):
    """
    return information about the account, if active
    """
    acctid = self.__roomInstance.split("/")[0]
    resp = http_get("%sapp/account?account=%s&%s" % (self.__baseURL, acctid, self.__authToken), self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    check_status(response)
    
    info = response.getElementsByTagName('account-info')[0]
    ainfo = accountinfo()
    ainfo.userCount    = int(getElementValue(info, 'user-count'))
    ainfo.bytesUp      = int(getElementValue(info, 'total-bytes-up'))
    ainfo.bytesDown    = int(getElementValue(info, 'total-bytes-down'))
    ainfo.messages     = int(getElementValue(info, 'total-messages'))
    ainfo.peakUsers    = int(getElementValue(info, 'peak-user-count'))
    ainfo.userTime     = iso2time(getElementValue(info, 'total-time'))
    ainfo.dateCreated  = getElementValueDate(info, 'date-created')
    ainfo.dateExpired  = getElementValueDate(info, 'date-expired')
    return ainfo

  def getRoomInfo(self, room):
    """
    return information about the room/instance, if active
    """
    if room.rfind('/') >= 0:
      instance = room
    else:
      instance = self.__roomInstance.replace('#room#', room)
      
    resp = http_get("%sapp/account?instance=%s&%s" % (self.__baseURL, instance, self.__authToken), self.__authHeaders)
    if DEBUG: logging.info(resp)

    response = parseString(resp).documentElement
    check_status(response)

    info = response.getElementsByTagName('meeting-info')[0]
    rinfo = roominfo()
    rinfo.isConnected  = getElementValue(info, 'is-connected') == 'true'
    rinfo.userCount    = int(getElementValue(info, 'user-count'))
    rinfo.bytesUp      = int(getElementValue(info, 'total-bytes-up'))
    rinfo.bytesDown    = int(getElementValue(info, 'total-bytes-down'))
    rinfo.messages     = int(getElementValue(info, 'total-messages'))
    rinfo.peakUsers    = int(getElementValue(info, 'peak-users'))
    rinfo.dateCreated  = getElementValueDate(info, 'date-created')
    rinfo.dateStarted  = getElementValueDate(info, 'date-started')
    rinfo.dateEnded    = getElementValueDate(info, 'date-ended')
    rinfo.dateExpired  = getElementValueDate(info, 'date-expired')
    return rinfo

  def __initialize(self):
    if self.__contentPath: return True

    data = http_get("%s?mode=xml&accountonly=true&%s" % (self.url, self.__authToken), self.__authHeaders)

    try:
      response = parseString(data).documentElement
    except:
      raise error("invalid-room")

    if response.tagName == 'meeting-info':
      self.__baseURL = response.getElementsByTagName("baseURL")[0].attributes['href'].value
      self.url = urljoin(self.__baseURL, urlsplit(self.url).path)
      self.__contentPath = response.getElementsByTagName("accountPath")[0].attributes['href'].value
      if len(response.getElementsByTagName("room")) > 0:
        self.__roomInstance = response.getElementsByTagName("room")[0].attributes['instance'].value
      return True

    elif response.tagName == 'result':
      if response.attributes['code'].value == "unauthorized":
        if len(response.getElementsByTagName("baseURL")) > 0:
          self.__baseURL = response.getElementsByTagName("baseURL")[0].attributes['href'].value
          self.url = urljoin(self.__baseURL, urlsplit(self.url).path)

        authURL = response.getElementsByTagName("authentication")[0].attributes['href'].value
        if authURL.startswith('/'):
          authURL = urljoin(self.__baseURL, authURL)

        self.__authenticator = authenticator(authURL)
        return False
      else:
        raise error(data)

    else:
       raise error(data)

http_get = __http_get
http_post = __http_post

if __name__ == "__main__":
  import sys

  def usage():
    print "usage: %s [--debug] [--host=url] account user password command parameters..." % sys.argv[0]
    print ""
    print "where <command> is:"
    print "    --list"
    print "    --create room [template]"
    print "    --delete room"
    print "    --delete-template template"
    print "    --ext-auth secret room username userid role"
    print "    --invalidate room"
    print ""
    print "    --get-node-configuration room collection node"
    print "    --fetch-items room collection node"
    print "    --register-hook endpoint [token]"
    print "    --unregister-hook"
    print "    --hook-info"
    print "    --subscribe-collection room collection"
    print "    --unsubscribe-collection room collection"
    print "    --create-node room collection [node]"
    print "    --remove-node room collection [node]"
    print "    --set-user-role room userID role [collection [node]]"
    print "    --publish-item room collection node itemID body"
    print "    --retract-item room collection node itemID"
    exit(1)

  #DEBUG = True
  HOST = "http://connectnow.acrobat.com"

  args = sys.argv[1:]
 
  #
  # parse options
  #
  while args and args[0].startswith('-'):
    p = args[0]

    if p.startswith('--host='): 
      HOST = p[7:]
    elif p == "--debug":
      DEBUG = True

    else:
      print "invalid option %s\n" % p
      args = []
      break

    args = args[1:]

  n = len(args)

  if n < 3:
    usage()

  if DEBUG: logging.getLogger().setLevel(logging.DEBUG)
   
  account = "%s/%s" % (HOST, args[0])
  user = args[1]
  password = args[2]

  am = accountmanager(account)
  am.login(user, password)

  args = args[3:]

  if len(args) == 0 or args[0] == "--list":
    print "==== templates ========================="
    for i in am.listTemplates()[:]:
      print "%s:%s" % (i.name, i.created)

    print "==== rooms ============================="
    for i in am.listRooms()[:]:
      print "%s:%s:%s" % (i.name, i.desc, i.created)

  elif args[0] == "--create":
    #
    # create room
    #
    template = None
    if len(args) > 2: template = args[2]
    print am.createRoom(args[1], template)

  elif args[0] == "--delete":
    #
    # delete room
    #
    print am.deleteRoom(args[1])

  elif args[0] == "--delete-template":
    #
    # delete template
    #
    print am.deleteTemplate(args[1])

  elif args[0] == "--ext-auth":
    #
    # get session and create external auth tokens
    #
    if len(args) > 5:
      role = getRole(args[5])
    else:
      role = userrole.LOBBY
    sess = am.getSession(args[2])
    print sess.getAuthenticationToken(args[1], args[3], args[4], role)

  elif args[0] == "--invalidate":
    sess = am.getSession(args[1])
    am.invalidateSession(sess)

  elif args[0] == "--info":
    #
    # Get account or room session information.
    #
    if len(args) == 1:
      print am.getAccountInfo()

    else:
      print am.getRoomInfo(args[1])

  elif args[0] == "--get-node-configuration":
    print am.getNodeConfiguration(args[1], args[2], args[3])

  elif args[0] == "--fetch-items":
    print am.fetchItems(args[1], args[2], args[3])

  elif args[0] == "--register-hook":
    if len(args) > 2:
      print am.registerHook(args[1], args[2])
    else:
      print am.registerHook(args[1])
    
  elif args[0] == "--unregister-hook":
    print am.unregisterHook()
    
  elif args[0] == "--hook-info":
    print am.getHookInfo()
    
  elif args[0] == "--subscribe-collection":
    if len(args) > 3:
      print am.subscribeCollection(args[1], args[2], args[3])
    else:
      print am.subscribeCollection(args[1], args[2])
    
  elif args[0] == "--unsubscribe-collection":
    if len(args) > 3:
      print am.unsubscribeCollection(args[1], args[2], args[3])
    else:
      print am.unsubscribeCollection(args[1], args[2])
    
  elif args[0] == "--publish-item":
    print am.publishItem(args[1], args[2], args[3], { 'itemID' : args[4], 'body' : args[5] })

  elif args[0] == "--retract-item":
    print am.retractItem(args[1], args[2], args[3], args[4])

  elif args[0] == "--create-node":
    print am.createNode(args[1], args[2], args[3])

  elif args[0] == "--remove-node":
    if len(args) > 3:
      print am.removeNode(args[1], args[2], args[3])
    else:
      print am.removeNode(args[1], args[2])
    
  elif args[0] == "--set-user-role":
    role = getRole(args[3])
    if len(args) > 5:
      print am.setUserRole(args[1], args[2], role, args[4], args[5])
    elif len(args) > 4:
      print am.setUserRole(args[1], args[2], role, args[4])
    else:
      print am.setUserRole(args[1], args[2], role)

  else:
    usage()

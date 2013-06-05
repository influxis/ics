#!/usr/bin/env python
#
# A simple application that can be hosted on Google AppEngine
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
import os
import cgi
import logging
import wsgiref.handlers
import pickle, base64
from xml.dom.minidom import parseString, getDOMImplementation

from datetime import datetime

from google.appengine.api import users
from google.appengine.ext import webapp, db
from google.appengine.ext.webapp import template

import lccs
import gae_http

class LoginPage(webapp.RequestHandler):
  def get(self):
    values = {
      'account' : "http://connectnow.acrobat.com/account",
      'username' : "username",
      'password' : "password"
    }

    templateWrite(self.response.out, 'login.html', values)

class MainPage(webapp.RequestHandler):
  def post(self):
    account = self.request.get('account')
    user = self.request.get('user')
    password = self.request.get('password')

    am = lccs.accountmanager(account)
    am.login(user, password)

    ctx = base64.standard_b64encode(pickle.dumps(am, -1))
    self.response.headers.add_header('Set-Cookie', "LCCS=%s" % ctx)

    templateWrite(self.response.out, 'main.html', { 'account' : am.url });

  def get(self):
    if not self.request.cookies.has_key("RTCCOOKIE"):
      self.redirect("/")
    else:
      ctx = self.request.cookies["RTCCOOKIE"]
      am = pickle.loads(base64.standard_b64decode(ctx))

      templateWrite(self.response.out, 'main.html', { 'account' : am.url });

class ListRooms(webapp.RequestHandler):
  def get(self):
    if not self.request.cookies.has_key("RTCCOOKIE"):
      self.redirect("/")
    else:
      ctx = self.request.cookies["RTCCOOKIE"]
      am = pickle.loads(base64.standard_b64decode(ctx))

      values = {
        'title' : "List Rooms",
        'headers' : [ "Room", "Template", "Created" ],
        'rows' : am.listRooms(),
        'create' : {
          'desc': "Create Room",
          'name': "room",
          'value': "room",
          'select': {
             'desc': "Template",
             'name': 'template',
             'options': self.templateOptions(am.listTemplates())
          }
        }
      }

      templateWrite(self.response.out, 'list.html', values)
    
  def post(self):
    if not self.request.cookies.has_key("RTCCOOKIE"):
      self.redirect("/")
    else:
      ctx = self.request.cookies["RTCCOOKIE"]
      am = pickle.loads(base64.standard_b64decode(ctx))

      if self.request.get('room'):
        room = self.request.get('room')
        template = self.request.get('template')
        if template == "": template = None

        am.createRoom(room, template)
        
      elif self.request.get('delete'):
        room = self.request.get('delete')
        am.deleteRoom(room)
          
      self.redirect("/rooms")

  def templateOptions(self, templates):
    options = map(self.makeOption, templates)
    options.insert(0, lccs.item('default', 'Default'))
    return options
    
  def makeOption(self, opt):
    if opt.desc == None: opt.desc = opt.name
    return opt

class ListTemplates(webapp.RequestHandler):
  def get(self):
    if not self.request.cookies.has_key("RTCCOOKIE"):
      self.redirect("/")
    else:
      ctx = self.request.cookies["RTCCOOKIE"]
      am = pickle.loads(base64.standard_b64decode(ctx))

      values = {
        'title' : "List Templates",
        'headers' : [ "Template", "Description", "Created" ],
        'rows' : am.listTemplates(),
      }

      templateWrite(self.response.out, 'list.html', values)

  def post(self):
    if not self.request.cookies.has_key("RTCCOOKIE"):
      self.redirect("/")
    else:
      ctx = self.request.cookies["RTCCOOKIE"]
      am = pickle.loads(base64.standard_b64decode(ctx))

    if self.request.get('delete'):
      template = self.request.get('delete')
      am.deleteTemplate(template)

    self.redirect("/templates")

class ChatPage(webapp.RequestHandler):
  def get(self):       
    if not self.request.cookies.has_key("RTCCOOKIE"):
      self.redirect("/")
    else:
      ctx = self.request.cookies["RTCCOOKIE"]
      am = pickle.loads(base64.standard_b64decode(ctx))

      data = self.getChatMessages(am, "mymeeting")
      
      values = {
        'title' : "Chat",
        'data': data.replace("&", "&amp;").replace("<", "&lt;")
      }

      templateWrite(self.response.out, 'chat.html', values)
      
  def getChatMessages(self, am, room):
    data = am.fetchItems("mymeeting", "2_SimpleChat", "history")
    response = parseString(data).documentElement
    if response.getElementsByTagName("status")[0].attributes['code'].value == "ok":
      doc = getDOMImplementation().createDocument(None, "items", None)
      for item in response.getElementsByTagName("item"):
        doc.documentElement.appendChild(item)
      return doc.toprettyxml()
    else:
      return response.toprettyxml()
    
application = webapp.WSGIApplication([
  ('/',          LoginPage),
  ('/main',      MainPage),
  ('/rooms',     ListRooms),
  ('/templates', ListTemplates),
  ('/chat',      ChatPage)
], debug=True)

def templateWrite(out, name, values):
  path = os.path.join(os.path.dirname(__file__), 'templates/', name)
  out.write(template.render(path, values))

def main():
  gae_http.use_gae()
  logging.getLogger().setLevel(logging.DEBUG)
  wsgiref.handlers.CGIHandler().run(application)


if __name__ == '__main__':
  main()

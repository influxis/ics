import sys
import logging
import traceback
import lccs
from lccs import nodeconfiguration, userrole
from pyamf.remoting.gateway.wsgi import WSGIGateway
from wsgiref import simple_server
from threading import Timer
from datetime import *
import bjgame

gameserver = None

# #########################################################################
# GAME LOGIC
class GameServer:
#  ACCOUNT       = "http://connectnow.acrobat.com/<SDKACCOUNT>"
#  USER          = "<SDKUSERNAME>"
#  PASSWORD      = "<SDKPASSWORD>"

  #
  # Note that this URL must be internet accessible
  #
#  PORT          = 8000
#  HOOKURL       = "http://<THISSERVER>:%d" % PORT

  ACCOUNT       = "http://localhost:8080/undef-pccsdk"
  USER          = "pccsdk"
  PASSWORD      = "pccsdk"
  PORT          = 8001
  HOOKURL       = "http://localhost:%d" % PORT

  ROOM          = "bj"

  COLLECTION    = u"Blackjack"
  NODE_DEALER   = u"dealer"
  NODE_PLAYERS  = u"players"
  NODE_STATE    = u"state"
  NODE_PLAY     = u"play"

  ROLE_PLAY     = 60
  ROLE_WAIT     = 10

  STATE_BET    = u"bet"
  STATE_PLAYER = u"play"
  STATE_DEALER = u"deal"

  PLAY_BET   = u"bet"
  PLAY_HIT   = u"hit"
  PLAY_STAND = u"stand"

  TIMEOUT = timedelta(minutes=5)

  am = None
  lastaccess = None
  state = None
  deck = None
  dealer = None
  players = {}

  def __init__(self):
    self.am = lccs.accountmanager(self.ACCOUNT)
    self.am.login(self.USER, self.PASSWORD)
    self.lastaccess = datetime.now()

    logging.info("connected...")

    try:
      self.am.removeNode(self.ROOM, self.COLLECTION, self.NODE_DEALER)
      self.am.removeNode(self.ROOM, self.COLLECTION, self.NODE_PLAYERS)
      self.am.removeNode(self.ROOM, self.COLLECTION, self.NODE_PLAY)
      self.am.removeNode(self.ROOM, self.COLLECTION, self.NODE_STATE)
    except lccs.error:
      # assume the error is because the room doesn't exists yet
      self.am.createRoom(self.ROOM)

    conf = { 
      'itemStorageScheme' : nodeconfiguration.STORAGE_SCHEME_SINGLE_ITEM,
      'publishModel'      : userrole.OWNER,
      'accessModel'       : userrole.VIEWER,
      'sessionDependentItems' : True
    }
    self.am.createNode(self.ROOM, self.COLLECTION, self.NODE_DEALER, conf)

    conf = {
      'itemStorageScheme' : nodeconfiguration.STORAGE_SCHEME_MANUAL,
      'publishModel'      : userrole.OWNER,
      'accessModel'       : userrole.VIEWER,
      'sessionDependentItems' : True
    }
    self.am.createNode(self.ROOM, self.COLLECTION, self.NODE_PLAYERS, conf)

    conf = { 
      'itemStorageScheme' : nodeconfiguration.STORAGE_SCHEME_SINGLE_ITEM, 
      'publishModel'      : self.ROLE_PLAY,
      'accessModel'       : userrole.VIEWER,
      'sessionDependentItems' : True
    }
    self.am.createNode(self.ROOM, self.COLLECTION, self.NODE_PLAY, conf)

    conf = {
      'itemStorageScheme' : nodeconfiguration.STORAGE_SCHEME_SINGLE_ITEM,
      'publishModel'      : userrole.OWNER,
      'accessModel'       : userrole.VIEWER,
      'sessionDependentItems' : True
    }
    self.am.createNode(self.ROOM, self.COLLECTION, self.NODE_STATE, conf)

    self.am.registerHook(self.HOOKURL)
    self.am.subscribeCollection(self.ROOM, "UserManager")
    self.am.subscribeCollection(self.ROOM, self.COLLECTION)

  def keepalive(self):
      t = datetime.now()
      delta = t - self.lastaccess
      if delta > self.TIMEOUT:
        logging.info("*** keepalive ***")
        self.am.keepalive(self.USER, self.PASSWORD)

      self.lastaccess = t

  def can_play(self, userID):
    return userID in self.players

  def add_player(self, room, userID, name):
    #
    # for now we only allow one player
    #
    if len(self.players) == 0:
      self.deck = bjgame.Deck(2)
      self.dealer = bjgame.Dealer()
      self.players[userID] = bjgame.Player(name)
      self.player_start(room, userID, name)

  def remove_player(self, room, userID):
    if userID in self.players:
      del self.players[userID]

    if len(self.players) == 0:
      #
      # Reset table
      #
      self.deck = bjgame.Deck(0)
      self.am.publishItem(room, self.COLLECTION, self.NODE_DEALER,
        { 'itemID' : 'item', 'body' : bjgame.Dealer().toVO(True) })
      self.am.retractItem(room, self.COLLECTION, self.NODE_PLAYERS, userID)
      self.send_state(room, None, "Table closed")

  def fetch_users(self, room):
    # in case some users are already connected
    logging.info("fetch users for %s", room)
    users = self.am.fetchItems(room, "UserManager", "UserList")
    for id,item in users.iteritems():
      receiveItem(0, room, "UserManager", item)

  def send_state(self, room, aState, message, userID=None, role=None):
    self.state = aState
    self.am.publishItem(room, self.COLLECTION, self.NODE_STATE, 
      { 'itemID' : 'item', 'body' : { 'state' : self.state, 'message' : message, 'cards' : self.deck.length() }})
    logging.info("state is now %s", self.state)

    if userID != None and role != None:
      self.am.setUserRole(room, userID, role, self.COLLECTION, self.NODE_PLAY)

  def new_round(self, room, userID):
    player = self.players[userID]

    self.dealer.newround()
    player.newround()

    # bet
    player.bet(5)

    # first card
    self.deck.deal_for(player)
    self.deck.deal_for(self.dealer)

    # second card
    self.deck.deal_for(player)
    self.deck.deal_for(self.dealer)

    # show cards
    self.am.publishItem(room, self.COLLECTION, self.NODE_DEALER,
      { 'itemID' : 'item', 'body' : self.dealer.toVO(True) })
    self.am.publishItem(room, self.COLLECTION, self.NODE_PLAYERS,
      { 'itemID' : userID, 'body' : player.toVO() })

    if player.isblackjack():
      return True
    else:
      self.send_state(room, self.STATE_PLAYER, '', userID, self.ROLE_PLAY)
      return False

  def deal_player(self, room, userID):
    player = self.players[userID]

    self.deck.deal_for(player)
    self.am.publishItem(room, self.COLLECTION, self.NODE_PLAYERS,
      { 'itemID' : userID, 'body' : player.toVO() })
    if player.total > 21:
      player.busted()
      self.dealer.win()
      self.am.publishItem(room, self.COLLECTION, self.NODE_DEALER,
        { 'itemID' : userID, 'body' : self.dealer.toVO() })
      self.send_state(room, self.STATE_BET, "%s busted!" % player.name)
      return False
    else:
      return (player.total==21)

  def deal_dealer(self, room, userID):
    player = self.players[userID]

    self.send_state(room, self.STATE_DEALER, '', userID, self.ROLE_WAIT)

    # unveil second card
    self.am.publishItem(room, self.COLLECTION, self.NODE_DEALER,
      { 'itemID' : 'item', 'body' : self.dealer.toVO() })

    while self.dealer.total < 17:
      self.deck.deal_for(self.dealer)
      self.am.publishItem(room, self.COLLECTION, self.NODE_DEALER,
        { 'itemID' : 'item', 'body' : self.dealer.toVO() })

    if self.dealer.total > 21:
      self.dealer.busted()
      player.win()
      message = '%s Busted!' % self.dealer.name
    elif self.dealer.total > player.total:
      self.dealer.win()
      message = '%s Win!' % self.dealer.name
    elif self.dealer.total == player.total:
      if self.dealer.isblackjack() and player.isblackjack():
        player.tie()
        message = "Tie!"
      elif player.isblackjack():
        player.win()
        message = '%s Win!' % player.name
      else:
        self.dealer.win()  
        message = '%s Win!' % self.dealer.name
    else:
      player.win()
      message = '%s Win!' % player.name

    # update player chips
    self.am.publishItem(room, self.COLLECTION, self.NODE_PLAYERS,
      { 'itemID' : userID, 'body' : player.toVO() })

    self.send_state(room, self.STATE_BET, message, userID, self.ROLE_PLAY)

  def player_start(self, room, userID, name):
    logging.info("starting player %s (%s)", name, userID)
    self.send_state(room, self.STATE_BET, "Please bet!", userID, self.ROLE_PLAY)

# #########################################################################
# RTC HOOKS

def receiveNode(token, room, collectionName, nodeName, configuration):
  logging.info("receiveNode %s %s %s %s %s" % (token, room, collectionName, nodeName, configuration))

def receiveNodeConfiguration(token, room, collectionName, nodeName, configuration):
  logging.info("receiveNodeConfiguration %s %s %s %s %s" % (token, room, collectionName, nodeName, configuration))

def receiveNodeDeletion(token, room, collectionName, nodeName ):
  logging.info("receiveNodeDeletion %s %s %s %s" % (token, room, collectionName, nodeName))

def receiveItem(token, room, collectionName, item):
  logging.info("receiveItem %s %s %s %s %s %s" % (token, room, collectionName, item['nodeName'], item['itemID'], item['body']))
  try:
    gameserver.keepalive()

    if collectionName == GameServer.COLLECTION and item['nodeName'] == GameServer.NODE_PLAY:
      switch = False
      userID = item['publisherID']
      cmd = item['body']

      if not gameserver.can_play(userID):
        logging.warn("### Invalid player %s %s", userID, cmd)
        return

      logging.info("*** PLAY %s %s", userID, cmd)

      if cmd == GameServer.PLAY_BET:
        logging.info("play BET");
        switch = gameserver.new_round(room, userID)

      elif gameserver.state != GameServer.STATE_PLAYER:
        logging.info("current state is %s", state)
        gameserver.send_state(room, GameServer.STATE_BET, "Please bet!")

      elif cmd == GameServer.PLAY_HIT:
        logging.info("play HIT");
        switch = gameserver.deal_player(room, userID)

      elif cmd == GameServer.PLAY_STAND:
        logging.info("play STAND");
        switch = True

      else:
        logging.info("invalid play command: %s", cmd)

      if switch:
        logging.info("*** PLAY DEALER");
        gameserver.deal_dealer(room, userID)

    elif collectionName == GameServer.COLLECTION and item['nodeName'] == GameServer.NODE_STATE:
      body = item['body']
      if gameserver.state != body['state']:
        logging.info("STATE %s, state node: %s", gameserver.state, body['state'])

    elif collectionName == "UserManager" and item['nodeName'] == "UserList":
      body = item['body']
      name = None
      if 'displayName' in body:
        name = body['displayName']
      if name==None or name=='':
        name = "Player"

      Timer(1, GameServer.add_player, [gameserver, room, body['userID'], name]).start()
  except Exception, e:
    logging.error(e)
    traceback.print_exc()

  logging.info("END receiveItem")

def receiveItemRetraction(token, room, collectionName, nodeName, item):
  logging.info("receiveItemRetraction %s %s %s %s %s" % (token, room, collectionName, nodeName, item['itemID']))
  try:
    if collectionName == "UserManager" and item['nodeName'] == "UserList":
      userID = item['itemID']
      gameserver.remove_player(room, userID)
  except Exception, e:
    logging.error(e)
    traceback.print_exc()
    
  logging.info("END receiveItemRetraction")

def receiveUserRole(token, room, collectionName, nodeName, userID, role):
  logging.info("receiveUserRole %s %s %s %s %s %s" % (token, room, collectionName, nodeName, userID, role))

services = {
  'RTCHOOKS.receiveNode'              : receiveNode,
  'RTCHOOKS.receiveNodeConfiguration' : receiveNodeConfiguration,
  'RTCHOOKS.receiveNodeDeletion'      : receiveNodeDeletion,
  'RTCHOOKS.receiveItem'              : receiveItem,
  'RTCHOOKS.receiveItemRetraction'    : receiveItemRetraction,
  'RTCHOOKS.receiveUserRole'          : receiveUserRole,
}

# #########################################################################
# MAIN APPLICATION

args = sys.argv[1:]

if len(args) > 0 and args[0] == "--debug":
  lccs.DEBUG = True

logging.basicConfig(level=logging.DEBUG, format="%(asctime)s - %(message)s")

gameserver = GameServer()
gameserver.fetch_users(GameServer.ROOM)

gw = WSGIGateway(services)

httpd = simple_server.WSGIServer(
  ('0.0.0.0', GameServer.PORT), 
  simple_server.WSGIRequestHandler,
)
httpd.set_app(gw)

try:
  # open for business
  sa = httpd.socket.getsockname()
  print "Running Blackjack server on ", sa[0], "port", sa[1], "..."
  httpd.serve_forever()
except KeyboardInterrupt:
  pass

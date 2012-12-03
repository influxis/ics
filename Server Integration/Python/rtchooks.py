import logging

# #########################################################################
# RTC HOOKS

def receiveNode(token, room, collectionName, nodeName, configuration):
  logging.info("receiveNode %s %s %s %s %s" % (token, room, collectionName, nodeName, configuration))

def receiveNodeConfiguration(token, room, collectionName, nodeName, configuration):
  logging.info("receiveNodeConfiguration %s %s %s %s %s" % (token, room, collectionName, nodeName, configuration))

def receiveNodeDeletion(token, room, collectionName, nodeName ):
  logging.info("receiveNodeDeletion %s %s %s %s" % (token, room, collectionName, nodeName))

def receiveItem(token, room, collectionName, item):
  logging.info("receiveItem %s %s %s %s" % (token, room, collectionName, item))

def receiveItemRetraction(token, room, collectionName, nodeName, item):
  logging.info("receiveItemRetraction %s %s %s %s %s" % (token, room, collectionName, nodeName, item))

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

if __name__ == '__main__':
  from pyamf.remoting.gateway.wsgi import WSGIGateway
  from wsgiref import simple_server

  logfile = "rtc.log"

  # uncommment to log to console
  #logfile = None

  logging.basicConfig(filename=logfile, level=logging.INFO, format="%(asctime)s - %(message)s")

  gw = WSGIGateway(services)

  httpd = simple_server.WSGIServer(
    ('0.0.0.0', 8000), 
    simple_server.WSGIRequestHandler,
  )
  httpd.set_app(gw)

  try:
    # open for business
    sa = httpd.socket.getsockname()
    print "Running RTCHOOKS gateway on", sa[0], "port", sa[1], "..."
    httpd.serve_forever()
  except KeyboardInterrupt:
    pass

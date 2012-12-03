/************************************************
* Adobe LCCS 2010-2011 
* Server To Server Python interface
* Version 1.0
*************************************************/

The "server to server" receiver module is available in the rtchooks.py file.
This module uses "pyamf" to decode the LCCS messages (sent as AMF-RPCs)

The easiest way to install pyamf is to use easy_install/setuptools (http://pypi.python.org/pypi/setuptools):

   easy_install pyamf

Once pyamf is installed you can simply execute the rtchooks.py file on an internet accessible machine. 
It will start a basic server on port 8000 and log the received messages in the file rtc.log.

At this point you can register a global "hook" for your LCCS account and then subscribe to specific collections
on the rooms you want to monitor. You can do this programmatically using the documented APIs or by running the lccs.py
module as a shell command:

  # register hook
  python lccs.py <accountname> <developer-email> <developer-password> --register-hook http://<rtchooks-server>:8000

  # subscribe to collection "RoomManager" for room "testroom"
  python lccs.py <accountname> <developer-email> <developer-password> --subscribe-collection "testroom" RoomManager

From now on, assuming your rtchooks server is running, when you run applications accessing your "testroom" room
you should receive notification every time a node is published or retracted on the collection "RoomManager"


In order to integrate the "server to server" receiver module with your web application, assuming you are using
a WSGI compliant server or another server supported by pyamf, simply copy the rtchooks.py file in your web application,
register the services in rtchooks.py with your web application, and add your logic to the method in the file.

For more information about pyamf please refer to the documentation at http://pyamf.org.

/************************************************
* Adobe LCCS 2010
* Server To Server Java Interface and Example
* Version 1.0
*
* The example shows how to use LCCS Server to Server API to invoke LCCS commands.  It also shows how to receive messages coming from LCCS room.
*
* following is the list of actions it can perform 
* 1) login  (e.g. http://<hostname>/samples/LCCS/LCCS.html)
* 2) register hook 
* 3) subscribe collection 
*
* To recieve room notifications:
*  When events are received, RTCHOOKS.java will print out those message via standard output. 
* 
* To get more information on the LCCS HTTP Server to Server API, visit ****
*************************************************/

Setup Procedure:

1) BlazeDS development guid: http://livedocs.adobe.com/blazeds/1/blazeds_devguide/
(this example use sampels.war from BlazeDS, if you use other war deployment, make sure you copy samples/WEB-INF/* <BACKUP YOUR OWN WEB-INF BEFORE COPY> to your WEB-INF directory and compile the src according to your path)

It is recommended use sample directory under webapps for this example. However, if your tomcat runs by default on webapps/ROOT folder and not the webapps/samples,then you should move everything under ROOT folder i.e. tomcat/webapps/samples/WEB-INF to tomcat/webapps/ROOT/WEB-INF.
In that case,you should replace samples with ROOT for every instruction below.

2) create LCCS directory (e.g. tomcat/webapps/samples/WEB-INF/src/flex/samples/LCCS, If it's ROOT, it should be  tomcat/webapps/ROOT/WEB-INF/src/flex/samples/LCCS)
3) copy RTCHOOKS.java and MySessionHandler.java from this example subdirectory (i.e. BlazeDSGateway_Java/tomcat/webapps/samples/WEB-INF/src/flex/samples/LCCS) to your LCCS directory created above.
4) and copy LCCS.jar from serverIntegration/java to the WEB-INF/lib directory

   WARNING: RTCHOOKS.java has example code embedded, it is different from the RTCHOOKS.java file under 
   the serverIntegration/java directory which is a more generic interface.

5) go to the samples directory under webapps. If using ROOT, go to ROOT directory under webapps.

6) javac -d WEB-INF/classes/ WEB-INF/src/flex/samples/LCCS/*.java -classpath WEB-INF/lib/LCCS.jar:WEB-INF/lib/flex-messaging-core.jar
(use ";" to separate jar file in you in windows)

7) find all the configuration for AMFEndpoint at tomcat/webapp/samples/WEB-INF/flex

8) overwrite your remoting-config.xml in your tomcat/webapp/samples/WEB-INF/flex with one in BlazeDSGateway_Java/tomcat/webapps/samples/WEB-INF/flex/
However, if you have your custom remoting-config.xml set up, you can update it with the following: (id="RTCHOOKS" is required as this is the destination to which LCCS will push hook notifications)
(if you use sample directory)

    <destination id="RTCHOOKS">
        <properties>
            <source>flex.samples.LCCS.RTCHOOKS</source>
        </properties>
    </destination>

    <destination id="LCCS" channels="my-amf">
        <properties>
            <source>com.adobe.rtc.account.AccountManager</source>
        </properties>
    </destination>

    <destination id="MySessionHandler" channels="my-amf">
        <properties>
            <source>flex.samples.LCCS.MySessionHandler</source>
        </properties>
        <adapter ref="java-object"/>
    </destination>

9) This example use flash client to invoke AccountManager methods (login, registerhook, gethookinfo, subscribeCollection).  
copy tomcat/webapp/samples/LCCS directory to your server or compile the WEB-INF/flex-src/flex-src/LCCS/src/LCCS.mxml  and copy the output to your tomcat directory. If you are compiling yourself, you should add flex compiler option -context-root "samples" -services "<path>/services-config.xml"   
    
10) launch LCCS.html in your browser and point to the LCCS account url. 

11) after login successful try to register hook and subscribe collection.  The events should go to your server log (e.g. catalina.out).
 hook info: http://<hostname>:8400/samples/messagebroker/amf. If using ROOT,http://<hostname>:8400/messagebroker/amf
 
12) In case you don't get any hooks error or subscribe error but still can't see the logs, check the logging tag inside services-config.xml. If the target level is set to "Error" . then set it to "Debug" or "All".
Similarly, if you see logs in the tomcat console but want to see it in a log file, change the target class from flex.messaging.log.ConsoleTarget to flex.messaging.log.ServletLogTarget. Refer to tomcat 
logging information for more details. http://livedocs.adobe.com/blazeds/1/blazeds_devguide/help.html?content=services_logging_3.html

 





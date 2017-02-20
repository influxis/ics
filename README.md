ics
===

Developer SDK and Documentation for the Influxis Collaborative Service (ICS)

Cocomo SDK Build Notes
===
The last official build was made with Flex SDK 3.2, however 3.6 *should* work as well. Flex SDK 4.5+ made major design changes and would require code changes on our part (notably the mxml Spark design changes).

### Flex SDK
[Flex SDK 3.6](http://download.macromedia.com/pub/flex/sdk/flex_sdk_3.6a.zip)

[Flex SDK 3.2](http://blogs.adobe.com/flex/files/2012/05/FlexLicense.swf?build=3.2.0.3958A&pkgtype=1)

After installing SDK create __FLEX_HOME__ environment variable pointing to base directory.

Additionally download and install playerglobal swc for Flash 10.3. Cocomo was originally built against this version (as the latest), newer versions should be fine as well.

[Flash 10.3 Player SWC](http://fpdownload.macromedia.com/get/flashplayer/installers/archive/playerglobal/playerglobal10_3.swc)

```Shell
mkdir -p "${FLEX_HOME}/frameworks/libs/player/10.3"
mv ~/Downloads/playerglobal10_3.swc "${FLEX_HOME}/frameworks/libs/player/10.3/playerglobal.swc"
```

### Ant
https://ant.apache.org/bindownload.cgi

Ant also required.
After installing set __ANT_HOME__ environment variable to base dir, and add the equivalent of "ANT_HOME/bin" to your __Path__ environment variable.

### Build
```Shell
cd ics/build/cocomoSDK
ant
```

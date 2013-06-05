1.) In Flash Builder, create a New Flex Project.
2.) Copy the contents of the jQuerier.mxml file provided into your application's mxml file (replace all of the code in there).
3.) Copy the files cursor.png & LCCS_JS_Bridge.js from the SDK's JavaScript library [<SDK_DIRECTORY>/com.adobe.lccs/libs/JavaScript] into the html-template directory of the Flex Project.
4.) Copy all the files inside the html-template folder provided into the html-template directory of the Flex Project.
5.) Download a Jquery Plugin called Tipsy from - http://plugins.jquery.com/project/tipsy (MIT license) and copy it to your html-template folder.
6.) Provide the project name, room URL, LCCS username & LCCS password inside index.template.html file at line 164 (inside the init function where the JQuery Plugin is called)

Note: Project Name in step 5 should be the name of the swf gnerated in bin-debug folder of your flex project. The generated swf is usually named after the name of mxml application file you created  in step 2.
/*
*
* ADOBE CONFIDENTIAL
* ___________________
*
* Copyright [2007-2010] Adobe Systems Incorporated
* All Rights Reserved.
*
* NOTICE:  All information contained herein is, and remains
* the property of Adobe Systems Incorporated and its suppliers,
* if any.  The intellectual and technical concepts contained
* herein are proprietary to Adobe Systems Incorporated and its
* suppliers and are protected by trade secret or copyright law.
* Dissemination of this information or reproduction of this material
* is strictly forbidden unless prior written permission is obtained
* from Adobe Systems Incorporated.
*/
package com.adobe.rtc.util
{
	import com.adobe.rtc.session.ConnectSession;

	/**
	 * Utility class for debugging.
	 * 
	 * 
	 */
   public class  DebugUtil
	{
	   
	   private static var _firstTrace:Boolean = false;
		//include "../core/Version.as";
		/**
		 * A custom trace function that can be defined by the developer. It can turned on and off using the <code>suppressDebugTraces</code>.
		 */ 
		public static var traceFunction:Function;
		
		/**
		 * A flag to turn on/off tracing. The flag is used in conjunction with the <code>debugTrace</code> method. The traces are turned off if true.
		 * @default false
		 */ 
		public static var suppressDebugTraces:Boolean = false;
		
		/**
		 * Takes an object and traces its content and the type of each member in a tree form.
		 * In additional to the two standard parameters, two optional parameters may be passed in:
		 * <ul>
		 * <li>A prefix to add to all traces; it's typically just "".</li>
		 * <li>A function that should be used for tracing instead of <code>trace</code>. For example, 
		 * this is useful if you'd like the output to go to a TextArea component.</li>
		 * </ul>
		 * 
		 * @param p_name The name of the object. 
		 * @param p_obj The object to trace. 
		 */
		
		public static function dumpObject(p_name:String, p_obj:Object, ...rest):void
		{
			var prefix:String = (rest.length == 0) ? "  " : rest[0];
			var f:Function = (rest.length == 2) ? rest[1] : trace;
			
			f(prefix+"."+p_name+" ["+typeof(p_obj)+"]");
			f(prefix+prefix+"\\\\");
			for (var i:* in p_obj) {
				if (typeof(p_obj[i]) == "object") {
					DebugUtil.dumpObject(i, p_obj[i], prefix+prefix, f);
				} else
					f(prefix+prefix+"."+i+" ["+typeof(p_obj[i])+"]= "+p_obj[i]);
			}
		}

		/**
		 * Similar to <code>dumpObject()</code> but it's not recursive, and it only traces 
		 * the first level of the object that's passed in. In additional to the two 
		 * standard parameters, two optional parameters may be passed in:
		 * <ul>
		 * <li>A prefix to add to all traces; it's typically just "".</li>
		 * <li>A function that should be used for tracing instead of <code>trace</code>. For example, 
		 * this is useful if you'd like the output to go to a TextArea component.</li>
		 * </ul>
		 * 
		 * @param p_name The name of the object. 
		 * @param p_obj The object to trace. 
		 */
		public static function dumpObjectShallow(p_name:String, p_obj:Object, ...rest):void
		{
			var prefix:String = (rest.length == 0) ? "  " : rest[0];
			var f:Function = (rest.length == 2) ? rest[1] : debugTrace;

			f(prefix+"."+p_name+" ["+typeof(p_obj)+"]");
			f(prefix+prefix+"\\\\");
			for (var i:* in p_obj) {
				f(prefix+prefix+"."+i+" ["+typeof(p_obj[i])+"]= "+p_obj[i]);
			}
		}
		
		/**
		 * A custom log function that can be turned on/off using the <code>suppressDebugTraces</code>. The traces are outputted only when <code>suppressDebugTraces</code> is false.
		 * The default trace() function is used if the <code>traceFunction</code> is not defined.
		 */ 
		public static function debugTrace(p_traceString:String):void
		{
			var now:Date = new Date();
			var dateStr:String;
			if (!_firstTrace) {
				_firstTrace = true;
				dateStr = now.toString() + "    ";
			} else {
				dateStr = now.toTimeString() + "    ";
			}
			if (!suppressDebugTraces) {
				if (traceFunction != null) {
					traceFunction(dateStr + p_traceString);
				} else {
					trace(dateStr + p_traceString);
				}
			}
		}
		
		
	}
}
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
    
    /** 
     * Implements the encode and decode routines as specified in ISO 9075-14:2003. 
     * If a character c is not valid at a certain position in an
     * XML name, it is encoded in the form: <code>'_x' + hexValueOf(c) + '_'</code>.
     */
   public class  ISO9075 
    {
         
        /** 
         *
         */
        private static const ENCODE_PATTERN:RegExp = /_x[0123456789abcdefABCDEF]{4}_/g;
        
        /** 
         *
         */
        private static const PADDING:String ="000";
        
        /** 
         *
         */
        private static const HEX_DIGITS:String = "0123456789abcdefABCDEF";

	/**
	 *
	 */
	private static const U_CODE:int = "_".charCodeAt(0);

	public function ISO9075()
	{
	}
        
        /** 
         * Encodes a name as specified in ISO 9075.
		 * 
         * @param name The string to encode.
		 * 
         * @return The encoded string or else its name if it does not need encoding.
         */
        public static function encode(name:String):String {
            if (name.length == 0) {
                return name;
            } 
            if (_isXMLName(name) && (name.indexOf("_x") < 0)) {
                return name;
            } else {
                var encoded:String = "";
                for (var i:int = 0 ; i < name.length ; i++) {
                    if (i == 0) {
                        if (isXMLNameChar(name.charAt(i))) {
                            if (needsEscaping(name, i)) {
                                encoded += encodeChar(U_CODE);
                            } else {
                                encoded += name.charAt(i);
                            }
                        } else {
                            encoded += encodeChar(name.charCodeAt(i));
                        }
                    } else if (!isXMLNameChar(name.charAt(i))) {
                        encoded += encodeChar(name.charCodeAt(i));
                    } else {
                        if (needsEscaping(name, i)) {
                            encoded += encodeChar(U_CODE);
                        } else {
                            encoded += name.charAt(i);
                        }
                    }
                }
                return encoded;
            }
        }
        
        /** 
         * Decodes the name. 
		 *
         * @param name The string to decode.
		 * 
         * @return The decoded string.
         */
        public static function decode(name:String):String {
            if (name.indexOf("_x") < 0) {
                return name;
            } 
            return name.replace(ENCODE_PATTERN, replaceDecoded);
        }

		private static function replaceDecoded():String {
			var match:String = arguments[0];
            var ch:String = String.fromCharCode(
            	parseInt(match.substring(2, 6), 16));
            if ((ch == '$') || (ch == '\\')) {
                return "\\" + ch;
            } else {
                return ch;
            }
		}
        
        /** 
         * Encodes the character c as a string in the following form:
         * "_x" + hex value of c + "_" where the hex value has four 
		 * digits padded with leading zeros. For example: ' ' (the space 
		 * character) is encoded to: <code>_x0020_</code>.
		 * 
         * @param c The character code to encode.
         */
        private static function encodeChar(c:int):String {
            var hex:String = Number(c).toString(16);
            return "_x" + PADDING.substr(0, 4 - hex.length) + hex + "_";
        }
        
        /** 
         * Returns true if <code>name.charAt(location)</code> is the underscore
         * character and the following character sequence is '<code>xHHHH_</code>' where H
         * is a hex digit.
		 * 
         * @param name The name to check.
         * @param location The location in which to look.
         */
        private static function needsEscaping(name:String, location:int):Boolean {
            if ((name.charCodeAt(location) == U_CODE) 
	    && (name.length >= (location + 6))) {
                return ((((name.charAt(location + 1) == 'x') 
		    && (HEX_DIGITS.indexOf(name.charAt(location + 2)) != -1))
		    && (HEX_DIGITS.indexOf(name.charAt(location + 3)) != -1))
		    && (HEX_DIGITS.indexOf(name.charAt(location + 4)) != -1))
		    && (HEX_DIGITS.indexOf(name.charAt(location + 5)) != -1);
            } else {
                return false;
            }
        }
        
	/**
 	 * Returns true if the input character is a valid starting character for an XML name.
	 */
        private static function isXMLNameStart(c:String):Boolean {
        	return (c >= 'A' && c <= 'Z')
        		|| (c >= 'a' && c <= 'z')
        		|| (c == '_');
        }
        
	/**
 	 * Returns true if the input character is a valid character for an XML name.
	 */
        private static function isXMLNameChar(c:String):Boolean {
        	return (c >= '0' && c <= '9')
        		|| (c >= 'A' && c <= 'Z')
        		|| (c >= 'a' && c <= 'z')
        		|| (c == '_')
        		|| (c == '-')
        		|| (c == '.');
        }
        
        /**
         * The global AS3 function <code>isXMLName()</code> doesn't seem to work with 
		 * non-ascii characters. TODO: ?
         */ 
        private static function _isXMLName(name:String):Boolean {
        	if (name.length == 0)
        		return false;
        	if (isXMLNameStart(name.charAt(0)) == false)
        		return false;
        	
        	for (var i:int = 1; i < name.length; i++)
        		if (isXMLNameChar(name.charAt(i)) == false) return false;
        		
        	return true;
        }
    }
}

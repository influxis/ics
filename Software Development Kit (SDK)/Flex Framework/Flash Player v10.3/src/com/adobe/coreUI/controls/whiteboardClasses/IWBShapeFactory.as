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
package com.adobe.coreUI.controls.whiteboardClasses
{
	/**
	 * @private
	 */
	public interface IWBShapeFactory
	{
		
		function newShape():WBShapeBase;
		function get toolBar():IWBPropertiesToolBar;
		function get toggleSelectionAfterDraw():Boolean;
		function set shapeData(p_data:Object):void;
		function get cursor():Class;
		function get factoryId():String;
	}
}
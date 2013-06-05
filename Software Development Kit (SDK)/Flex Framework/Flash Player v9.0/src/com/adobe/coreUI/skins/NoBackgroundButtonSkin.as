package com.adobe.coreUI.skins
{
	import mx.skins.halo.ButtonSkin;

	/**
	 * @private
	 */
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
   public class  NoBackgroundButtonSkin extends ButtonSkin
	{
		public function NoBackgroundButtonSkin()
		{
			super();
		}
		
		protected override function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w,h);
			alpha = 0;
		}
	}
}
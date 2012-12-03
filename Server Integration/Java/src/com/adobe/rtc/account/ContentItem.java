package com.adobe.rtc.account;

/*
 *  $File$ $Revision$ $Date$
 *
 *  ADOBE SYSTEMS INCORPORATED
 *    Copyright 2007 Adobe Systems Incorporated
 *    All Rights Reserved.
 *
 *  NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
 *  terms of the Adobe license agreement accompanying it.  If you have received this file from a 
 *  source other than Adobe, then your use, modification, or distribution of it requires the prior 
 *  written permission of Adobe.
 */

import java.util.Date;

  /**
   * Item: Room or template item information.
   */
  public class ContentItem {
    public String name;
    public String desc;
    public Date created;

    ContentItem(String name, String desc, Date created) {
     this.name = name;
     this.desc = desc;
     this.created = created;
    }
  }

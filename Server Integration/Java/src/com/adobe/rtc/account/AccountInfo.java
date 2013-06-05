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

import java.util.*;

public class AccountInfo {
	public long userCount;
	public long peakUsers;
	public long bytesUp;
	public long bytesDown;
	public long messages;
	public long userTime;
	public Date dateCreated;
	public Date dateExpired;
	public String activeRooms[];

	public String toString() {
		return "(userCount:" + userCount
			+ ", bytesUp:" + bytesUp
			+ ", bytesDown:" + bytesDown
			+ ", messages:" + messages
			+ ", usertime:" + userTime
			+ ", dateCreated:" + dateCreated
			+ ", dateExpired:" + dateExpired
			+ ", activeRooms:" + (activeRooms != null ? activeRooms.length : 0)
			+ "}";
	}
}

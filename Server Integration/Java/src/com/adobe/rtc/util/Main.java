package com.adobe.rtc.util;

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

import com.adobe.rtc.account.AccountManager;
import com.adobe.rtc.account.ContentItem;
import com.adobe.rtc.account.Session;
import com.adobe.rtc.messaging.UserRoles;

import java.util.*;

/**
 * A command line tool that exercises the LCCS APIs
 *
 * @author  Raffaele Sena
 */
public class Main {

	private static void usage(String progname, String reason) {
		if (reason != null)
			System.out.println(reason + "\n");
			
		System.out.println("usage: " + progname + " [--version] [--debug] [--host=url] account user password command parameters... ");
		System.out.println();
		System.out.println("where command is:");
		System.out.println("    --list");
		System.out.println("    --create room [template]");
		System.out.println("    --create-autodelete room [template]");
		System.out.println("    --delete room");
		System.out.println("    --delete-template template");
		System.out.println("    --delete-archive archive");
		System.out.println("    --move-archive archive [template]");			
		System.out.println("    --ext-auth secret room username userid role");
		System.out.println("    --invalidate room");
		System.out.println();
		System.out.println("    --get-node-configuration room collection node");
		System.out.println("    --fetch-items room collection node");
		System.out.println("    --register-hook endpoint [token]");
		System.out.println("    --unregister-hook");
		System.out.println("    --hook-info");
		System.out.println("    --register-repository endpoint [token]");
		System.out.println("    --unregister-repository");
		System.out.println("    --repository-info");
		System.out.println("    --subscribe-collection room collection");
		System.out.println("    --unsubscribe-collection room collection");
		System.out.println("    --create-node room collection [node]");
		System.out.println("    --remove-node room collection [node]");
		System.out.println("    --set-user-role room userID role [collection [node]]");
		System.out.println("    --publish-item room collection node itemID body");
		System.out.println("    --retract-item room collection node itemID");
		System.out.println();		
		System.out.println("    --start-recording room [[archiveId] [guestsAllowed]]");
		System.out.println("    --stop-recording room");		
		System.exit(1);
	}
	
	private static int getRole(String sRole) {
		if (sRole.equalsIgnoreCase("none"))
			return UserRoles.NONE;
		else if (sRole.equalsIgnoreCase("lobby"))
			return UserRoles.LOBBY;
		else if (sRole.equalsIgnoreCase("viewer"))
			return UserRoles.VIEWER;
		else if (sRole.equalsIgnoreCase("publisher"))
			return UserRoles.PUBLISHER;
		else if (sRole.equalsIgnoreCase("owner"))
			return UserRoles.OWNER;
		else
			return Integer.parseInt(sRole);
	}

	/**
	 * A simple command line utility
	 */
	public static void main(String args[]) throws Exception {
		String progname = "lccs";
		String host = "http://collaboration.adobelivecycle.com";
		int argc = 0;

		while (argc < args.length) {

			String arg = args[argc];

			if (arg.equals("--version")) {
				System.out.println(progname + " " + AccountManager.VERSION);
				System.exit(0);
			}
			
			else if (arg.startsWith("--host="))
				host = arg.substring(7);

			else if (arg.equals("--debug"))
				Utils.DEBUG = true;
			
			else if (arg.startsWith("-"))
				usage(progname, "Invalid option: " + arg);

			else
				break;

			argc++;
		}

		if (args.length - argc < 3)
			usage(progname, "Missing argument");

		String account = args[argc++];
		String username = args[argc++];
		String password = args[argc++];

		AccountManager am = new AccountManager(host + "/" + account);
		am.login(username,password);
		
		try {
			if (args.length - argc == 0 || args[argc].equals("--list")) {
				System.out.println("==== template list for " + account + " ====");
				try {
					for (ContentItem aTemplate : am.listTemplates()) {
						System.out.println(aTemplate.name + " : " + aTemplate.created);
					}
				} catch(Exception e) {
					System.out.println("error listing templates");
					e.printStackTrace(System.out);
				}

				System.out.println("==== room list for " + account + " ====");
				try {
					for (ContentItem aRoom : am.listRooms()) {
						System.out.println(aRoom.name + " : " + aRoom.desc + " : " + aRoom.created);
					}
				} catch(Exception e) {
					System.out.println("error listing rooms");
					e.printStackTrace(System.out);
				}
				
				System.out.println("==== archive list for " + account + " ====");
				try {
					for (ContentItem aArchive : am.listArchives()) {
						System.out.println(aArchive.name + " : " + aArchive.desc + " : " + aArchive.created);
					}
				} catch(Exception e) {
					System.out.println("error listing archives");
					e.printStackTrace(System.out);
				}				
			}

			else if (args[argc].equals("--create")) {
				am.createRoom(args[argc+1], (args.length - argc) > 2 ? args[argc+2] : null);
			}

			else if (args[argc].equals("--create-autodelete")) {
				am.createRoom(args[argc+1], (args.length - argc) > 2 ? args[argc+2] : null, true);
			}

			else if (args[argc].equals("--delete")) {
				am.deleteRoom(args[argc+1]);
			}

			else if (args[argc].equals("--delete-template")) {
				am.deleteTemplate(args[argc+1]);
			}

			else if (args[argc].equals("--delete-archive")) {
				am.deleteArchive(args[argc+1]);
			}

			else if (args[argc].equals("--move-archive")) {
				am.moveArchive(args[argc+1], (args.length - argc) > 2 ? args[argc+2] : null);				
			}
			
			else if (args[argc].equals("--ext-auth")) {
				int role = UserRoles.LOBBY;

				if (args.length - argc >= 6)
					role = getRole(args[argc+5]);

				Session session = am.getSession(args[argc+2]);
				String token =  session.getAuthenticationToken(args[argc+1], args[argc+3], args[argc+4], role);
				System.out.println(token);
				System.out.println("userID: " + session.getUserID(args[argc+4]));
			}

			else if (args[argc].equals("--invalidate")) {
				Session session = am.getSession(args[argc+1]);
				am.invalidateSession(session);
			}

			else if (args[argc].equals("--info")) {
				if ((args.length - argc) == 1)
					System.out.println(am.getAccountInfo());
				else
					System.out.println(am.getRoomInfo(args[argc+1]));
			}

			else if (args[argc].equals("--get-node-configuration")) {
				System.out.println("" + am.getNodeConfiguration(args[argc+1], args[argc+2], args[argc+3]));
			}

			else if (args[argc].equals("--fetch-items")) {
				System.out.println("" + am.fetchItems(args[argc+1], args[argc+2], args[argc+3]));
			}

			else if (args[argc].equals("--register-hook")) {
				String endpoint = args[argc+1];
				String token = (args.length - argc) > 2 ? args[argc+2] : null;
				am.registerHook(endpoint, token);
			}
			
			else if (args[argc].equals("--unregister-hook")) {
				am.unregisterHook();
			}
			
			else if (args[argc].equals("--hook-info")) {
				System.out.println("" + am.getHookInfo());
			}
			
			else if (args[argc].equals("--register-repository")) {
				String endpoint = args[argc+1];
				String token = (args.length - argc) > 2 ? args[argc+2] : null;
				am.registerRepository(endpoint, token);
			}

			else if (args[argc].equals("--unregister-repository")) {
				am.unregisterRepository();
			}
			
			else if (args[argc].equals("--repository-info")) {
				System.out.println("" + am.getRepositoryInfo());
			}

			else if (args[argc].equals("--subscribe-collection")) {
				String room = args[argc+1];
				String collectionName = args[argc+2];
				am.subscribeCollection(room, collectionName);
			}
			
			else if (args[argc].equals("--unsubscribe-collection")) {
				String room = args[argc+1];
				String collectionName = args[argc+2];
				am.unsubscribeCollection(room, collectionName);
			}
			
			else if (args[argc].equals("--create-node")) {
				String room = args[argc+1];
				String collectionName = args[argc+2];
				String nodeName = (args.length - argc) > 3 ? args[argc+3] : null;
				am.createNode(room, collectionName, nodeName);
			}
			
			else if (args[argc].equals("--remove-node")) {
				String room = args[argc+1];
				String collectionName = args[argc+2];
				String nodeName = (args.length - argc) > 3 ? args[argc+3] : null;
				am.removeNode(room, collectionName, nodeName);
			}
			
			else if (args[argc].equals("--set-user-role")) {
				String room = args[argc+1];
				String userID = args[argc+2];
				int role = getRole(args[argc+3]);
				String collectionName = (args.length - argc) > 4 ? args[argc+4] : null;
				String nodeName = (args.length - argc) > 5 ? args[argc+5] : null;
				am.setUserRole(room, userID, role, collectionName, nodeName);
			}
			
			else if (args[argc].equals("--publish-item")) {
				String room = args[argc+1];
				String collectionName = args[argc+2];
				String nodeName = args[argc+3];
				String itemID = args[argc+4];
				String body = args[argc+5];

				Map<String, Object> itemVO = new HashMap<String, Object>();
				itemVO.put("itemID", itemID);
				itemVO.put("body", body);
				am.publishItem(room, collectionName, nodeName, itemVO);
			}

			else if (args[argc].equals("--retract-item")) {
				String room = args[argc+1];
				String collectionName = args[argc+2];
				String nodeName = args[argc+3];
				String itemID = args[argc+4];
				am.retractItem(room, collectionName, nodeName, itemID);
			}

			else if (args[argc].equals("--start-recording")) {
				String room = args[argc+1];
				String archiveID = (args.length - argc) > 2 ? args[argc+2] : null;
				String guestsAllowed = (args.length - argc) > 3 ? args[argc+3] : "true";
				am.startRecording(room, archiveID, "true".equals(guestsAllowed));
			}

			else if (args[argc].equals("--stop-recording")) {
				String room = args[argc+1];
				am.stopRecording(room);
			}
			
			else {
				// make it fail
				System.out.println(args[-1]);
			}
		} catch (ArrayIndexOutOfBoundsException e1) {
			String reason;
			
			if ("-1".equals(e1.getMessage()))
				reason = "Invalid option: " + args[argc];
			else
				reason = "Missing parameter";

			usage(progname, reason);
		} catch (Exception e) {
			System.out.println("Error!\n");
			
			e.printStackTrace(System.out);
		}
	}  
}

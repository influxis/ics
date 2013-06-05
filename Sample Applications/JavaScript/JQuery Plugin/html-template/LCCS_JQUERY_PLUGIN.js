/**
 *The plugin that instantiates LCCS & binds all the click events for the input fields
*/
(function($){  
	$.fn.extend({   
		makeCollaborative: function(swfName,roomURL, userName, password) {
			var data;
			if (swfName) {
				data = $(this).data('swfName',swfName);
				startLCCS(swfName,roomURL, userName, password);
			} else {
				if (!data) {
					$.error("instantiate plugin with application swfs name");
				}
			}
			return this.each(function() {
			$(this).bind("change",onTextChange);
			$(this).bind("keyup",onTextChange);
			$(this).bind("focus",onTextChange);
			$(this).bind("click",onTextChange);
			$(this).bind("focusout",onFocusOut);
		});  
	}  
	});  
})(jQuery);

/**
 * Load a few other plugin and css files that are needed once the document is loaded
*/
$(document).ready(function() { 
	$.getScript('jquery.tipsy.js', function() {
		$("input[name='lcssBtns']").tipsy({trigger: 'manual', gravity: 'w', fade: true});
		console.log('tipsy.js loaded');
		});
	$('head').append("<link href='tipsy.css' type='text/css' rel='stylesheet' />");
	//$(document).mousemove(function (event) {$("#age1").val(event.pageX + " " + event.pageY)});
});

var sharedObj;
var batonObject;
var connectSession;

/**
 * Load LCCS and connect a room
 * @param swfName is the name of the swf that the mxml file generates
 * @param roomURL LCCS RoomURL
 * @param userName LCCS userName usually yourAccountName@adobe.com
 * @param password LCCS account password. Its optional if the rooms autoPromote is set to True and all the necessary nodes are created by the owner
*/
function startLCCS(swfName,roomURL, userName, password) {
	connectSession = new ConnectSession(swfName);
	if (roomURL) {
		connectSession.roomURL = roomURL;
	}else {
		$.error("Please provide a LCCS room URL");
	}
	var auth = new Object();
	if (userName) {
		auth.userName = userName;
	} else {
		$.error("Please provide a userName");
	}
	if (password) {
		auth.password = password;
	}
	connectSession.authenticator = auth;
	connectSession.addEventListener("synchronizationChange",this);
	connectSession.login();
}

/**
 * Instantiate BatonObject & SharedCursor once we are connected to the Room
*/
function synchronizationChange(evt) 
{
	if (evt.target instanceof ConnectSession && evt.value) {
		
		startSharedCursor();
		batonObject = new BatonObject();
		batonObject.sharedID = "batonFormValues";
		batonObject.addEventListener("synchronizationChange",this);
		batonObject.addEventListener("propertyChange",this);
		batonObject.addEventListener("propertyAdd",this);
		batonObject.addEventListener("propertyRetracted",this);
		batonObject.addEventListener("batonHolderChange",this);
		batonObject.setTimeOut(10);
		batonObject.subscribe();
	} else if (evt.target instanceof BatonObject && evt.target.isSynchronized()) {
		var tmpObj = batonObject.getValues();
		for (var elementId in tmpObj) {
			if ($("#"+elementId)) {
				$("#"+elementId).val(tmpObj[elementId]);
			}
		} 
	}
}

function batonHolderChange(p_evt) 
{
	if (p_evt.PROPERTY_ID) {
		var id1 = "#"+p_evt.PROPERTY_ID;
		var holderID = batonObject.getHolderID(p_evt.PROPERTY_ID);
		if (holderID) {
			if (connectSession.userManager.myUserID != holderID) {
				$(id1).addClass('disabledInputCSSClass');
				$(id1).attr('disabled', 'disabled');
				var usrName = connectSession.userManager.getUserDescriptor(holderID).displayName;
				usrName = $(id1).attr("id") + " field is controlled by " + usrName;
				$(id1).attr('original-title', usrName);
				$(id1).tipsy("show");
			} else {
				$(id1).removeAttr('disabled');
				$(id1).removeAttr('original-title');
				$(id1).tipsy("hide");
				$(id1).removeClass('disabledInputCSSClass');
			}
		} else {
			$(id1).removeAttr('disabled');
			$(id1).removeAttr('original-title');
			$(id1).tipsy("hide");
			$(id1).removeClass('disabledInputCSSClass');
		}
	}
}

function onTextChange(p_evt) {
	var id1 = "#" + p_evt.target.id;
	if (batonObject.isSynchronized() && batonObject.getProperty(p_evt.target.id) != p_evt.target.value) {
		if (batonObject.isAvailable(p_evt.target.id) || batonObject.amIHolding(p_evt.target.id)) {
			batonObject.setProperty(p_evt.target.id,p_evt.target.value);
		}
	} else if (batonObject.isSynchronized() && (p_evt.type == "focus" || p_evt.type == "click") && batonObject.isAvailable(p_evt.target.id)) {
		batonObject.grab(p_evt.target.id);
	}
		
}

function onFocusOut(p_evt) {
	var id1 = "#"+p_evt.itemID;
	if (batonObject.isSynchronized() && batonObject.amIHolding(p_evt.target.id)) {
		batonObject.putDown(p_evt.target.id);
	}
}

function propertyChange(p_evt) {
	var id1 = "#"+p_evt.itemID;
	if (batonObject.isSynchronized() && $(id1).val() != p_evt.value && p_evt.item.publisherID != connectSession.userManager.myUserID) {
		$(id1).attr('disabled', 'disabled');
		$(id1).val(p_evt.value);
	}
}

function propertyAdd(p_evt){
	var id1 = "#"+p_evt.itemID;
	if (batonObject.isSynchronized() && $(id1).val() != p_evt.value && p_evt.item.publisherID != connectSession.userManager.myUserID) {
		$(id1).val(p_evt.value);
	}
}

function propertyRetracted(p_evt){
	var id1 = "#"+p_evt.itemID;
	if (batonObject.isSynchronized() && $(id1).val() != p_evt.value && p_evt.item.publisherID != connectSession.userManager.myUserID) {
		$(id1).val("");
	}
}

function startSharedCursor() {
	var sharedCursor = new SharedCursorPane();
	sharedCursor.sizingMode = "absolute";
	sharedCursor.cursorClass = 'cursorFont';
	sharedCursor.subscribe();
}
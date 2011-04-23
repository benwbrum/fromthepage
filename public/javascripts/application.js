// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// checkModifications.js
// see http://blog.tremend.ro/2007/10/03/prototype-based-script-for-notifying-users-for-unsaved-changes-when-leaving-a-page/
var mustConfirmLeave = false;
function initCheckingForModifications(exceptions) {
    //var elems = $(formId).elements;
    var inputs = document.getElementsByTagName("input");
    for(var i = 0; i < inputs.length; i++) {
        var type = inputs[i].getAttribute("type");
        if(type == "checkbox" || type == "radio") {
            Event.observe(inputs[i], "change", somethingHasChanged);
        } else {
            Event.observe(inputs[i], "keypress", somethingHasChanged);
        }
    }
    var textareas = document.getElementsByTagName("textarea");
    for(var i = 0; i < textareas.length; i++) {
        Event.observe(textareas[i], "keypress", somethingHasChanged);
    }
    var selects = document.getElementsByTagName("select");
    for(var i = 0; i < selects.length; i++) {
        Event.observe(selects[i], "change", somethingHasChanged);
    }
   
    // for all a-s - intercept onclick
    var as = document.getElementsByTagName("a");
    for(var i = 0; i < as.length; i++) {
        // don't intercept for exceptions
        var linkId = as[i].getAttribute("id");
        if(exceptions == null || exceptions.indexOf(linkId) == -1) { 
	        var href = as[i].getAttribute("href");
	        as[i]._href = href;
	        as[i].removeAttribute("href");
	        Event.observe(as[i], "click", navigateAway.bindAsEventListener(as[i]));
        }
    }
}

function somethingHasChanged(e) {
    if (e.keyCode != Event.KEY_TAB) {
        mustConfirmLeave = true;
    }
}

function navigateAway(url) {
    if(checkForModifications()) {
        window.location.href = this._href;//url;
    }
}

function checkForModifications() {
    if(mustConfirmLeave) {
        if(confirm("You’ve made changes in the page. Select OK to discard your pages and leave the page, or hit cancel and press the save button to retain them.")) {
            return true;
        } else {
            return false;
        }                           
    }
    return true;
}



// functions supporting notes, copied over from Restful Comments plugin
window.restfulComments = new function() {
	
	this.showForm = function( form_id ) {
		
		document.getElementById( 'comment_form_' + form_id ).insertBefore( document.getElementById( 'comment_form' ), null );
		document.getElementById( 'comment_parent_id' ).value = form_id;
		document.getElementById( 'comment_form' ).style.display = 'block';
				
		return false;
	}
	
	this.hideForm = function() {
		
		document.getElementById( 'comment_form_0' ).insertBefore( document.getElementById( 'comment_form' ), null );
		document.getElementById( 'comment_parent_id' ).value = 0;
		document.getElementById( 'comment_form' ).style.display = 'none';
		
		return false;
	}
}




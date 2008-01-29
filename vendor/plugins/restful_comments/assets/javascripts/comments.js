
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


	this.showReviewForm = function( form_id ) {
		
		document.getElementById( 'review_form_' + form_id ).insertBefore( document.getElementById( 'review_form' ), null );
		document.getElementById( 'review_parent_id' ).value = form_id;
		document.getElementById( 'review_form' ).style.display = 'block';
				
		return false;
	}
	
	this.hideReviewForm = function() {
		
		document.getElementById( 'review_form_0' ).insertBefore( document.getElementById( 'review_form' ), null );
		document.getElementById( 'review_parent_id' ).value = 0;
		document.getElementById( 'review_form' ).style.display = 'none';
		
		return false;
	}
}

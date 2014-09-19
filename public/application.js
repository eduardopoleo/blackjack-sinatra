$(document).ready(function(){
	
	//$('#form-hit').click(function(){
	// this line rebinds the element #game without the need of a browser refresh
	// not putting this line produces the layout false in the controller to take place 
	$(document).on('click', '#form-hit input', function(){
		$.ajax({
			type: 'POST',
			url: '/player_hits'
		// this done function gets the output of the controller in the url as if it had no ajax	
		}).done(function(msg){
			$('#game').replaceWith(msg)
		});
	return false
	});

	$(document).on('click', '#form-stay input', function(){
		$.ajax({
			type: 'POST',
			url: '/show_dealer_cards'
		// this done function gets the output of the controller in the url as if it had no ajax	
		}).done(function(msg){
			$('#game').replaceWith(msg)
		});
	return false
	});

	$(document).on('click', '#dealer-btn', function(){
		$.ajax({
			type: 'POST',
			url: '/dealer_plays'
		// this done function gets the output of the controller in the url as if it had no ajax	
		}).done(function(msg){
			$('#game').replaceWith(msg)
		});
	return false
	});
});
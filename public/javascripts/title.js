$( document ).ready(function() {
  $('div[contenteditable=true]').blur(function(){
    $.post('/title/update',{ title: $(this).text(), id: $(this).parent().attr('id') });
  });
});

$(document).ready(function () {
    var formSaved = false;
    
    $('input').change(function () {
        formSaved = false;
    });
    
    $('form').on('submit', function(){
        formSaved = true;
    });
    
    
    window.onbeforeunload = function () {
        if (formSaved === false ) {
            return "Your changes have not been saved?"
        }
    };
});

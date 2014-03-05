$(document).ready(function () {
    var formSaved = false;
    
    $('textarea').change(function () {
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

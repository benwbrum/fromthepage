//functions to allow for speech to text

function startDictation(form, recognizing, id){
  if (window.hasOwnProperty('webkitSpeechRecognition')){
    var recognizing = recognizing;
    var startObj = $(id);
    var stopObj = startObj.next();
    var voiceData = form.find('textarea')[0]
    var recognition = new webkitSpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = false;
    recognition.lang = 'en-US';
    var final_transcript = '';
    recognition.start();

    recognition.onresult = function(e){
      for (var i = e.resultIndex; i < e.results.length; ++i){
          final_transcript += e.results[i][0].transcript;
      }
      voiceData.innerHTML = final_transcript;
    };
    recognition.onerror = function(e){
      recognizing = false;
      recognition.stop();
    }
    stopObj.click(function(e){
      e.preventDefault();
      recognition.stop();
      recognizing = false;
      $(this).hide();
      startObj.show();
    })
  }
}
//functions to allow for speech to text

function startDictation(){
  if (window.hasOwnProperty('webkitSpeechRecognition')){
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
      $('#transcription')[0].innerHTML = final_transcript;
    };
    recognition.onerror = function(e){
      recognition.stop();
    }
    $('#stop').click(function(e){
      e.preventDefault();
      recognition.stop();
    })
  }
}
//functions for speech to text

//set variables and initial recognition behavior
var recognizing = false;
var button;

if (window.hasOwnProperty('webkitSpeechRecognition')){
  var recognition = new webkitSpeechRecognition();
  recognition.continuous = true;
  recognition.interimResults = true;
  recognition.lang = 'en-US';

  recognition.onstart = function(){
    recognizing = true;
    button.src = '/assets/mic-on-icon.png'
  };
}

//change image when stop
recognition.onend = function(){
  recognizing = false;
  button.src = '/assets/mic-icon.png';
}

recognition.onerror = function(e){
  recognizing = false;
  recognition.stop();
  button.src = '/assets/mic-icon.png';
}

//toggle speech to text on and off
function startButton(e){
  e.preventDefault();
  if (recognizing) {
    recognition.stop();
    return;
  }
  startDictation(e.target);
}

function startDictation(target){
  recognizing = true;
  button = target;
  var form = $(button.form)
  var voiceData = form.find('textarea')
  var initialText = voiceData.text();
  var final_transcript = initialText + '\n';
  var interim_transcript = initialText + '\n';

  recognition.start();
  recognition.onresult = function(e){
    for (var i = e.resultIndex; i < e.results.length; ++i){
      if (e.results[i].isFinal){
        final_transcript += e.results[i][0].transcript;
      }
    }
    voiceData.text(final_transcript);
  };
}
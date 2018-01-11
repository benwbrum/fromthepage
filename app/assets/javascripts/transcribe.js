//Voice to text functionality

//set variables and initial recognition behavior
var recognizing = false;
//this finds the correct button on the page
var button;
//this finds the correct information span on the page
var voiceSpan;

if (window.hasOwnProperty('webkitSpeechRecognition')){
  var recognition = new webkitSpeechRecognition();
  recognition.continuous = true;
  recognition.interimResults = true;

  recognition.onstart = function(){
    recognizing = true;
    button.src = '/assets/mic-on-icon.png';
    voiceSpan.text("Listening");
  };
}

//change image when stop
recognition.onend = function(){
  recognizing = false;
  button.src = '/assets/mic-icon.png';
  voiceSpan.text("Click microphone for dictation");
}

recognition.onerror = function(e){
  recognizing = false;
  recognition.stop();
  button.src = '/assets/mic-icon.png';
  voiceSpan.text("Recording Error");
  voiceSpan.addClass('voice-error');
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
  recognition.lang = window.lang;
  recognizing = true;
  button = target;
  var form = $(button.form);
  var voiceData = form.find('textarea');
  voiceSpan = form.find('.voice-info');
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

//Check for unsaved notes before save
function unsavedNotes(e){
  var noteText = $('.user-bubble_form #note_body:last').text();
  if (noteText != ''){
    e.preventDefault();
    alert("You have unsaved notes. Please save or discard notes before saving transcription.");
  } else {
    return;
  }


}

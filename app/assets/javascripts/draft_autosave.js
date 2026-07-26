// LocalStorage-based draft autosave for transcription and translation editors.
//
// Usage: call FtpDraftAutosave.init(storageKey) once the page is ready.
// The storageKey should be unique per user + page + text-type, e.g.:
//   'ftp:draft:<collection_id>:<work_id>:<page_id>:<type>:<user_slug>'
//
// Public API:
//   FtpDraftAutosave.init(storageKey)  – wire events and check for a saved draft
//   FtpDraftAutosave.purge()           – remove the stored draft (call on successful save)
//   FtpDraftAutosave.saveDraft()       – immediately persist the current editor content

/* global myCodeMirror, hot */

var FtpDraftAutosave = (function () {
  var storageKey = null;
  var saveTimer = null;
  var DEBOUNCE_MS = 2000;
  var PERIODIC_MS = 30000;

  // ---- localStorage helpers (degrade silently on failure) ----

  function lsSet(key, value) {
    try { localStorage.setItem(key, value); } catch (e) { /* quota / unavailable */ }
  }

  function lsGet(key) {
    try { return localStorage.getItem(key); } catch (e) { return null; }
  }

  function lsRemove(key) {
    try { localStorage.removeItem(key); } catch (e) { /* ignore */ }
  }

  // ---- Content capture ----

  function getCodeMirrorValue() {
    if (typeof myCodeMirror !== 'undefined') { return myCodeMirror.getValue(); }
    var ta = document.getElementById('page_source_text') ||
             document.getElementById('page_source_translation');
    return ta ? ta.value : null;
  }

  function captureContent() {
    var content = {};

    // Document-based (CodeMirror or plain textarea)
    var cmVal = getCodeMirrorValue();
    if (cmVal !== null) { content.sourceText = cmVal; }

    // Page title field (when scribes_can_edit_titles is true)
    var titleField = document.getElementById('page_title');
    if (titleField) { content.title = titleField.value; }

    // Field-based inputs (.field-wrapper .field-input, name="fields[id][label]")
    var fieldValues = {};
    var hasFields = false;
    document.querySelectorAll('.field-wrapper .field-input').forEach(function (input) {
      var name = input.getAttribute('name');
      if (name) { fieldValues[name] = input.value; hasFields = true; }
    });
    if (hasFields) { content.fields = fieldValues; }

    // Spreadsheet (HandsOnTable) – read from the hidden field kept in sync by
    // the handsontable Stimulus controller.  Supports multiple spreadsheet fields.
    var sheetValues = {};
    var hasSheets = false;
    document.querySelectorAll('[data-controller="handsontable"]').forEach(function (el) {
      try {
        var fieldMeta = JSON.parse(
          el.getAttribute('data-handsontable-transcription-field-value') || '{}'
        );
        var id = fieldMeta.id;
        if (!id) { return; }
        var hiddenField = document.getElementById('fields-' + id);
        if (hiddenField && hiddenField.value) {
          sheetValues['fields-' + id] = JSON.parse(hiddenField.value);
          hasSheets = true;
        }
      } catch (e) { /* malformed data – skip */ }
    });
    if (hasSheets) { content.spreadsheets = sheetValues; }

    return content;
  }

  // ---- Save ----

  function saveDraft() {
    if (!storageKey) { return; }
    try {
      var payload = JSON.stringify({
        savedAt: new Date().toISOString(),
        content: captureContent()
      });
      lsSet(storageKey, payload);
    } catch (e) { /* serialisation error – skip */ }
  }

  function debouncedSave() {
    if (saveTimer) { clearTimeout(saveTimer); }
    saveTimer = setTimeout(saveDraft, DEBOUNCE_MS);
  }

  // ---- Purge ----

  function purge() {
    if (storageKey) { lsRemove(storageKey); }
  }

  // ---- Restore content into editors ----

  function restoreContent(content) {
    if (!content) { return; }

    if (content.sourceText !== undefined) {
      if (typeof myCodeMirror !== 'undefined') {
        myCodeMirror.setValue(content.sourceText);
      } else {
        var ta = document.getElementById('page_source_text') ||
                 document.getElementById('page_source_translation');
        if (ta) { ta.value = content.sourceText; }
      }
    }

    if (content.title !== undefined) {
      var titleField = document.getElementById('page_title');
      if (titleField) { titleField.value = content.title; }
    }

    if (content.fields) {
      document.querySelectorAll('.field-wrapper .field-input').forEach(function (input) {
        var name = input.getAttribute('name');
        if (name && Object.prototype.hasOwnProperty.call(content.fields, name)) {
          input.value = content.fields[name];
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
        }
      });
    }

    if (content.spreadsheets) {
      Object.keys(content.spreadsheets).forEach(function (fieldId) {
        var data = content.spreadsheets[fieldId];
        // Update the hidden field (what gets submitted to the server)
        var hiddenField = document.getElementById(fieldId);
        if (hiddenField) { hiddenField.value = JSON.stringify(data); }
        // Update the visual Handsontable instance when available
        if (typeof hot !== 'undefined') {
          // Legacy global `hot` variable (single-spreadsheet support)
          hot.loadData(data);
        }
      });
    }
  }

  // ---- Restore banner ----

  function buildBanner(draft) {
    var savedAt = draft.savedAt ? new Date(draft.savedAt).toLocaleString() : 'an earlier session';
    var banner = document.createElement('div');
    banner.id = 'ftp-draft-restore-banner';
    banner.className = 'flash flash-notice';
    banner.setAttribute('role', 'status');
    banner.setAttribute('aria-live', 'polite');

    var msgSpan = document.createElement('span');
    msgSpan.className = 'flash_message';
    msgSpan.appendChild(
      document.createTextNode('You have unsaved work from ' + savedAt + ' that may not have been saved to the server. ')
    );

    var restoreBtn = document.createElement('button');
    restoreBtn.type = 'button';
    restoreBtn.className = 'button';
    restoreBtn.textContent = 'Restore';
    restoreBtn.addEventListener('click', function () {
      restoreContent(draft.content);
      banner.parentNode.removeChild(banner);
    });

    var discardBtn = document.createElement('button');
    discardBtn.type = 'button';
    discardBtn.className = 'button outline';
    discardBtn.style.marginLeft = '8px';
    discardBtn.textContent = 'Discard';
    discardBtn.addEventListener('click', function () {
      purge();
      banner.parentNode.removeChild(banner);
    });

    var closeLink = document.createElement('a');
    closeLink.className = 'flash_close';
    closeLink.innerHTML = '&times;';
    closeLink.href = '#';
    closeLink.addEventListener('click', function (e) {
      e.preventDefault();
      banner.parentNode.removeChild(banner);
    });

    msgSpan.appendChild(restoreBtn);
    msgSpan.appendChild(discardBtn);
    banner.appendChild(msgSpan);
    banner.appendChild(closeLink);
    return banner;
  }

  function showRestoreBanner(draft) {
    var wrapper = document.getElementById('flash_wrapper');
    if (!wrapper) { return; }
    var existing = document.getElementById('ftp-draft-restore-banner');
    if (existing) { existing.parentNode.removeChild(existing); }
    wrapper.insertBefore(buildBanner(draft), wrapper.firstChild);
  }

  // ---- Check for an existing draft on page load ----

  function checkForDraft() {
    var raw = lsGet(storageKey);
    if (!raw) { return; }

    var draft;
    try { draft = JSON.parse(raw); } catch (e) { lsRemove(storageKey); return; }
    if (!draft || !draft.content) { lsRemove(storageKey); return; }

    // Compare draft against what the server currently renders.
    // If identical, the previous save succeeded – silently drop the stale draft.
    var current = captureContent();
    if (JSON.stringify(current) === JSON.stringify(draft.content)) {
      lsRemove(storageKey);
      return;
    }

    showRestoreBanner(draft);
  }

  // ---- Wire form-submit purge ----

  function wireFormPurge() {
    var form = document.getElementById('custom_form_id') ||
               document.querySelector('form.page-editor');
    if (!form) { return; }

    form.addEventListener('submit', function (event) {
      var submitter = event.submitter;
      if (!submitter) { return; }
      var name = submitter.name || '';
      // Purge only for genuine save / done / approve actions.
      // Do NOT purge for preview, autolink, or edit (those re-render the same page).
      if (/^(save|done|approve)/.test(name)) { purge(); }
    });
  }

  // ---- Wire all input events ----

  function wireEvents() {
    // Raw textarea / title field
    ['page_source_text', 'page_source_translation', 'page_title'].forEach(function (id) {
      var el = document.getElementById(id);
      if (!el) { return; }
      el.addEventListener('keyup', debouncedSave);
      el.addEventListener('change', debouncedSave);
      el.addEventListener('input', debouncedSave);
    });

    // Field-based inputs
    document.querySelectorAll('.field-wrapper .field-input').forEach(function (input) {
      input.addEventListener('keyup', debouncedSave);
      input.addEventListener('change', debouncedSave);
      input.addEventListener('input', debouncedSave);
    });

    // CodeMirror: hook after the instance is initialized (the codemirror partial
    // runs after this script in the page, so we poll briefly).
    var cmHookAttempts = 0;
    var cmHookInterval = setInterval(function () {
      cmHookAttempts += 1;
      if (typeof myCodeMirror !== 'undefined') {
        clearInterval(cmHookInterval);
        myCodeMirror.on('change', debouncedSave);
      } else if (cmHookAttempts > 50) {
        // Give up after ~5 s if CodeMirror never appears
        clearInterval(cmHookInterval);
      }
    }, 100);

    // Periodic save (catches spreadsheet changes & any missed events)
    setInterval(saveDraft, PERIODIC_MS);

    // Immediate save on page unload
    window.addEventListener('beforeunload', function () {
      if (saveTimer) { clearTimeout(saveTimer); }
      saveDraft();
    });

    wireFormPurge();
  }

  // ---- Public init ----

  function init(key) {
    if (!key) { return; }
    storageKey = key;
    wireEvents();
    // Delay the draft check to let CodeMirror (and field rendering) finish
    // initialising so captureContent() reads the correct server-rendered value.
    setTimeout(checkForDraft, 500);
  }

  return {
    init: init,
    purge: purge,
    saveDraft: saveDraft
  };
}());

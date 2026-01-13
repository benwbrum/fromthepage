import { PASTE_CHARACTERS_THRESHOLD } from 'libs/behavior_flagger/core/foundations/constants';
/**
 * usePasteFlagger - Listens to and flags suspicious paste events
 *
 * Responsibilities:
 * - Setups paste event listers
 * - Evaluates paste behaviors and flag suspicious events
 *
 * @param {Object} controller - Stimulus controller instance
 */
const usePasteFlagger = (controller) => {
  if (!controller) {
    console.error('usePasteFlagger requires a Stimulus controller instance.');
  };

  controller.editAreaTargetConnected = (target) => {
    target.addEventListener("paste", handlePaste);
  };

  controller.editAreaTargetDisconnected = (target) => {
    target.removeEventListener("paste", handlePaste);
  };

  const handlePaste = (event) => {
    const pastedText = (event.clipboardData || window.clipboardData).getData('text');

    if (pastedText.length > PASTE_CHARACTERS_THRESHOLD) {
      console.warn("Paste exceeds threshold! Possible AI-generated content.");

      controller.reportBehavior(
        'large_paste',
        {
          content: pastedText
        }
      );
    }
  }

  return () => {
    // Nothing to clean up for now
  };
};

export default usePasteFlagger;

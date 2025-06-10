import {
  $getSelection,
  $isRangeSelection,
  $createParagraphNode,
  FORMAT_TEXT_COMMAND,
  FORMAT_ELEMENT_COMMAND,
  KEY_ENTER_COMMAND,
  UNDO_COMMAND,
  REDO_COMMAND,
  CAN_REDO_COMMAND,
  CAN_UNDO_COMMAND,
  COMMAND_PRIORITY_LOW,
  COMMAND_PRIORITY_HIGH
} from 'lexical';

import { $isListItemNode, $insertList, $removeList } from '@lexical/list';
import { $isLinkNode } from '@lexical/link';

const BUTTONS = {
  "bold": {
    action: "bold",
    condition: 'bold',
    command: (editor) => editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'bold')
  },
  "italic": {
    action: "italic",
    condition: 'italic',
    command: (editor) => editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'italic')
  }
}

const getButtonsHtml = () => {
  return Object.keys(BUTTONS).map((action) => {
    return `<button class="btn btn-secondary f-lexical-editor-toolbar__button f-lexical-editor-toolbar__button--${action}" data-action="click->f-lexical-editor-toolbar#buttonClick" data-f-lexical-editor-toolbar-action-param="${action}" data-f-lexical-editor-toolbar-target="button">${action}</button>`;
  }).join('');
}

window.Folio.Stimulus.register('f-lexical-editor-toolbar', class extends window.Stimulus.Controller {
  static targets = ["button"]

  connect () {
  }

  updateToolbarState (editorState) {
    editorState.read(() => {
      const selection = $getSelection();
      if (!selection) return;

      const node = selection.anchor.getNode();
      const parent = node.getParent();

      const toggleButtonState = (button, condition) => {
        button.classList.toggle('btn-primary', condition);
        button.classList.toggle('btn-secondary', !condition);
      }

      this.buttonTargets.forEach((button) => {
        const action = BUTTONS[button.dataset.fLexicalEditorToolbarActionParam]

        if (mapping) {
          toggleButtonState(button, selection.hasFormat(mapping.condition));
        }
      })

      // const isLink = $isLinkNode(parent);
      // toggleButtonState(linkBtn, isLink);
      // if (linkInput) linkInput.value = isLink ? parent.getURL() : '';
    });
  }

  buttonClick (e) {
    e.preventDefault();
    e.stopPropagation();

    if (e.params.action) {
      const action = BUTTONS[e.params.action]
      if (action) {
        this.dispatch("toolbarAction", { detail: { action } })
      }
    }
  }
})

export default function getToolbarHtml () {
  return `
    <div class="f-lexical-editor-toolbar mb-3" data-controller="f-lexical-editor-toolbar">
      ${getButtonsHtml()}
    </div>
  `
}

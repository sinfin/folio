// adopted from https://github.com/jetrockets/lexical-vanilla-plugins

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

export default function registerToolbarActions(editor, elements, options = {}) {
  const {
    undoBtn,
    redoBtn,
    boldBtn,
    italicBtn,
    underlineBtn,
    ulBtn,
    olBtn,
    linkBtn,
    linkInput
  } = elements;

  const activeClass = options.activeClass || 'active';

  const updateToolbarState = (editorState) => {
    editorState.read(() => {
      const selection = $getSelection();
      if (!selection) return;

      const node = selection.anchor.getNode();
      const parent = node.getParent();

      const toggleButtonState = (button, condition) => {
        if (button) button.classList.toggle(activeClass, condition);
      };

      toggleButtonState(boldBtn, selection.hasFormat('bold'));
      toggleButtonState(italicBtn, selection.hasFormat('italic'));
      toggleButtonState(underlineBtn, selection.hasFormat('underline'));
      toggleButtonState(ulBtn, isListType(node, 'bullet'));
      toggleButtonState(olBtn, isListType(node, 'number'));

      const isLink = $isLinkNode(parent);
      toggleButtonState(linkBtn, isLink);
      if (linkInput) linkInput.value = isLink ? parent.getURL() : '';
    });
  };

  const isListType = (node, type) => {
    while (node) {
      if (node.getType() === 'list' && typeof node.getListType === 'function' && node.getListType() === type) {
        return true;
      }
      node = node.getParent();
    }
    return false;
  };

  const toggleList = (type) => {
    editor.update(() => {
      const selection = $getSelection();
      if ($isRangeSelection(selection)) {
        const node = selection.anchor.getNode();
        isListType(node, type) ? $removeList() : $insertList(type);
      }
    });
  };

  const handleEnterCommand = (e) => {
    const selection = $getSelection();
    const node = selection.anchor.getNode()

    if ($isListItemNode(node)) {
      editor.update(() => {
        const paragraphNode = $createParagraphNode()
        node.insertAfter(paragraphNode, node)
        node.remove()
        paragraphNode.select()
      })
      return true
    }
  }

  const registerCommandWithButton = (command, button, callback) => {
    editor.registerCommand(
      command,
      (payload) => {
        if (button) button.disabled = !payload;
        return callback ? callback(payload) : false;
      },
      COMMAND_PRIORITY_LOW
    );
  };

  registerCommandWithButton(CAN_UNDO_COMMAND, undoBtn);
  registerCommandWithButton(CAN_REDO_COMMAND, redoBtn);
  editor.registerCommand(KEY_ENTER_COMMAND, handleEnterCommand, COMMAND_PRIORITY_HIGH)

  return {
    undo: () => editor.dispatchCommand(UNDO_COMMAND),
    redo: () => editor.dispatchCommand(REDO_COMMAND),
    bold: () => editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'bold'),
    italic: () => editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'italic'),
    underline: () => editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'underline'),
    alignLeft: () => editor.dispatchCommand(FORMAT_ELEMENT_COMMAND, 'left'),
    alignCenter: () => editor.dispatchCommand(FORMAT_ELEMENT_COMMAND, 'center'),
    alignRight: () => editor.dispatchCommand(FORMAT_ELEMENT_COMMAND, 'right'),
    alignJustify: () => editor.dispatchCommand(FORMAT_ELEMENT_COMMAND, 'justify'),
    listBullet: () => toggleList('bullet'),
    listOrdered: () => toggleList('number'),
    updateToolbarState
  };
}

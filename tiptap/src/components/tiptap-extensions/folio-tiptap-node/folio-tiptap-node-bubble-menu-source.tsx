import { findParentNode } from "@tiptap/core";
import { Node } from "@tiptap/pm/model";
import type { Editor } from '@tiptap/core';
import type { FolioEditorBubbleMenuSource } from '@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus';

import { FolioTiptapNodeExtension } from './folio-tiptap-node-extension';
import {
  ArrowDownIcon,
  ArrowUpIcon,
  CloseIcon,
  EditIcon,
} from '@/components/tiptap-icons';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    moveFolioTiptapNodeUp: "Posunout nahoru",
    moveFolioTIptapNodeDown: "Posunout dolů",
    editFolioTipapNode: "Upravit",
    removeFolioTiptapNode: "Odstranit",
  },
  en: {
    moveFolioTiptapNodeUp: "Move up",
    moveFolioTIptapNodeDown: "Move down",
    editFolioTipapNode: "Edit",
    removeFolioTiptapNode: "Remove",
  }
}

export const FOLIO_TIPTAP_NODE_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource = {
  pluginKey: "folioTiptapNodeBubbleMenu",
  offset: ({rects}) => -rects.reference.height / 2 - rects.floating.height / 2,
  shouldShow: ({ editor, state }) => {
    return window.innerWidth <= 468 && editor.isActive(FolioTiptapNodeExtension.name)
  },
  items: [
    [
      {
        key: "moveFolioTiptapNodeUp",
        title: translate(TRANSLATIONS, "moveFolioTiptapNodeUp"),
        icon: ArrowUpIcon,
        command: ({ editor }: { editor: Editor }) => {
          // editor.chain().focus().setFolioTiptapFloatAttributes({ side: "left" }).run()
          console.log('moveFolioTiptapNodeUp')
        }
      },
      {
        key: "moveFolioTiptapNodeDown",
        title: translate(TRANSLATIONS, "moveFolioTiptapNodeDown"),
        icon: ArrowDownIcon,
        command: ({ editor }: { editor: Editor }) => {
          // editor.chain().focus().setFolioTiptapFloatAttributes({ side: "left" }).run()
          console.log('moveFolioTiptapNodeDown')
        }
      },
      {
        key: "editFolioTipapNode",
        title: translate(TRANSLATIONS, "editFolioTipapNode"),
        icon: EditIcon,
        command: ({ editor }: { editor: Editor }) => {
          // editor.chain().focus().setFolioTiptapFloatAttributes({ side: "left" }).run()
          console.log('editFolioTipapNode')
        }
      },
      {
        key: "removeFolioTiptapNode",
        title: translate(TRANSLATIONS, "removeFolioTiptapNode"),
        icon: CloseIcon,
        command: ({ editor }: { editor: Editor }) => {
          // editor.chain().focus().setFolioTiptapFloatAttributes({ side: "left" }).run()
          console.log('removeFolioTiptapNode')
        }
      },
    ]
  ]
}

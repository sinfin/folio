import { mergeAttributes, Node, ReactNodeViewRenderer } from "@tiptap/react";
import translate from "@/lib/i18n";

export const TRANSLATIONS = {
  cs: {
    label: "Stránkovaný obsah",
  },
  en: {
    label: "Paged content"
  }
}

export const FolioTiptapPageNode = Node.create({
  name: 'folioTiptapPage',
  content: 'block+',
  isolating: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-page',
        "data-f-tiptap-page-label": translate(TRANSLATIONS, "label"),
      },
    };
  },

  addAttributes() {
    return {
      index: {
        default: 0,
        parseHTML: (element) => {
          const raw = element.getAttribute('data-f-tiptap-page-index')

          if (typeof raw === 'string') {
            return parseInt(raw, 10);
          } else if (typeof raw === 'number') {
            return raw;
          } else {
            return 0;
          }
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-page"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ "data-f-tiptap-page-index": HTMLAttributes.index }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});

export default FolioTiptapPageNode;

import * as React from "react";
import {
  EditorContent,
  EditorContext,
  useEditor,
  type Editor,
} from "@tiptap/react";

// --- Tiptap Core Extensions ---
import { StarterKit } from "@tiptap/starter-kit";
// import { Image } from "@tiptap/extension-image";
import { TaskItem } from "@tiptap/extension-task-item";
import { TaskList } from "@tiptap/extension-task-list";
import { TextAlign } from "@tiptap/extension-text-align";
import { Typography } from "@tiptap/extension-typography";
import { Subscript } from "@tiptap/extension-subscript";
import { Superscript } from "@tiptap/extension-superscript";
import { Selection, Placeholder, TrailingNode } from "@tiptap/extensions";

// --- Tiptap Node ---
import { FolioTiptapNodeExtension } from "@/components/tiptap-extensions/folio-tiptap-node";
import {
  FolioTiptapColumnsExtension,
  FolioTiptapColumnNode,
  FolioTiptapColumnsNode,
} from "@/components/tiptap-extensions/folio-tiptap-columns";
import {
  StyledParagraph,
  DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_VARIANTS,
  makeFolioTiptapStyledParagraphCommands,
} from "@/components/tiptap-extensions/folio-tiptap-styled-paragraph";

import "@/components/tiptap-node/image-node/image-node.scss";
import "@/components/tiptap-node/paragraph-node/paragraph-node.scss";

// --- Tiptap UI ---
import {
  CommandsExtension,
  suggestion,
  defaultGroupForBlock,
  makeSuggestionItems,
} from "@/components/tiptap-ui/commands";

// --- Icons ---
import { ArrowLeftIcon } from "@/components/tiptap-icons/arrow-left-icon";
import { LinkIcon } from "@/components/tiptap-icons/link-icon";
import { SmartDragHandle } from "@/components/tiptap-ui/smart-drag-handle";

// --- Hooks ---
import { useWindowSize } from "@/hooks/use-window-size";

import translate from "@/lib/i18n";
import makeFolioTiptapNodeCommandGroup from "@/lib/make-folio-tiptap-node-command-group";

import TRANSLATIONS from "./folio-editor-i18n.json";
import { FolioEditorBubbleMenus } from "./folio-editor-bubble-menus";
import { FolioEditorToolbar } from "./folio-editor-toolbar";

import type { Content } from "@tiptap/react";

interface FolioEditorProps {
  onCreate?: (content: { editor: Editor }) => void;
  onUpdate?: (content: { editor: Editor }) => void;
  defaultContent?: Content;
  type: "block" | "rich-text";
  folioTiptapNodes: FolioTiptapNodeFromInput[];
}

export function FolioEditor({
  onCreate,
  onUpdate,
  defaultContent,
  type,
  folioTiptapNodes,
}: FolioEditorProps) {
  const windowSize = useWindowSize();
  const editorRef = React.useRef<HTMLDivElement>(null);
  const blockEditor = type === "block";
  const styledParagraphVariants =
    DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_VARIANTS;

  const styledParagraph = StyledParagraph.configure({
    variants: styledParagraphVariants,
  });

  const editor = useEditor({
    onUpdate,
    onCreate,
    content: defaultContent,
    autofocus: blockEditor,
    immediatelyRender: true,
    shouldRerenderOnTransaction: false,
    editorProps: {
      attributes: {
        autocomplete: "off",
        autocorrect: "off",
        autocapitalize: "off",
        "aria-label": "Main content area, start typing to enter text.",
      },
    },
    extensions: [
      StarterKit,
      TextAlign.configure({
        alignments: ["left", "center", "right"],
        types: ["heading", "paragraph"],
      }),
      TrailingNode,
      Typography,

      Selection,

      ...(blockEditor
        ? [FolioTiptapNodeExtension, Superscript, Subscript]
        : []),

      Placeholder.configure({
        // Use a placeholder:
        placeholder: ({ node }) => {
          let key = "commandPlaceholder";

          if (
            node.type.name === "heading" &&
            node.attrs.level &&
            [2, 3, 4].indexOf(node.attrs.level) !== -1
          ) {
            key = `h${node.attrs.level}Placeholder`;
          }

          return translate(TRANSLATIONS, key);
        },
      }),
      ...(blockEditor ? [TaskList] : []),
      ...(blockEditor ? [TaskItem.configure({ nested: true })] : []),
      Typography,

      Selection,
      ...(blockEditor
        ? [
            FolioTiptapColumnsExtension,
            FolioTiptapColumnsNode,
            FolioTiptapColumnNode,
          ]
        : []),
      styledParagraph,
      CommandsExtension.configure({
        suggestion:
          blockEditor && folioTiptapNodes
            ? {
                ...suggestion,
                items: makeSuggestionItems([
                  {
                    ...defaultGroupForBlock,
                    items: [
                      ...defaultGroupForBlock.items,
                      ...makeFolioTiptapStyledParagraphCommands(
                        styledParagraphVariants,
                      ),
                    ],
                  },
                  makeFolioTiptapNodeCommandGroup(folioTiptapNodes),
                ]),
              }
            : suggestion,
      }),
    ],
  });

  React.useEffect(() => {
    if (!editorRef.current) return;

    const editorElement = editorRef.current;

    const resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        window.top!.postMessage(
          {
            type: "f-tiptap-editor:resized",
            height: entry.contentRect.height,
          },
          "*",
        );
      }
    });

    resizeObserver.observe(editorElement);

    return () => {
      resizeObserver.disconnect();
    };
  }, []);

  // console.log('editor rendered', Number(new Date()))

  return (
    <EditorContext.Provider value={{ editor }}>
      <div
        ref={editorRef}
        className={`f-tiptap-editor f-tiptap-editor--${blockEditor ? "block" : "rich-text"}`}
      >
        <FolioEditorToolbar editor={editor} blockEditor={blockEditor} />

        <div className="f-tiptap-editor__content-wrap">
          {blockEditor ? <SmartDragHandle editor={editor} /> : null}

          <EditorContent
            editor={editor}
            role="presentation"
            className="f-tiptap-editor__content f-tiptap-styles"
          />

          <FolioEditorBubbleMenus editor={editor} blockEditor={blockEditor} />
        </div>
      </div>
    </EditorContext.Provider>
  );
}

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
import { TextAlign } from "@tiptap/extension-text-align";
import { Typography } from "@tiptap/extension-typography";
import { Subscript } from "@tiptap/extension-subscript";
import { Superscript } from "@tiptap/extension-superscript";
import { Placeholder } from "@tiptap/extensions";
import { TableKit } from '@tiptap/extension-table';

// --- Tiptap Node ---
import { FolioTiptapNodeExtension } from "@/components/tiptap-extensions/folio-tiptap-node";
import {
  FolioTiptapColumnsExtension,
  FolioTiptapColumnNode,
  FolioTiptapColumnsNode,
} from "@/components/tiptap-extensions/folio-tiptap-columns";
import {
  FolioTiptapStyledParagraph,
  DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_VARIANTS,
} from "@/components/tiptap-extensions/folio-tiptap-styled-paragraph";
import {
  FolioTiptapFloatNode,
  FolioTiptapFloatAsideNode,
  FolioTiptapFloatMainNode,
} from "@/components/tiptap-extensions/folio-tiptap-float";
import { FolioTiptapInvalidNode } from '@/components/tiptap-extensions/folio-tiptap-invalid-node';

import "@/components/tiptap-node/image-node/image-node.scss";
import "@/components/tiptap-node/paragraph-node/paragraph-node.scss";

import {
  TextStylesCommandGroup,
  ListsCommandGroup,
  LayoutsCommandGroup,
  makeFolioTiptapNodesCommandGroup
} from '@/components/tiptap-command-groups';

// --- Tiptap UI ---
import {
  FolioTiptapCommandsExtension,
  folioTiptapCommandsSuggestion,
  makeFolioTiptapCommandsSuggestionItems,
} from "@/components/tiptap-extensions/folio-tiptap-commands";

// --- Icons ---
import { SmartDragHandle } from "@/components/tiptap-ui/smart-drag-handle";

// --- Hooks ---
import { useWindowSize } from "@/hooks/use-window-size";

import translate from "@/lib/i18n";
import clearContent from "@/lib/clear-content";

import TRANSLATIONS from "./folio-editor-i18n.json";
import { FolioEditorBubbleMenus } from "./folio-editor-bubble-menus";
import { FolioEditorToolbar } from "./folio-editor-toolbar";

import type { JSONContent } from "@tiptap/react";

interface FolioEditorProps {
  onCreate?: (content: { editor: Editor }) => void;
  onUpdate?: (content: { editor: Editor }) => void;
  defaultContent?: JSONContent;
  type: "block" | "rich-text";
  folioTiptapConfig: FolioTiptapConfig;
  readonly: boolean;
}

export function FolioEditor({
  onCreate,
  onUpdate,
  defaultContent,
  type,
  folioTiptapConfig,
  readonly,
}: FolioEditorProps) {
  const windowSize = useWindowSize();
  const editorRef = React.useRef<HTMLDivElement>(null);
  const blockEditor = type === "block";

  const editor = useEditor({
    onUpdate,
    onCreate,
    onDrop () {
      for (const dropCursor of document.querySelectorAll('.prosemirror-dropcursor-block')) {
        (dropCursor as HTMLElement).hidden = true;
      }
    },
    autofocus: blockEditor,
    immediatelyRender: true,
    shouldRerenderOnTransaction: false,
    editable: !readonly,
    editorProps: {
      attributes: {
        autocomplete: "off",
        autocorrect: "off",
        autocapitalize: "off",
        "aria-label": "Main content area, start typing to enter text.",
        class: "f-tiptap-editor__tiptap-editor",
      },
    },
    extensions: [
      StarterKit.configure({
        link: {
          openOnClick: false,
          enableClickSelection: true,
          HTMLAttributes: {
            rel: null,
            target: null,
          },
        }
      }),
      TextAlign.configure({
        alignments: ["left", "center", "right"],
        types: ["heading", "paragraph"],
      }),
      Typography,
      Superscript,
      Subscript,
      FolioTiptapInvalidNode,

      ...(blockEditor
        ? [
            FolioTiptapNodeExtension,
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
            FolioTiptapColumnsExtension,
            FolioTiptapColumnsNode,
            FolioTiptapColumnNode,
            FolioTiptapFloatNode,
            FolioTiptapFloatAsideNode,
            FolioTiptapFloatMainNode,
            TableKit.configure({
              table: {
                allowTableNodeSelection: true,
                resizable: false,
              }
            }),
            FolioTiptapCommandsExtension.configure({
              suggestion:
                (blockEditor && folioTiptapConfig.nodes && folioTiptapConfig.nodes.length)
                  ? {
                      ...folioTiptapCommandsSuggestion,
                      items: makeFolioTiptapCommandsSuggestionItems([
                        TextStylesCommandGroup,
                        ListsCommandGroup,
                        LayoutsCommandGroup,
                        makeFolioTiptapNodesCommandGroup(folioTiptapConfig.nodes),
                      ]),
                    }
                  : folioTiptapCommandsSuggestion
            }),
          ]
        : []),
      FolioTiptapStyledParagraph,
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

  React.useEffect(() => {
    const clearedContent = clearContent({ content: defaultContent, editor })

    if (clearedContent) {
      editor.commands.setContent(clearedContent)
    }
  }, [defaultContent])

  let contentClassName = "f-tiptap-editor__content f-tiptap-styles"
  if (readonly) contentClassName += " f-tiptap-editor__content--readonly";

  return (
    <EditorContext.Provider value={{ editor }}>
      <div
        ref={editorRef}
        className={`f-tiptap-editor f-tiptap-editor--${blockEditor ? "block" : "rich-text"}`}
      >
        {readonly ? null : (
          <FolioEditorToolbar
            editor={editor}
            blockEditor={blockEditor}
            folioTiptapConfig={folioTiptapConfig}
          />
        )}

        <div className="f-tiptap-editor__content-wrap">
          {blockEditor && !readonly ? <SmartDragHandle editor={editor} /> : null}

          <EditorContent
            editor={editor}
            role="presentation"
            className={contentClassName}
          />

          {readonly ? null : (
            <FolioEditorBubbleMenus
              editor={editor}
              blockEditor={blockEditor}
            />
          )}
        </div>
      </div>
    </EditorContext.Provider>
  );
}

import * as React from "react";
import {
  EditorContent,
  EditorContext,
  useEditor,
  type Editor,
} from "@tiptap/react";
import { findParentNode, findChildren } from "@tiptap/core";
import { Node } from "@tiptap/pm/model";

// --- Tiptap Core Extensions ---
import { StarterKit } from "@tiptap/starter-kit";
import type { Level } from "@tiptap/extension-heading";
// import { Image } from "@tiptap/extension-image";
import { TextAlign } from "@tiptap/extension-text-align";
import { Typography } from "@tiptap/extension-typography";
import { Subscript } from "@tiptap/extension-subscript";
import { Superscript } from "@tiptap/extension-superscript";
import { Placeholder } from "@tiptap/extensions";
import { TableKit, Table } from '@tiptap/extension-table';

// --- Tiptap Node ---
import { FolioTiptapNodeExtension } from "@/components/tiptap-extensions/folio-tiptap-node";
import {
  FolioTiptapColumnsExtension,
  FolioTiptapColumnNode,
  FolioTiptapColumnsNode,
} from "@/components/tiptap-extensions/folio-tiptap-columns";
import {
  FolioTiptapPagesExtension,
  FolioTiptapPageNode,
  FolioTiptapPagesNode,
  makeFolioTiptapPagesCommands,
} from "@/components/tiptap-extensions/folio-tiptap-pages";
import {
  FolioTiptapStyledParagraph,
  makeFolioTiptapStyledParagraphCommands,
} from "@/components/tiptap-extensions/folio-tiptap-styled-paragraph";
import {
  FolioTiptapStyledWrap,
  makeFolioTiptapStyledWrapCommands,
} from "@/components/tiptap-extensions/folio-tiptap-styled-wrap";
import {
  FolioTiptapFloatNode,
  FolioTiptapFloatAsideNode,
  FolioTiptapFloatMainNode,
} from "@/components/tiptap-extensions/folio-tiptap-float";
import { FolioTiptapInvalidNode } from '@/components/tiptap-extensions/folio-tiptap-invalid-node';

import "@/components/tiptap-node/image-node/image-node.scss";
import "@/components/tiptap-node/paragraph-node/paragraph-node.scss";

import {
  ListsCommandGroup,
  makeLayoutsCommandGroup,
  makeTextStylesCommandGroup,
  makeFolioTiptapNodesCommandGroup
} from '@/components/tiptap-command-groups';

// --- Tiptap UI ---
import {
  FolioTiptapCommandsExtension,
  folioTiptapCommandsSuggestionWithoutItems,
  makeFolioTiptapCommandsSuggestion,
  makeFolioTiptapCommandsSuggestionItems,
} from "@/components/tiptap-extensions/folio-tiptap-commands";

// --- Icons ---
import { SmartDragHandle } from "@/components/tiptap-ui/smart-drag-handle";

// --- Hooks ---
import translate from "@/lib/i18n";
import clearContent from "@/lib/clear-content";

import TRANSLATIONS from "./folio-editor-i18n.json";
import { FolioEditorBubbleMenus } from "./folio-editor-bubble-menus";
import { FolioEditorToolbar } from "./folio-editor-toolbar";
import { FolioEditorResponsivePreview } from './folio-editor-responsive-preview';

import type { JSONContent } from "@tiptap/react";

interface FolioEditorProps {
  onCreate?: (props: { editor: Editor }) => void;
  onUpdate?: (props: { editor: Editor }) => void;
  defaultContent?: JSONContent;
  type: "block" | "rich-text";
  folioTiptapConfig: FolioTiptapConfig;
  readonly: boolean;
  initialScrollTop: number | null;
  autosaveIndicatorInfo?: FolioTiptapAutosaveIndicatorInfo;
}

export function FolioEditor({
  onCreate,
  onUpdate,
  defaultContent,
  type,
  folioTiptapConfig,
  readonly,
  initialScrollTop,
  autosaveIndicatorInfo,
}: FolioEditorProps) {
  const editorRef = React.useRef<HTMLDivElement>(null);
  const blockEditor = type === "block";
  const [responsivePreviewEnabled, setResponsivePreviewEnabled] = React.useState<boolean>(false);
  const [initializedContent, setInitializedContent] = React.useState<boolean>(false);
  const [editorCreated, setEditorCreated] = React.useState<boolean>(false);
  const [shouldScrollToInitial, setShouldScrollToInitial] = React.useState<number | null>(initialScrollTop);

  const folioTiptapStyledParagraphCommands = React.useMemo(() => {
    if (folioTiptapConfig &&
        folioTiptapConfig["styled_paragraph_variants"] &&
        folioTiptapConfig["styled_paragraph_variants"].length) {
      return makeFolioTiptapStyledParagraphCommands(folioTiptapConfig["styled_paragraph_variants"])
    }

    return []
  }, [folioTiptapConfig])

  const folioTiptapPagesCommands = React.useMemo(() => {
    if (folioTiptapConfig && folioTiptapConfig["enable_pages"]) {
      return makeFolioTiptapPagesCommands(folioTiptapConfig["enable_pages"])
    }

    return []
  }, [folioTiptapConfig])

  const folioTiptapStyledWrapCommands = React.useMemo(() => {
    if (folioTiptapConfig &&
        folioTiptapConfig["styled_wrap_variants"] &&
        folioTiptapConfig["styled_wrap_variants"].length) {
      return makeFolioTiptapStyledWrapCommands(folioTiptapConfig["styled_wrap_variants"])
    }

    return []
  }, [folioTiptapConfig])

  const folioTiptapHeadingLevels = React.useMemo(() => {
    if (folioTiptapConfig &&
        folioTiptapConfig["heading_levels"] &&
        folioTiptapConfig["heading_levels"].length) {
      return folioTiptapConfig["heading_levels"]
    }

    return [2, 3, 4] as Level[];
  }, [folioTiptapConfig])

  const textStylesCommandGroup = React.useMemo(() => {
    return makeTextStylesCommandGroup({ folioTiptapStyledParagraphCommands, folioTiptapHeadingLevels })
  }, [folioTiptapStyledParagraphCommands, folioTiptapHeadingLevels])

  const layoutsCommandGroup = React.useMemo(() => {
    return makeLayoutsCommandGroup({ folioTiptapStyledWrapCommands, folioTiptapPagesCommands })
  }, [folioTiptapStyledWrapCommands, folioTiptapPagesCommands])

  const editor = useEditor({
    onUpdate,
    onCreate (props: { editor: Editor }) {
      setEditorCreated(true)
      if (onCreate) {
        onCreate(props)
      }
    },
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
        heading: {
          levels: folioTiptapHeadingLevels,
        },
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
      Placeholder.configure({
        includeChildren: true,
        // Use a placeholder:
        placeholder: ({ editor, node }) => {
          if (blockEditor) {
            let key = "commandPlaceholder";

            if (node.type.name === "heading") {
              const maybePage = findParentNode((node: Node) => node.type.name === FolioTiptapPageNode.name)(editor.state.selection);
              let isFirstInPage = false

              if (maybePage) {
                const allTitlesInPage = findChildren(maybePage.node, (node: Node) => node.type.name === "heading");
                isFirstInPage = allTitlesInPage[0].node === node;
              }

              if (isFirstInPage) {
                key = 'headingInPagesPlaceholder'
              } else if (folioTiptapHeadingLevels.length === 1) {
                key = 'singleHeadingPlaceholder'
              } else if (node.attrs.level && [2, 3, 4].indexOf(node.attrs.level) !== -1) {
                key = `h${node.attrs.level}Placeholder`;
              }
            }

            return translate(TRANSLATIONS, key);
          } else {
            return translate(TRANSLATIONS, 'defaultPlaceholder');
          }
        },
      }),
      ...(blockEditor
        ? [
            FolioTiptapNodeExtension.configure({
              nodes: folioTiptapConfig.nodes || [],
            }),
            FolioTiptapColumnsExtension,
            FolioTiptapColumnsNode,
            FolioTiptapColumnNode,
            FolioTiptapPagesExtension,
            FolioTiptapPagesNode,
            FolioTiptapPageNode,
            FolioTiptapFloatNode,
            FolioTiptapFloatAsideNode,
            FolioTiptapFloatMainNode,
            Table.extend({
              parseHTML() {
                return [
                  {
                    tag: 'div.f-tiptap-table-wrapper',
                    contentElement: 'table',
                  },
                  { tag: 'table' },
                ]
              },
              renderHTML({ HTMLAttributes }) {
                return [
                  'div',
                  { class: 'f-tiptap-table-wrapper' },
                  ['table', HTMLAttributes, 0]
                ]
              },
            }).configure({
              allowTableNodeSelection: true,
              resizable: false,
            }),
            TableKit.configure({
              table: false, // disable default table to use our custom one
            }),
            FolioTiptapCommandsExtension.configure({
              suggestion:
                blockEditor
                  ? {
                      ...folioTiptapCommandsSuggestionWithoutItems,
                      items: makeFolioTiptapCommandsSuggestionItems([
                        textStylesCommandGroup,
                        ListsCommandGroup,
                        layoutsCommandGroup,
                        ...(folioTiptapConfig.nodes && folioTiptapConfig.nodes.length ? [makeFolioTiptapNodesCommandGroup(folioTiptapConfig.nodes)] : []),
                      ]),
                    }
                  : makeFolioTiptapCommandsSuggestion({ textStylesCommandGroup })
            }),
          ]
        : []),
      FolioTiptapStyledParagraph.configure({
        variantCommands: folioTiptapStyledParagraphCommands,
      }),
      FolioTiptapStyledWrap.configure({
        variantCommands: folioTiptapStyledWrapCommands,
      }),
    ],
  });

  React.useEffect(() => {
    if (!editorRef.current) return;

    const editorElement = editorRef.current;

    const resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        window.parent!.postMessage(
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
    if (!editorCreated) return
    if (initializedContent) return

    const clearedContent = clearContent({
      content: defaultContent,
      editor,
      allowedFolioTiptapNodeTypes: folioTiptapConfig.nodes || []
    })

    if (clearedContent) {
      editor.commands.setContent(clearedContent, { emitUpdate: false, errorOnInvalidContent: false })
    }

    setInitializedContent(true);

    window.parent!.postMessage(
      {
        type: "f-tiptap-editor:initialized-content",
        content: clearedContent,
      },
      "*",
    );
  }, [defaultContent, initializedContent, editorCreated, editor, folioTiptapConfig])

  const onContentWrapClick = React.useCallback((e: React.MouseEvent<HTMLElement>) => {
    if ((e.target as HTMLElement).classList.contains('f-tiptap-editor__content-wrap')) {
      // Clicked on the wrap, not the editor itself
      if (editor && editor.view && editor.view.dom) {
        editor.view.focus()
      }
    }
  }, [editor])

  let contentClassName = "f-tiptap-editor__content f-tiptap-styles"
  if (readonly) contentClassName += " f-tiptap-editor__content--readonly";
  if (!editorCreated || !initializedContent) return null

  return (
    <EditorContext.Provider value={{ editor }}>
      <div
        ref={editorRef}
        className={`f-tiptap-editor f-tiptap-editor--${blockEditor ? "block" : "rich-text"}${responsivePreviewEnabled ? " f-tiptap-editor--responsive-preview" : ""}`}
      >
        {readonly ? null : (
          <FolioEditorToolbar
            editor={editor}
            blockEditor={blockEditor}
            textStylesCommandGroup={textStylesCommandGroup}
            layoutsCommandGroup={layoutsCommandGroup}
            folioTiptapConfig={folioTiptapConfig}
            setResponsivePreviewEnabled={blockEditor ? setResponsivePreviewEnabled : undefined}
            autosaveIndicatorInfo={autosaveIndicatorInfo}
          />
        )}

        <FolioEditorResponsivePreview
          enabled={responsivePreviewEnabled}
          shouldScrollToInitial={shouldScrollToInitial}
          setShouldScrollToInitial={setShouldScrollToInitial}
        >
          <div className="f-tiptap-editor__content-wrap" onClick={onContentWrapClick}>
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
        </FolioEditorResponsivePreview>
      </div>
    </EditorContext.Provider>
  );
}

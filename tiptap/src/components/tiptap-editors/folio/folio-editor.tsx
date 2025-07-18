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
import { Highlight } from "@tiptap/extension-highlight";
// import { Subscript } from "@tiptap/extension-subscript";
// import { Superscript } from "@tiptap/extension-superscript";
import { Selection, Placeholder, TrailingNode } from "@tiptap/extensions";

// --- UI Primitives ---
import { Button } from "@/components/tiptap-ui-primitive/button";
import { Spacer } from "@/components/tiptap-ui-primitive/spacer";
import {
  Toolbar,
  ToolbarGroup,
  ToolbarSeparator,
} from "@/components/tiptap-ui-primitive/toolbar";

// --- Tiptap Node ---
import { FolioTiptapNodeExtension } from "@/components/tiptap-extensions/folio-tiptap-node";
import {
  FolioTiptapColumnsButton,
  FolioTiptapColumnsExtension,
  FolioTiptapColumnNode,
  FolioTiptapColumnsNode,
} from "@/components/tiptap-extensions/folio-tiptap-columns";

import "@/components/tiptap-node/image-node/image-node.scss";
import "@/components/tiptap-node/paragraph-node/paragraph-node.scss";

// --- Tiptap UI ---
import { HeadingDropdownMenu } from "@/components/tiptap-ui/heading-dropdown-menu";
import { FolioTiptapNodeButton } from "@/components/tiptap-ui/folio-tiptap-node-button";
import {
  CommandsExtension,
  suggestion,
  defaultGroupForBlock,
  defaultGroupForRichText,
  makeSuggestionItems,
} from "@/components/tiptap-ui/commands";
import { ListDropdownMenu } from "@/components/tiptap-ui/list-dropdown-menu";
import { BlockquoteButton } from "@/components/tiptap-ui/blockquote-button";
import { CodeBlockButton } from "@/components/tiptap-ui/code-block-button";
import {
  ColorHighlightPopover,
  ColorHighlightPopoverContent,
  ColorHighlightPopoverButton,
} from "@/components/tiptap-ui/color-highlight-popover";
import {
  LinkPopover,
  LinkContent,
  LinkButton,
} from "@/components/tiptap-ui/link-popover";
import { MarkButton } from "@/components/tiptap-ui/mark-button";
import { TextAlignButton } from "@/components/tiptap-ui/text-align-button";
import { UndoRedoButton } from "@/components/tiptap-ui/undo-redo-button";

// --- Icons ---
import { ArrowLeftIcon } from "@/components/tiptap-icons/arrow-left-icon";
import { HighlighterIcon } from "@/components/tiptap-icons/highlighter-icon";
import { LinkIcon } from "@/components/tiptap-icons/link-icon";
import { SmartDragHandle } from "@/components/tiptap-ui/smart-drag-handle";

// --- Hooks ---
import { useMobile } from "@/hooks/use-mobile";
import { useWindowSize } from "@/hooks/use-window-size";
import { useCursorVisibility } from "@/hooks/use-cursor-visibility";

import translate from "@/lib/i18n";
import makeFolioTiptapNodeCommandGroup from "@/lib/make-folio-tiptap-node-command-group";

import TRANSLATIONS from "./folio-editor-i18n.json";

const MainToolbarContent = ({
  onHighlighterClick,
  onLinkClick,
  isMobile,
  blockEditor,
  editor,
  folioTiptapNodes,
}: {
  onHighlighterClick: () => void;
  onLinkClick: () => void;
  isMobile: boolean;
  blockEditor: boolean;
  editor: Editor | null;
  folioTiptapNodes: FolioTiptapNodeFromInput[] | null;
}) => {
  return (
    <>
      <Spacer />

      {blockEditor ? (
        <>
        <ToolbarGroup>
          <FolioTiptapNodeButton editor={editor} />
        </ToolbarGroup>

        <ToolbarSeparator />
        </>
      ) : null}

      <ToolbarGroup>
        <UndoRedoButton action="undo" />
        <UndoRedoButton action="redo" />
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <HeadingDropdownMenu levels={[1, 2, 3, 4]} />
        <ListDropdownMenu types={["bulletList", "orderedList"]} />
        <BlockquoteButton />
        <CodeBlockButton />
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <MarkButton type="bold" />
        <MarkButton type="italic" />
        <MarkButton type="strike" />
        <MarkButton type="code" />
        <MarkButton type="underline" />
        {!isMobile ? (
          <ColorHighlightPopover />
        ) : (
          <ColorHighlightPopoverButton onClick={onHighlighterClick} />
        )}
        {!isMobile ? <LinkPopover /> : <LinkButton onClick={onLinkClick} />}
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <MarkButton type="superscript" />
        <MarkButton type="subscript" />
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <TextAlignButton align="left" />
        <TextAlignButton align="center" />
        <TextAlignButton align="right" />
      </ToolbarGroup>

      {blockEditor ? (
        <>
          <ToolbarSeparator />

          <ToolbarGroup>
            <FolioTiptapColumnsButton editor={editor} />
          </ToolbarGroup>
        </>
      ) : null}

      <Spacer />

      {isMobile && <ToolbarSeparator />}
    </>
  );
};

const MobileToolbarContent = ({
  type,
  onBack,
}: {
  type: "highlighter" | "link";
  onBack: () => void;
}) => (
  <>
    <ToolbarGroup>
      <Button data-style="ghost" onClick={onBack}>
        <ArrowLeftIcon className="tiptap-button-icon" />
        {type === "highlighter" ? (
          <HighlighterIcon className="tiptap-button-icon" />
        ) : (
          <LinkIcon className="tiptap-button-icon" />
        )}
      </Button>
    </ToolbarGroup>

    <ToolbarSeparator />

    {type === "highlighter" ? (
      <ColorHighlightPopoverContent />
    ) : (
      <LinkContent />
    )}
  </>
);

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
  const isMobile = useMobile();
  const windowSize = useWindowSize();
  const [mobileView, setMobileView] = React.useState<
    "main" | "highlighter" | "link"
  >("main");
  const toolbarRef = React.useRef<HTMLDivElement>(null);
  const editorRef = React.useRef<HTMLDivElement>(null);
  const blockEditor = type === "block";

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
        alignments: ['left', 'center', 'right'],
        types: ["heading", "paragraph"]
      }),
      TrailingNode,
      // ...(blockEditor ? [TaskList] : []),
      // ...(blockEditor ? [TaskItem.configure({ nested: true })] : []),
      Highlight.configure({ multicolor: true }),
      // ...(blockEditor ? [Image] : []),
      Typography,
      // Superscript,
      // Subscript,

      Selection,

      ...(blockEditor ? [
        FolioTiptapNodeExtension,
      ] : []),

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
      Highlight.configure({ multicolor: true }),
      // ...(blockEditor ? [Image] : []),
      Typography,
      // Superscript,
      // Subscript,

      Selection,
      ...(blockEditor ? [FolioTiptapColumnsExtension, FolioTiptapColumnsNode, FolioTiptapColumnNode] : []),

      CommandsExtension.configure({
        suggestion:
          blockEditor && folioTiptapNodes
            ? {
                ...suggestion,
                items: makeSuggestionItems([
                  defaultGroupForBlock,
                  makeFolioTiptapNodeCommandGroup(folioTiptapNodes),
                ]),
              }
            : suggestion,
      }),
    ],
  });

  const bodyRect = useCursorVisibility({
    editor,
    overlayHeight: toolbarRef.current?.getBoundingClientRect().height ?? 0,
  });

  React.useEffect(() => {
    if (!isMobile && mobileView !== "main") {
      setMobileView("main");
    }
  }, [isMobile, mobileView]);

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
        <Toolbar
          ref={toolbarRef}
          style={
            isMobile
              ? {
                  bottom: `calc(100% - ${windowSize.height - bodyRect.y}px)`,
                }
              : {}
          }
        >
          {mobileView === "main" ? (
            <MainToolbarContent
              onHighlighterClick={() => setMobileView("highlighter")}
              onLinkClick={() => setMobileView("link")}
              isMobile={isMobile}
              blockEditor={blockEditor}
              editor={editor}
              folioTiptapNodes={folioTiptapNodes}
            />
          ) : (
            <MobileToolbarContent
              type={mobileView === "highlighter" ? "highlighter" : "link"}
              onBack={() => setMobileView("main")}
            />
          )}
        </Toolbar>

        <div className="f-tiptap-editor__content-wrap">
          {blockEditor ? (
            <SmartDragHandle editor={editor} />
          ) : null}

          <EditorContent
            editor={editor}
            role="presentation"
            className="f-tiptap-editor__content f-tiptap-styles"
          />
        </div>
      </div>
    </EditorContext.Provider>
  );
}

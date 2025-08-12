import React from "react";
import { useEditorState } from "@tiptap/react";
import { type Editor } from "@tiptap/react";

import { Button } from "@/components/tiptap-ui-primitive/button";
import { Spacer } from "@/components/tiptap-ui-primitive/spacer";
import {
  Toolbar,
  ToolbarGroup,
  ToolbarSeparator,
} from "@/components/tiptap-ui-primitive/toolbar";
import { FolioTiptapNodeButton, FolioTiptapNodeButtonForSingleImage } from "@/components/tiptap-ui/folio-tiptap-node-button";
import { LinkPopover } from "@/components/tiptap-ui/link-popover";
import { MarkButton } from "@/components/tiptap-ui/mark-button";
import { UndoRedoButton } from "@/components/tiptap-ui/undo-redo-button";
import { FolioTiptapColumnsButton } from "@/components/tiptap-extensions/folio-tiptap-columns";
import { FolioTiptapShowHtmlButton } from "@/components/tiptap-extensions/folio-tiptap-show-html/folio-tiptap-show-html-button"
import { FolioTiptapEraseMarksButton } from "@/components/tiptap-extensions/folio-tiptap-erase-marks/folio-tiptap-erase-marks-button"
import { FolioEditorToolbarDropdown } from "./folio-editor-toolbar-dropdown"
import {
  ListsCommandGroup,
  LayoutsCommandGroup,
  TextAlignCommandGroup
} from '@/components/tiptap-command-groups';

interface FolioEditorToolbarButtonStateMapping {
  enabled: (params: { editor: Editor }) => boolean;
  active: (params: { editor: Editor }) => boolean;
  value?: (params: { editor: Editor }) => string | undefined;
  onlyInBlockEditor?: true;
}

interface FolioEditorToolbarStateMapping {
  undo: FolioEditorToolbarButtonStateMapping;
  redo: FolioEditorToolbarButtonStateMapping;
  bold: FolioEditorToolbarButtonStateMapping;
  italic: FolioEditorToolbarButtonStateMapping;
  strike: FolioEditorToolbarButtonStateMapping;
  underline: FolioEditorToolbarButtonStateMapping;
  superscript: FolioEditorToolbarButtonStateMapping;
  subscript: FolioEditorToolbarButtonStateMapping;
  link: FolioEditorToolbarButtonStateMapping;
  lists: FolioEditorToolbarButtonStateMapping;
  erase: FolioEditorToolbarButtonStateMapping;
  textStyles: FolioEditorToolbarButtonStateMapping;
  textAlign: FolioEditorToolbarButtonStateMapping;
  layouts: FolioEditorToolbarButtonStateMapping;
}

export interface FolioEditorToolbarButtonState {
  enabled: boolean;
  active: boolean;
  value?: string;
}

type FolioEditorToolbarKey = keyof FolioEditorToolbarStateMapping;

type FolioEditorToolbarState = {
  [K in FolioEditorToolbarKey]: FolioEditorToolbarButtonState;
};

interface FolioEditorToolbarProps {
  editor: Editor;
  blockEditor: boolean;
  folioTiptapConfig?: FolioTiptapConfig;
  textStylesCommandGroup: FolioEditorCommandGroup;
}

const makeMarkEnabled =
  (type: keyof FolioEditorToolbarStateMapping) =>
  ({ editor }: { editor: Editor }) =>
    editor!.isActive("codeBlock") && editor!.can().toggleMark(type);

const makeMarkActive =
  (type: keyof FolioEditorToolbarStateMapping) =>
  ({ editor }: { editor: Editor }) =>
    editor!.isActive(type);

const toolbarStateMapping: FolioEditorToolbarStateMapping = {
  undo: {
    enabled: ({ editor }) => editor!.can().undo(),
    active: ({ editor }) => false,
  },
  redo: {
    enabled: ({ editor }) => editor!.can().redo(),
    active: ({ editor }) => false,
  },
  bold: { enabled: makeMarkEnabled("bold"), active: makeMarkActive("bold") },
  italic: {
    enabled: makeMarkEnabled("italic"),
    active: makeMarkActive("italic"),
  },
  strike: {
    enabled: makeMarkEnabled("strike"),
    active: makeMarkActive("strike"),
  },
  underline: {
    enabled: makeMarkEnabled("underline"),
    active: makeMarkActive("underline"),
  },
  superscript: {
    enabled: makeMarkEnabled("superscript"),
    active: makeMarkActive("superscript"),
  },
  subscript: {
    enabled: makeMarkEnabled("subscript"),
    active: makeMarkActive("subscript"),
  },
  link: {
    enabled: ({ editor }) => editor.can().setLink?.({ href: "" }),
    active: makeMarkActive("link"),
  },
  textAlign: {
    enabled: ({ editor }) => editor.can().setTextAlign("left") || editor.can().setTextAlign("center"),
    active: ({ editor }) => (editor.isActive({ textAlign: 'center' }) || editor.isActive({ textAlign: 'right' })),
    value: ({ editor }) => {
      if (editor.isActive({ textAlign: 'left' })) {
        return 'align-left';
      } else if (editor.isActive({ textAlign: 'center' })) {
        return 'align-center';
      } else if (editor.isActive({ textAlign: 'right' })) {
        return 'align-right';
      }

      return undefined;
    }
  },
  erase: {
    enabled: ({ editor }) => {
      let hasAnyMarks = false
      const selection = editor.view.state.selection

      if (selection.empty) {
        // If the selection is empty, we check if the current node has any marks
        const node = editor.view.state.doc.nodeAt(selection.from);

        if (node && node.marks && node.marks.length > 0) {
          hasAnyMarks = true;
        }
      } else {
        editor.view.state.doc.nodesBetween(selection.from, selection.to, (node) => {
          if (node.marks && node.marks.length > 0) {
            hasAnyMarks = true;
            return false
          }
        })
      }

      return hasAnyMarks
    },
    active: ({ editor }) => false,
  },
  textStyles: {
    enabled: ({ editor }) => editor.can().toggleNode("heading", "paragraph"),
    active: ({ editor }) => editor!.isActive("heading") || editor!.isActive("folioTiptapStyledParagraph"),
    value: ({ editor }) => {
      if (editor!.isActive("heading")) {
        const attr = editor!.getAttributes("heading");

        if (attr && attr.level) {
          return `heading-${attr.level}`
        }
      } else if (editor!.isActive("folioTiptapStyledParagraph")) {
        const attr = editor!.getAttributes("folioTiptapStyledParagraph");

        if (attr && attr.variant) {
          return `folioTiptapStyledParagraph-${attr.variant}`;
        }
      } else if (editor!.isActive("paragraph")) {
        return "paragraph"
      }

      return undefined;
    },
  },
  lists: {
    enabled: ({ editor }) => editor.can().toggleBulletList() || editor.can().toggleOrderedList(),
    active: ({ editor }) => editor.isActive("bulletList") || editor.isActive("orderedList"),
    value: ({ editor }) => {
      if (editor.isActive("bulletList")) {
        return "bulletList";
      } else if (editor.isActive("orderedList")) {
        return "orderedList";
      }

      return undefined;
    },
  },
  layouts: {
    onlyInBlockEditor: true,
    enabled: ({ editor }) => editor.can().insertFolioTiptapColumns() || editor.can().insertTable(),
    active: ({ editor }) => false,
    value: ({ editor }) => {
      if (editor.isActive("folioTiptapColumns")) {
        return "folioTiptapColumns";
      } else if (editor.isActive("table")) {
        return "table";
      }

      return undefined;
    },
  }
};

const getToolbarState = ({
  editor,
  blockEditor,
}: {
  editor: Editor;
  blockEditor: boolean;
}): FolioEditorToolbarState => {
  const state: Partial<
    Record<keyof FolioEditorToolbarStateMapping, FolioEditorToolbarButtonState>
  > = {};
  let keys = Object.keys(
    toolbarStateMapping,
  ) as (keyof FolioEditorToolbarStateMapping)[];

  if (!blockEditor) {
    keys = keys.filter((key) => !toolbarStateMapping[key].onlyInBlockEditor)
  }

  if (editor && editor.isEditable) {
    keys.forEach((key: keyof FolioEditorToolbarStateMapping) => {
      state[key] = {
        enabled: toolbarStateMapping[key].enabled({ editor }),
        active: toolbarStateMapping[key].active({ editor }),
        value: toolbarStateMapping[key].value ? toolbarStateMapping[key].value({ editor }) : undefined,
      };
    });
  } else {
    keys.forEach((key: keyof FolioEditorToolbarStateMapping) => {
      state[key] = {
        enabled: false,
        active: false,
      };
    });
  }

  return state as FolioEditorToolbarState;
};

const MainToolbarContent = ({
  blockEditor,
  editor,
  folioTiptapConfig,
  textStylesCommandGroup,
}: {
  blockEditor: boolean;
  editor: Editor;
  folioTiptapConfig?: FolioTiptapConfig;
  textStylesCommandGroup: FolioEditorCommandGroup;
}) => {
  const editorState: FolioEditorToolbarState = useEditorState({
    editor,

    // the selector function is used to select the state you want to react to
    selector: ({ editor }) => {
      return getToolbarState({ editor, blockEditor });
    },
  });

  const singleImageNodeForToolbar = React.useMemo(() => {
    if (blockEditor && folioTiptapConfig?.nodes) {
      const node = folioTiptapConfig.nodes.find((node) => (
        node.config && node.config.use_as_single_image_in_toolbar
      ))

      return node || null;
    }

    return null;
  }, [blockEditor, folioTiptapConfig && folioTiptapConfig.nodes])

  return (
    <>
      {blockEditor ? (
        <>
          <ToolbarGroup>
            <FolioTiptapNodeButton editor={editor} />
          </ToolbarGroup>

          <ToolbarSeparator />
        </>
      ) : null}

      <ToolbarGroup>
        <UndoRedoButton
          action="undo"
          active={editorState["undo"].active}
          enabled={editorState["undo"].enabled}
        />
        <UndoRedoButton
          action="redo"
          active={editorState["redo"].active}
          enabled={editorState["redo"].enabled}
        />
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <FolioEditorToolbarDropdown
          editorState={editorState["textStyles"]}
          commandGroup={textStylesCommandGroup}
          editor={editor}
        />

        <FolioEditorToolbarDropdown
          editorState={editorState["lists"]}
          commandGroup={ListsCommandGroup}
          editor={editor}
        />
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <MarkButton editor={editor} type="bold" />
        <MarkButton editor={editor} type="italic" />
        <MarkButton editor={editor} type="underline" />
        <MarkButton editor={editor} type="strike" />

        <LinkPopover
          editor={editor}
          editorState={editorState["link"]}
        />
      </ToolbarGroup>

      <ToolbarSeparator />

      {blockEditor && (
        <>
          <ToolbarGroup>
            <MarkButton editor={editor} type="superscript" />
            <MarkButton editor={editor} type="subscript" />
          </ToolbarGroup>

          <ToolbarSeparator />
        </>
      )}

      <ToolbarGroup>
        <FolioTiptapEraseMarksButton editor={editor} enabled={editorState["erase"].enabled} />
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <FolioEditorToolbarDropdown
          editorState={editorState["textAlign"]}
          commandGroup={TextAlignCommandGroup}
          editor={editor}
        />
      </ToolbarGroup>

      {blockEditor ? (
        <>
          <ToolbarSeparator />

          <ToolbarGroup>
            <FolioEditorToolbarDropdown
              editorState={editorState["layouts"]}
              commandGroup={LayoutsCommandGroup}
              editor={editor}
            />
          </ToolbarGroup>

          {singleImageNodeForToolbar ? (
            <>
              <ToolbarSeparator />

              <ToolbarGroup>
                <FolioTiptapNodeButtonForSingleImage
                  editor={editor}
                  singleImageNodeForToolbar={singleImageNodeForToolbar}
                />
              </ToolbarGroup>
            </>
          ) : null}
        </>
      ) : null}

      <ToolbarSeparator />

      <ToolbarGroup>
        <FolioTiptapShowHtmlButton editor={editor} />
      </ToolbarGroup>

      <Spacer />
    </>
  );
};

export function FolioEditorToolbar({
  editor,
  blockEditor,
  folioTiptapConfig,
  textStylesCommandGroup,
}: FolioEditorToolbarProps) {
  if (!editor) return null;

  return (
    <Toolbar>
      <MainToolbarContent
        blockEditor={blockEditor}
        editor={editor}
        folioTiptapConfig={folioTiptapConfig}
        textStylesCommandGroup={textStylesCommandGroup}
      />
    </Toolbar>
  );
}

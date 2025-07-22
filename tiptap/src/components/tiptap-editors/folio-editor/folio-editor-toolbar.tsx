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
import { FolioTiptapNodeButton } from "@/components/tiptap-ui/folio-tiptap-node-button";
import {
  LinkPopover,
  LinkContent,
  LinkButton,
} from "@/components/tiptap-ui/link-popover";
import { MarkButton } from "@/components/tiptap-ui/mark-button";
import { TextAlignButton } from "@/components/tiptap-ui/text-align-button";
import { UndoRedoButton } from "@/components/tiptap-ui/undo-redo-button";
import { FolioTiptapColumnsButton } from "@/components/tiptap-extensions/folio-tiptap-columns";
import { FolioTiptapEraseMarksButton } from "@/components/tiptap-extensions/folio-tiptap-erase-marks/folio-tiptap-erase-marks-button"
import { FolioEditorToolbarDropdown } from "./folio-editor-toolbar-dropdown"
import { TextStylesCommandGroup, ListsCommandGroup, LayoutsCommandGroup } from '@/components/tiptap-command-groups';

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
  lists: FolioEditorToolbarButtonStateMapping;
  erase: FolioEditorToolbarButtonStateMapping;
  textStyles: FolioEditorToolbarButtonStateMapping;
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
    active: ({ editor }) => editor!.isActive("heading") || editor!.isActive("styledParagraph"),
    value: ({ editor }) => {
      if (editor!.isActive("heading")) {
        const attr = editor!.getAttributes("heading");

        if (attr && attr.level) {
          return `heading-${attr.level}`
        }
      } else if (editor!.isActive("styledParagraph")) {
        const attr = editor!.getAttributes("styledParagraph");

        if (attr && attr.variant) {
          return `styledParagraph-${attr.variant}`;
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
}: {
  blockEditor: boolean;
  editor: Editor;
}) => {
  const editorState: FolioEditorToolbarState = useEditorState({
    editor,

    // the selector function is used to select the state you want to react to
    selector: ({ editor }) => {
      return getToolbarState({ editor, blockEditor });
    },
  });

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
          commandGroup={TextStylesCommandGroup}
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
        <LinkPopover />
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
        <TextAlignButton align="left" />
        <TextAlignButton align="center" />
        <TextAlignButton align="right" />
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
        </>
      ) : null}

      <Spacer />
    </>
  );
};

export function FolioEditorToolbar({
  editor,
  blockEditor,
}: FolioEditorToolbarProps) {
  if (!editor) return null;

  return (
    <Toolbar>
      <MainToolbarContent
        blockEditor={blockEditor}
        editor={editor}
      />
    </Toolbar>
  );
}

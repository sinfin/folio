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
import { HeadingDropdownMenu } from "@/components/tiptap-ui/heading-dropdown-menu";
import { FolioTiptapColumnsButton } from "@/components/tiptap-extensions/folio-tiptap-columns";

interface FolioEditorToolbarButtonStateMapping {
  enabled: (params: { editor: Editor }) => boolean;
  active: (params: { editor: Editor }) => boolean;
}

interface FolioEditorToolbarStateMapping {
  undo: FolioEditorToolbarButtonStateMapping;
  redo: FolioEditorToolbarButtonStateMapping;
  bold: FolioEditorToolbarButtonStateMapping;
  italic: FolioEditorToolbarButtonStateMapping;
  strike: FolioEditorToolbarButtonStateMapping;
  code: FolioEditorToolbarButtonStateMapping;
  underline: FolioEditorToolbarButtonStateMapping;
}

interface FolioEditorToolbarButtonState {
  enabled: boolean;
  active: boolean;
}

interface FolioEditorToolbarState {
  undo: FolioEditorToolbarButtonState;
  redo: FolioEditorToolbarButtonState;
  bold: FolioEditorToolbarButtonState;
  italic: FolioEditorToolbarButtonState;
  strike: FolioEditorToolbarButtonState;
  code: FolioEditorToolbarButtonState;
  underline: FolioEditorToolbarButtonState;
}

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
  code: { enabled: makeMarkEnabled("code"), active: makeMarkActive("code") },
  underline: {
    enabled: makeMarkEnabled("underline"),
    active: makeMarkActive("underline"),
  },
};

const getToolbarState = ({
  editor,
}: {
  editor: Editor;
}): FolioEditorToolbarState => {
  const state: Partial<
    Record<keyof FolioEditorToolbarStateMapping, FolioEditorToolbarButtonState>
  > = {};
  const keys = Object.keys(
    toolbarStateMapping,
  ) as (keyof FolioEditorToolbarStateMapping)[];

  if (editor && editor.isEditable) {
    keys.forEach((key: keyof FolioEditorToolbarStateMapping) => {
      state[key] = {
        enabled: toolbarStateMapping[key].enabled({ editor }),
        active: toolbarStateMapping[key].active({ editor }),
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
      return getToolbarState({ editor });
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
        <HeadingDropdownMenu levels={[1, 2, 3, 4]} />
        <ListDropdownMenu types={["bulletList", "orderedList"]} />
        <BlockquoteButton />
        <CodeBlockButton />
      </ToolbarGroup>

      <ToolbarSeparator />

      <ToolbarGroup>
        <MarkButton editor={editor} type="bold" />
        <MarkButton editor={editor} type="italic" />
        <MarkButton editor={editor} type="strike" />
        <MarkButton editor={editor} type="code" />
        <MarkButton editor={editor} type="underline" />
        <ColorHighlightPopover />
        <LinkPopover />
      </ToolbarGroup>

      <ToolbarSeparator />

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
      <MainToolbarContent blockEditor={blockEditor} editor={editor} />
    </Toolbar>
  );
}

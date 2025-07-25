import { type EditorState, TextSelection } from "@tiptap/pm/state";
import { type Node } from "@tiptap/pm/model";
import { findParentNode, type Editor } from "@tiptap/core";
import { FolioTiptapFloatNode } from "./folio-tiptap-float-node";
import { FolioTiptapFloatLayoutNode } from "./folio-tiptap-float-layout-node";

export interface InsertFolioTiptapFloatLayoutArgs {
  tr: any; // Transaction type from ProseMirror
  dispatch?: (tr: any) => void; // Dispatch function for the transaction (optional)
  editor: Editor;
}

export const insertFolioTiptapFloatLayout = ({
  tr,
  dispatch,
  editor,
}: InsertFolioTiptapFloatLayoutArgs) => {
  const children = [
    editor.schema.nodes.folioTiptapFloat.createAndFill({}) as Node,
    editor.schema.nodes.paragraph.createAndFill({}) as Node,
  ];

  const node = editor.schema.nodes.folioTiptapFloatLayout.createChecked(
    {},
    children,
  );

  if (dispatch) {
    const offset = tr.selection.anchor + 1;

    tr.replaceSelectionWith(node)
      .scrollIntoView()
      .setSelection(TextSelection.near(tr.doc.resolve(offset)));

    dispatch(tr);
  }

  return true;
};

export interface SetFloatLayoutAttributesAttrs {
  side?: "left" | "right";
  size?: "small" | "medium" | "large";
}

export interface SetFloatLayoutAttributesArgs
  extends InsertFolioTiptapFloatLayoutArgs {
  attrs: SetFloatLayoutAttributesAttrs;
  state: EditorState;
}

export const setFloatLayoutAttributes = ({
  attrs,
  tr,
  dispatch,
  state,
  editor,
}: SetFloatLayoutAttributesArgs) => {
  const floatLayoutNode = findParentNode(
    (node: Node) => node.type.name === FolioTiptapFloatLayoutNode.name,
  )(state.selection);
  if (!floatLayoutNode) return false;

  let changed = false;
  const newAttrs = {
    side: floatLayoutNode.node.attrs.side || "left",
    size: floatLayoutNode.node.attrs.size || "medium",
  };

  if (attrs.side && attrs.side !== newAttrs.side) {
    if (["left", "right"].includes(attrs.side)) {
      newAttrs.side = attrs.side;
      changed = true;
    }
  }

  if (attrs.size && attrs.size !== newAttrs.size) {
    if (["small", "medium", "large"].includes(attrs.size)) {
      newAttrs.size = attrs.size;
      changed = true;
    }
  }

  if (!changed) return false;

  if (dispatch) {
    tr.setSelection(
      TextSelection.near(tr.doc.resolve(floatLayoutNode.pos + 1)),
    );

    tr.setNodeMarkup(floatLayoutNode.pos, undefined, newAttrs);

    dispatch(tr);
  }

  return true;
};

export function goToFloatOrBack({
  state,
  dispatch,
}: {
  state: EditorState;
  dispatch: any;
}) {
  const floatLayoutNode = findParentNode(
    (node: Node) => node.type.name === FolioTiptapFloatLayoutNode.name,
  )(state.selection);

  if (dispatch && floatLayoutNode) {
    const listNode = findParentNode(
      (node: Node) => node.type.name === "listItem",
    )(state.selection);

    // don't override tab inside lists
    if (listNode) return false

    const floatNode = findParentNode(
      (node: Node) => node.type.name === FolioTiptapFloatNode.name,
    )(state.selection);

    const tr = state.tr;

    if (floatNode) {
      // move selection after the node
      const nextSelectPos = floatNode.pos + floatNode.node.nodeSize;
      tr.setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));
    } else {
      // move selection inside the node
      const nextSelectPos = floatLayoutNode.pos + 1;
      tr.setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));
    }

    dispatch(tr);
    return true;
  }

  return false;
}

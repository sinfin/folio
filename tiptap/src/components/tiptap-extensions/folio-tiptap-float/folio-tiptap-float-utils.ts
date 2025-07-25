import { type EditorState, TextSelection } from "@tiptap/pm/state";
import { Node } from "@tiptap/pm/model";
import { findParentNode, type Editor } from "@tiptap/core";
import { FolioTiptapFloatNode } from "./folio-tiptap-float-node";
import { FolioTiptapFloatAsideNode } from "./folio-tiptap-float-aside-node";

export interface InsertFolioTiptapFloatArgs {
  tr: any; // Transaction type from ProseMirror
  dispatch?: (tr: any) => void; // Dispatch function for the transaction (optional)
  editor: Editor;
}

export const insertFolioTiptapFloat = ({
  tr,
  dispatch,
  editor,
}: InsertFolioTiptapFloatArgs) => {
  const children = [
    editor.schema.nodes.folioTiptapFloatAside.createAndFill({}) as Node,
    editor.schema.nodes.folioTiptapFloatMain.createAndFill({}) as Node,
  ];

  const node = editor.schema.nodes.folioTiptapFloat.createChecked(
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
  extends InsertFolioTiptapFloatArgs {
  attrs: SetFloatLayoutAttributesAttrs;
  state: EditorState;
}

export const setFolioTiptapFloatAttributes = ({
  attrs,
  tr,
  dispatch,
  state,
  editor,
}: SetFloatLayoutAttributesArgs) => {
  const floatNode = findParentNode(
    (node: Node) => node.type.name === FolioTiptapFloatNode.name,
  )(state.selection);
  if (!floatNode) return false;

  let changed = false;
  const newAttrs = {
    side: floatNode.node.attrs.side || "left",
    size: floatNode.node.attrs.size || "medium",
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
      TextSelection.near(tr.doc.resolve(floatNode.pos + 1)),
    );

    tr.setNodeMarkup(floatNode.pos, undefined, newAttrs);

    dispatch(tr);
  }

  return true;
};

export function goToFolioTiptapFloatAsideOrMain({
  state,
  dispatch,
}: {
  state: EditorState;
  dispatch: any;
}) {
  const floatNode = findParentNode(
    (node: Node) => node.type.name === FolioTiptapFloatNode.name,
  )(state.selection);

  if (dispatch && floatNode) {
    const listNode = findParentNode(
      (node: Node) => node.type.name === "listItem",
    )(state.selection);

    // don't override tab inside lists
    if (listNode) return false

    const asideNode = findParentNode(
      (node: Node) => node.type.name === FolioTiptapFloatAsideNode.name,
    )(state.selection);

    const tr = state.tr;

    if (asideNode) {
      // move selection after the node
      const nextSelectPos = asideNode.pos + asideNode.node.nodeSize;
      tr.setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));
    } else {
      // move selection inside the node
      const nextSelectPos = floatNode.pos + 1;
      tr.setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));
    }

    dispatch(tr);
    return true;
  }

  return false;
}

interface CancelFolioTiptapFloatArgs extends InsertFolioTiptapFloatArgs {
  state: EditorState;
}

interface NodeJson {
  type: string;
  content: NodeJson[];
}

export function cancelFolioTiptapFloat ({
  tr,
  dispatch,
  state,
  editor,
}: CancelFolioTiptapFloatArgs) {
  const floatNode = findParentNode(
    (node: Node) => node.type.name === FolioTiptapFloatNode.name,
  )(state.selection);

  if (!floatNode) return false
  if (!dispatch) return false

  const allContent = [];

  // loop all child nodes and gather their content
  floatNode.node.toJSON().content.forEach((childNode: NodeJson) => {
    if (childNode.content && childNode.content.length > 0) {
      childNode.content.forEach((contentNode: NodeJson) => {
        if (contentNode) {
          if (contentNode.type === "paragraph" && contentNode.content.length === 0) {
            // skip empty paragraphs
            return;
          }
          allContent.push(contentNode)
        }
      })
    }
  });

  // If no content, add an empty paragraph
  if (allContent.length === 0) {
    allContent.push({ type: "paragraph" });
  }

  // Replace the entire float node with the combined content
  tr.replaceWith(
    floatNode.pos,
    floatNode.pos + floatNode.node.nodeSize,
    allContent.map((content) => Node.fromJSON(state.schema, content)),
  );

  // Position cursor at the start of the replaced content
  tr.setSelection(
    TextSelection.near(tr.doc.resolve(floatNode.pos + 1)),
  );

  dispatch(tr);

  return true
};

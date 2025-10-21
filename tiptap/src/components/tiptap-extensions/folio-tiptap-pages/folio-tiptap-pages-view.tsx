import React, { useEffect } from "react";
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from "@tiptap/react";
import { findParentNode } from "@tiptap/core";
import { toggleFolioTiptapPageCollapsed } from "./folio-tiptap-pages-utils";

type FolioTiptapPagesViewProps = NodeViewProps;

export const FolioTiptapPagesView: React.FC<FolioTiptapPagesViewProps> = ({
  node,
  getPos,
  editor,
}) => {
  useEffect(() => {
    if (!editor) return;

    const handleSelectionUpdate = () => {
      // Find if cursor is inside any page
      const pageNode = findParentNode(
        (node) => node.type.name === "folioTiptapPage",
      )(editor.state.selection);

      if (pageNode && pageNode.node.attrs.collapsed) {
        // Cursor is inside a collapsed page - uncollapse it
        toggleFolioTiptapPageCollapsed({
          state: editor.state,
          dispatch: editor.view.dispatch,
          node: pageNode.node,
          getPos: () => pageNode.pos,
        });
      }
    };

    editor.on("selectionUpdate", handleSelectionUpdate);

    return () => {
      editor.off("selectionUpdate", handleSelectionUpdate);
    };
  }, [editor, node, getPos]);

  if (!editor) return null;

  return (
    <NodeViewWrapper className="f-tiptap-pages__view">
      <NodeViewContent className="f-tiptap-pages__content" />
    </NodeViewWrapper>
  );
};

export default FolioTiptapPagesView;

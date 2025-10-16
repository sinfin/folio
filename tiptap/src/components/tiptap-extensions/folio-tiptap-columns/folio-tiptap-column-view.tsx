import React from "react";
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from "@tiptap/react";
import ParagraphPlaceholder from "@/components/tiptap-ui/paragraph-placeholder/paragraph-placeholder";

type FolioTiptapColumnViewProps = NodeViewProps;

export const FolioTiptapColumnView: React.FC<FolioTiptapColumnViewProps> = ({
  editor,
  getPos,
}) => {
  if (!editor) return null;

  return (
    <NodeViewWrapper>
      <NodeViewContent />
      <ParagraphPlaceholder editor={editor} getPos={getPos} target="column" />
    </NodeViewWrapper>
  );
};

export default FolioTiptapColumnView;

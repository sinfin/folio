import React from "react";
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from "@tiptap/react";
import HasParagraphPlaceholder from "@/components/tiptap-ui/paragraph-placeholder/has-paragraph-placeholder";

type FolioTiptapColumnViewProps = NodeViewProps;

export const FolioTiptapColumnView: React.FC<FolioTiptapColumnViewProps> = ({
  editor,
  getPos,
}) => {
  if (!editor) return null;

  return (
    <NodeViewWrapper>
      <HasParagraphPlaceholder editor={editor} getPos={getPos} target="column">
        <NodeViewContent />
      </HasParagraphPlaceholder>
    </NodeViewWrapper>
  );
};

export default FolioTiptapColumnView;

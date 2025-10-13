import React from "react";
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from "@tiptap/react";
import ParagraphPlaceholder from "@/components/tiptap-ui/paragraph-placeholder/paragraph-placeholder";

type FolioTiptapFloatAsideViewProps = NodeViewProps;

export const FolioTiptapFloatAsideView: React.FC<
  FolioTiptapFloatAsideViewProps
> = ({ editor, getPos }) => {
  if (!editor) return null;

  return (
    <NodeViewWrapper>
      <NodeViewContent />
      <ParagraphPlaceholder editor={editor} getPos={getPos} />
    </NodeViewWrapper>
  );
};

export default FolioTiptapFloatAsideView;

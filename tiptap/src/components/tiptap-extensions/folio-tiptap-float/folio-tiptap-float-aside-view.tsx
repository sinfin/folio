import React from "react";
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from "@tiptap/react";
import HasParagraphPlaceholder from "@/components/tiptap-ui/paragraph-placeholder/has-paragraph-placeholder";

type FolioTiptapFloatAsideViewProps = NodeViewProps;

export const FolioTiptapFloatAsideView: React.FC<
  FolioTiptapFloatAsideViewProps
> = ({ editor, getPos }) => {
  if (!editor) return null;

  return (
    <NodeViewWrapper>
      <HasParagraphPlaceholder
        editor={editor}
        getPos={getPos}
        target="float-aside"
      >
        <NodeViewContent />
      </HasParagraphPlaceholder>
    </NodeViewWrapper>
  );
};

export default FolioTiptapFloatAsideView;

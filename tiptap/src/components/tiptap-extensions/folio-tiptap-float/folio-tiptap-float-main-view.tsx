import React from "react";
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from "@tiptap/react";
import HasParagraphPlaceholder from "@/components/tiptap-ui/paragraph-placeholder/has-paragraph-placeholder";

type FolioTiptapFloatMainViewProps = NodeViewProps;

export const FolioTiptapFloatMainView: React.FC<
  FolioTiptapFloatMainViewProps
> = ({ editor, getPos }) => {
  if (!editor) return null;

  return (
    <NodeViewWrapper>
      <HasParagraphPlaceholder
        editor={editor}
        getPos={getPos}
        target="float-main"
      >
        <NodeViewContent />
      </HasParagraphPlaceholder>
    </NodeViewWrapper>
  );
};

export default FolioTiptapFloatMainView;

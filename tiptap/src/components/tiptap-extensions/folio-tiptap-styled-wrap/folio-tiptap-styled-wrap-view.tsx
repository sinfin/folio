import React from "react";
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from "@tiptap/react";
import ParagraphPlaceholder from "@/components/tiptap-ui/paragraph-placeholder/paragraph-placeholder";

type FolioTiptapStyledWrapViewProps = NodeViewProps;

export const FolioTiptapStyledWrapView: React.FC<
  FolioTiptapStyledWrapViewProps
> = ({ node, editor, getPos }) => {
  if (!editor) return null;

  const variant = node.attrs.variant;
  const className =
    "node-folioTiptapStyledWrap f-tiptap-styled-wrap f-tiptap-avoid-external-layout";
  const dataAttributes = variant
    ? { "data-f-tiptap-styled-wrap-variant": variant }
    : {};

  return (
    <NodeViewWrapper className={className} {...dataAttributes}>
      <NodeViewContent />
      <ParagraphPlaceholder editor={editor} getPos={getPos} />
    </NodeViewWrapper>
  );
};

export default FolioTiptapStyledWrapView;

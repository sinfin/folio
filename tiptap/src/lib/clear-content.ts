import type { JSONContent } from "@tiptap/react";

const BLOCK_EDITOR_ONLY_NODE_TYPES = [
  "table",
  "folioTiptapNode",
  "folioTiptapColumns",
];

// Type guard to ensure proper typing after filtering
const isJSONContent = (node: JSONContent | undefined): node is JSONContent => !!node;

const removeUnsupportedNodesInContent = (
  content: JSONContent | undefined
): JSONContent | undefined => {
  if (!content) return content;

  // If this is a node with a type to remove, return undefined (remove it)
  if (content.type && BLOCK_EDITOR_ONLY_NODE_TYPES.includes(content.type)) {
    console.error(`Removed unsupported node type: ${content.type}`);
    return undefined;
  }

  // If this node has children, process them recursively
  if (Array.isArray(content.content)) {
    const filtered = content.content
      .map(removeUnsupportedNodesInContent)
      .filter(isJSONContent); // Only keep valid JSONContent nodes

    return { ...content, content: filtered };
  }

  // Otherwise, return the node as is
  return content;
};

export const clearContent = ({
  content,
  blockEditor,
}: {
  content?: JSONContent;
  blockEditor: boolean;
}): JSONContent | undefined => {
  if (!content) {
    return content;
  }

  if (blockEditor) {
    return content;
  }

  return removeUnsupportedNodesInContent(content);
};

export default clearContent;

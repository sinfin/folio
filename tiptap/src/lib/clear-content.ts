import type { JSONContent } from "@tiptap/react";
import type { Editor } from "@tiptap/core";

export type FolioTiptapNodeFromInput = {
  type: string;
};

const BLOCK_EDITOR_ONLY_NODE_TYPES = [
  "table",
  "folioTiptapNode",
  "folioTiptapColumns",
  "folioTiptapColumn",
  "folioTiptapFloat",
  "folioTiptapFloatAside",
  "folioTiptapFloatMain",
];

const replaceUnsupportedNodesInContent = ({
  content,
  schema,
  allowedNodeTypes
}: {
  content?: JSONContent | undefined;
  schema: any; // Editor's schema type
  allowedNodeTypes?: string[];
}): JSONContent | undefined => {
  if (!content) return content;

  // If this is a node not from schema, change it to folioTiptapInvalidNode
  if (content.type && !schema.nodes[content.type]) {
    console.error(`Removed unsupported node type: ${content.type}`);
    return {
      type: "folioTiptapInvalidNode",
      attrs: {
        invalidNodeHash: content,
      },
    };
  }

  // If this is a folioTiptapNode, check if its type is allowed
  if (content.type === "folioTiptapNode" && allowedNodeTypes && allowedNodeTypes.length > 0) {
    const nodeType = content.attrs?.type;
    if (nodeType && !allowedNodeTypes.includes(nodeType)) {
      console.error(`Removed disallowed folioTiptapNode type: ${nodeType}`);
      return {
        type: "folioTiptapInvalidNode",
        attrs: {
          invalidNodeHash: content,
        },
      };
    }
  }

  // If this node has children, process them recursively
  if (Array.isArray(content.content)) {
    const replaced: JSONContent[] = []

    content.content.forEach((child) => {
      const handledChild = replaceUnsupportedNodesInContent({ content: child, schema, allowedNodeTypes })
      if (handledChild) {
        // If the child is a valid node, add it to the replaced array
        replaced.push(handledChild);
      }
    })

    return { ...content, content: replaced };
  }

  // Otherwise, return the node as is
  return content;
};

export const clearContent = ({
  content,
  editor,
  allowedFolioTiptapNodeTypes,
}: {
  content?: JSONContent;
  editor: Editor;
  allowedFolioTiptapNodeTypes?: FolioTiptapNodeFromInput[];
}): JSONContent | undefined => {
  if (!content) {
    return content;
  }

  const allowedNodeTypes = allowedFolioTiptapNodeTypes?.map(node => node.type);
  return replaceUnsupportedNodesInContent({ content, schema: editor.schema, allowedNodeTypes });
};

export default clearContent;

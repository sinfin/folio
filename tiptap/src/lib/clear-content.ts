import type { JSONContent } from "@tiptap/react";
import type { Editor } from "@tiptap/core";

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
  schema
}: {
  content?: JSONContent | undefined;
  schema: any; // Editor's schema type
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

  // If this node has children, process them recursively
  if (Array.isArray(content.content)) {
    const replaced: JSONContent[] = []

    content.content.forEach((child) => {
      const handledChild = replaceUnsupportedNodesInContent({ content: child, schema })
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
}: {
  content?: JSONContent;
  editor: Editor;
}): JSONContent | undefined => {
  if (!content) {
    return content;
  }

  return replaceUnsupportedNodesInContent({ content, schema: editor.schema });
};

export default clearContent;

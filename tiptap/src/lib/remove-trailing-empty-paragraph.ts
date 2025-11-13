import type { JSONContent } from "@tiptap/react";

/**
 * Removes the trailing empty paragraph added by TrailingNode extension
 * from the root level of the document.
 *
 * @param node - The JSONContent node (typically a doc node)
 * @returns The cleaned JSONContent with trailing empty paragraph removed
 */
export const removeTrailingEmptyParagraph = (
  node: JSONContent,
): JSONContent => {
  // Check if this is a doc node with content
  if (
    node.type === "doc" &&
    node.content &&
    Array.isArray(node.content) &&
    node.content.length > 0
  ) {
    const lastItem = node.content[node.content.length - 1];

    // Check if the last item is an empty paragraph
    const isEmptyParagraph =
      lastItem.type === "paragraph" &&
      (!lastItem.content || lastItem.content.length === 0);

    if (isEmptyParagraph) {
      // Only create a new node if we need to remove the trailing paragraph
      return {
        ...node,
        content: node.content.slice(0, -1),
      };
    }
  }

  // Return original node if no changes needed
  return node;
};

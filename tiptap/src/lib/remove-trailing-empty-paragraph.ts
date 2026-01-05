import type { JSONContent } from "@tiptap/react";

/**
 * Checks if a node is an empty paragraph.
 *
 * @param node - The JSONContent node to check
 * @returns True if the node is a paragraph with no content
 */
const isEmptyParagraph = (node: JSONContent): boolean => {
  return (
    node.type === "paragraph" && (!node.content || node.content.length === 0)
  );
};

/**
 * Recursively removes trailing empty paragraphs from block elements.
 * Removes trailing empty paragraphs from the root level and all nested block elements,
 * but only if they follow other content (not if they're the only item).
 *
 * @param node - The JSONContent node to process
 * @returns The cleaned JSONContent with trailing empty paragraphs removed
 */
const removeTrailingEmptyParagraphRecursive = (
  node: JSONContent,
): JSONContent => {
  // Early return if no content to process
  if (
    !node.content ||
    !Array.isArray(node.content) ||
    node.content.length === 0
  ) {
    return node;
  }

  // Recursively process all children
  const processedContent = node.content.map((child) =>
    removeTrailingEmptyParagraphRecursive(child),
  );

  // Remove trailing empty paragraph if it follows other content
  if (
    processedContent.length > 1 &&
    isEmptyParagraph(processedContent[processedContent.length - 1])
  ) {
    return {
      ...node,
      content: processedContent.slice(0, -1),
    };
  }

  // Return node with processed content
  return {
    ...node,
    content: processedContent,
  };
};

/**
 * Removes the trailing empty paragraph added by TrailingNode extension
 * from the root level of the document and recursively from all nested block elements.
 *
 * @param node - The JSONContent node (typically a doc node)
 * @returns The cleaned JSONContent with trailing empty paragraphs removed
 */
export const removeTrailingEmptyParagraph = (
  node: JSONContent,
): JSONContent => {
  return removeTrailingEmptyParagraphRecursive(node);
};

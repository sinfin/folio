import { makeUniqueId } from "./make-unique-id";

export const addUniqueIdsToFolioTiptapNodes = (
  node: import("@tiptap/react").JSONContent,
) => {
  // Copy the node to avoid mutating the original
  const newNode = { ...node };

  // If it's a folioTiptapNode, add the uniqueId attr
  if (newNode.type === "folioTiptapNode") {
    newNode.attrs = {
      ...newNode.attrs,
      uniqueId: makeUniqueId(),
    };
  }

  // If the node has children (content), recursively process them
  if (newNode.content && Array.isArray(newNode.content)) {
    newNode.content = newNode.content.map((child) =>
      addUniqueIdsToFolioTiptapNodes(child),
    );
  }

  return newNode;
};

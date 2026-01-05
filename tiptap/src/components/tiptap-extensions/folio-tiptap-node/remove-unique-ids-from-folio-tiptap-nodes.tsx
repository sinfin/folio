export const removeUniqueIdsFromFolioTiptapNodes = (
  node: import("@tiptap/react").JSONContent,
) => {
  // Copy the node to avoid mutating the original
  const newNode = { ...node };

  // If it's a folioTiptapNode, remove the uniqueId attr
  if (newNode.type === "folioTiptapNode") {
    newNode.attrs = { ...newNode.attrs };
    delete newNode.attrs.uniqueId;
  }

  // If the node has children (content), recursively process them
  if (newNode.content && Array.isArray(newNode.content)) {
    newNode.content = newNode.content.map((child) =>
      removeUniqueIdsFromFolioTiptapNodes(child),
    );
  }

  return newNode;
};

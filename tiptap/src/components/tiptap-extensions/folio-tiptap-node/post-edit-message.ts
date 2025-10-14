export const postEditMessage = (
  attrs: Record<string, unknown>,
  uniqueId: string,
) => {
  window.parent!.postMessage(
    {
      type: "f-tiptap-node:click",
      attrs,
      uniqueId,
    },
    "*",
  );
};

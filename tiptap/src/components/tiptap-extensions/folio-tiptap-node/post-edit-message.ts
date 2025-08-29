export const postEditMessage = (attrs: any, uniqueId: string) => {
  window.parent!.postMessage(
    {
      type: "f-tiptap-node:click",
      attrs,
      uniqueId,
    },
    "*",
  );
};

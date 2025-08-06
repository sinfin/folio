export const postEditMessage = (attrs: any, uniqueId: string) => {
  window.top!.postMessage(
    {
      type: "f-tiptap-node:click",
      attrs,
      uniqueId,
    },
    "*",
  );
};

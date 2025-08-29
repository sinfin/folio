let folioTiptapNodeCounter = 1;

export const makeUniqueId = (): string => {
  return `folioTiptapNode-${folioTiptapNodeCounter++}`;
};

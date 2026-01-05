import "@tiptap/core";

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    /**
     * Inserts a FolioTiptapFloat node.
     */
    insertFolioTiptapFloat: (attrs?: Record<string, unknown>) => ReturnType;

    /**
     * Sets attributes for the FolioTiptapFloat node.
     */
    setFolioTiptapFloatAttributes: (
      attrs: Record<string, unknown>,
    ) => ReturnType;
  }
}

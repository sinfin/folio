import '@tiptap/core';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    /**
     * Inserts a FolioTiptapFloat node.
     */
    insertFolioTiptapFloat: (attrs?: Record<string, any>) => ReturnType;

    /**
     * Sets attributes for the FolioTiptapFloat node.
     */
    setFloatLayoutAttributes: (attrs: Record<string, any>) => ReturnType;
  }
}

import '@tiptap/core';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    /**
     * Inserts a FolioTiptapFloatLayout node.
     */
    insertFolioTiptapFloatLayout: (attrs?: Record<string, any>) => ReturnType;

    /**
     * Sets attributes for the FolioTiptapFloatLayout node.
     */
    setFloatLayoutAttributes: (attrs: Record<string, any>) => ReturnType;
  }
}

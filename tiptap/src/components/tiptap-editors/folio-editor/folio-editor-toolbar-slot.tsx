import { type Editor } from "@tiptap/react";

import { FolioEditorToolbarSlotButton } from "./folio-editor-toolbar-slot-button";

export interface FolioEditorToolbarSlotProps {
  editor: Editor | null;
  nodes: FolioTiptapNodeFromInput[];
}

export function FolioEditorToolbarSlot ({ editor, nodes }: FolioEditorToolbarSlotProps) {
  return (
    <>
      {nodes.map((node) => (
        <FolioEditorToolbarSlotButton editor={editor} node={node} />
      ))}
    </>
  );
}

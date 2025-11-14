import { type Editor } from "@tiptap/react";

import { FolioEditorToolbarSlotButton } from "./folio-editor-toolbar-slot-button";

import { ToolbarGroup } from "@/components/tiptap-ui-primitive/toolbar";

export interface FolioEditorToolbarSlotProps {
  editor: Editor | null;
  nodes: FolioTiptapNodeFromInput[];
}

export function FolioEditorToolbarSlot ({ editor, nodes }: FolioEditorToolbarSlotProps) {
  return (
    <>
      {nodes.map((node) => (
        <ToolbarGroup>
          <FolioEditorToolbarSlotButton editor={editor} node={node} />
        </ToolbarGroup>
      ))}
    </>
  );
}

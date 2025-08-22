import React, { useState, createElement } from "react";
import DragHandle from "@tiptap/extension-drag-handle-react";
import { type Editor } from "@tiptap/react";

import { SmartDragHandleContent } from "./smart-drag-handle-content";

export function SmartDragHandle({ editor }: { editor: Editor }) {
  const [selectedNodeData, setSelectedNodeData] = React.useState<{
    type: string;
    x: number;
    y: number;
  } | null>(null);

  const [copiedToClipboardAt, setCopiedToClipboardAt] = React.useState<number | null>(null);

  return (
    <DragHandle
      editor={editor}
      onNodeChange={({ node }) => {
        if (node) {
          const handle = document.querySelector(".drag-handle");

          if (handle) {
            const rect = handle.getBoundingClientRect();
            const newData = {
              type: node.type.name,
              x: rect.x,
              y: rect.y,
            }

            if (selectedNodeData &&
                selectedNodeData.type === newData.type &&
                selectedNodeData.x === newData.x &&
                selectedNodeData.y === newData.y) {
              return;
            }

            setSelectedNodeData(newData);

            return;
          }
        }

        setSelectedNodeData(null);
      }}
    >
      <SmartDragHandleContent
        editor={editor}
        selectedNodeData={selectedNodeData}
        copiedToClipboardAt={copiedToClipboardAt}
        setCopiedToClipboardAt={setCopiedToClipboardAt}
      />
    </DragHandle>
  )
}

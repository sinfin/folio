import React from "react";
import DragHandle from "@tiptap/extension-drag-handle-react";
import { type Editor } from "@tiptap/react";
import { NodeSelection } from "@tiptap/pm/state";

import { SmartDragHandleContent } from "./smart-drag-handle-content";

interface ClipboardData {
  at: number | null;
  html: string | null;
}

export function SmartDragHandle({ editor }: { editor: Editor }) {
  const [selectedNodeData, setSelectedNodeData] = React.useState<{
    type: string;
    x: number;
    y: number;
  } | null>(null);

  // Track the current node position from DragHandle's onNodeChange
  const currentNodePosRef = React.useRef<number>(-1);

  const [clipboardData, setClipboardData] = React.useState<ClipboardData>({
    at: null,
    html: null,
  });

  return (
    <DragHandle
      editor={editor}
      onElementDragStart={(e) => {
        // Workaround for @tiptap/extension-drag-handle bug:
        // When content visually extends past editor bounds (e.g. NodeViews with
        // negative margins), the extension's coordinate-based node detection fails.
        // If view.dragging is null, use the tracked node position from onNodeChange.
        const nodePos = currentNodePosRef.current;

        if (!editor.view.dragging && nodePos >= 0) {
          // Get the node at the tracked position
          const node = editor.state.doc.nodeAt(nodePos);
          if (!node) return;

          // Create a NodeSelection for this node and get its content
          const selection = NodeSelection.create(editor.state.doc, nodePos);
          const slice = selection.content();
          editor.view.dragging = { slice, move: true };

          // Also update the actual selection so drop knows what to delete
          const tr = editor.state.tr.setSelection(selection);
          editor.view.dispatch(tr);

          // Set up dataTransfer with the slice content
          if (e.dataTransfer) {
            e.dataTransfer.effectAllowed = "move";
            // Create a drag image from the selected node
            const nodeDOM = editor.view.nodeDOM(nodePos);
            if (nodeDOM instanceof HTMLElement) {
              const wrapper = document.createElement("div");
              wrapper.appendChild(nodeDOM.cloneNode(true));
              wrapper.style.position = "absolute";
              wrapper.style.top = "-10000px";
              document.body.appendChild(wrapper);
              e.dataTransfer.setDragImage(wrapper, 0, 0);
              document.addEventListener("drop", () => wrapper.remove(), {
                once: true,
              });
            }
          }
        }
      }}
      onNodeChange={({ node, pos }) => {
        // Store the current node position for use in onElementDragStart
        currentNodePosRef.current = pos;
        if (node) {
          const handle = document.querySelector(".drag-handle");

          if (handle) {
            const rect = handle.getBoundingClientRect();
            const newData = {
              type: node.type.name,
              x: rect.x,
              y: rect.y,
            };

            if (
              selectedNodeData &&
              selectedNodeData.type === newData.type &&
              selectedNodeData.x === newData.x &&
              selectedNodeData.y === newData.y
            ) {
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
        clipboardData={clipboardData}
        setClipboardData={setClipboardData}
      />
    </DragHandle>
  );
}

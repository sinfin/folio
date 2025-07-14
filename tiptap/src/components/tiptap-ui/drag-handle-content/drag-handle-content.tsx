import * as React from "react";
import {
  GripVertical,
  Plus,
  MoveUp,
  MoveDown,
  ArrowUpToLine,
  ArrowDownToLine,
  X,
} from "lucide-react";
import type { Editor } from "@tiptap/react";
import type { Node } from "@tiptap/pm/model";
import { TextSelection } from "@tiptap/pm/state";

import { Button } from "@/components/tiptap-ui-primitive/button";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuGroup,
} from "@/components/tiptap-ui-primitive/dropdown-menu";

import translate from "@/lib/i18n";

import "./drag-handle-content.scss";

const handlePlusClick = () => {
  console.log("Plus button clicked");
};

const handleDragClick = () => {
  console.log("Drag button clicked");
};

type MoveDirection = "up" | "down" | "top" | "bottom";

const moveNode = (
  editor: Editor,
  direction: MoveDirection,
  selectedNodeId: string | null,
): boolean => {
  try {
    const { state } = editor;

    if (!selectedNodeId) {
      console.warn("No node selected for movement");
      return false;
    }

    // Find the node and its parent info
    let foundNode: Node | null = null;
    let foundNodePos = -1;
    let parentNode: Node | null = null;
    let nodeIndex = -1;
    let nodeDepth = 0;

    state.doc.descendants((currentNode, currentPos, parent, index) => {
      if (currentNode.attrs?.uid === selectedNodeId) {
        foundNode = currentNode;
        foundNodePos = currentPos;
        parentNode = parent;
        nodeIndex = index;
        nodeDepth = state.doc.resolve(currentPos).depth;
        return false; // Stop searching
      }
      return true;
    });

    if (!foundNode || foundNodePos === -1) {
      console.warn("Cannot move: node not found");
      return false;
    }

    // Handle document-level nodes (depth 0)
    if (nodeDepth === 0) {
      parentNode = state.doc;
      // Find the correct index for document-level nodes
      for (let i = 0; i < state.doc.childCount; i++) {
        if (state.doc.child(i) === foundNode) {
          nodeIndex = i;
          break;
        }
      }
    }

    if (!parentNode) {
      console.warn("Cannot move: no valid parent found");
      return false;
    }

    const parentChildCount = parentNode.childCount;

    if (parentChildCount <= 1) {
      console.warn("Cannot move: parent has only one child");
      return false;
    }

    // Calculate target index
    let targetIndex: number;

    switch (direction) {
      case "up":
        if (nodeIndex === 0) return false;
        targetIndex = nodeIndex - 1;
        break;
      case "down":
        if (nodeIndex >= parentChildCount - 1) return false;
        targetIndex = nodeIndex + 1;
        break;
      case "top":
        if (nodeIndex === 0) return false;
        targetIndex = 0;
        break;
      case "bottom":
        if (nodeIndex >= parentChildCount - 1) return false;
        targetIndex = parentChildCount - 1;
        break;
      default:
        return false;
    }

    console.log("Moving node:", {
      direction,
      nodeIndex,
      targetIndex,
      parentChildCount,
      nodeDepth,
    });

    // Execute the move
    const success = editor
      .chain()
      .focus()
      .command(({ tr }) => {
        try {
          // Get the current node position in the transaction
          const currentPos = foundNodePos;
          if (!foundNode) {
            return false;
          }
          const nodeSize = foundNode.nodeSize;
          const nodeContent = tr.doc.slice(currentPos, currentPos + nodeSize);

          // Remove the node from current position
          tr.delete(currentPos, currentPos + nodeSize);

          // Calculate new target position
          let targetPos: number;

          if (nodeDepth === 0) {
            // Document-level node
            targetPos = 0;
            const docAfterDelete = tr.doc;

            // Calculate position by summing node sizes up to target index
            for (
              let i = 0;
              i < targetIndex && i < docAfterDelete.childCount;
              i++
            ) {
              targetPos += docAfterDelete.child(i).nodeSize;
            }
          } else {
            // Nested node
            const $parentPos = tr.doc.resolve(
              state.doc.resolve(foundNodePos).start(nodeDepth - 1),
            );
            targetPos =
              $parentPos.pos +
              $parentPos.posAtIndex(targetIndex, nodeDepth - 1);
          }

          // Insert the node at the target position
          tr.insert(targetPos, nodeContent.content);

          // Set selection to the moved node
          const newNodeStart = targetPos + 1;
          if (newNodeStart < tr.doc.content.size) {
            tr.setSelection(TextSelection.create(tr.doc, newNodeStart));
          }

          return true;
        } catch (error) {
          console.error("Error in move transaction:", error);
          return false;
        }
      })
      .run();

    // Fallback focus mechanism
    if (success) {
      setTimeout(() => {
        try {
          // Find the moved node again and focus it
          let movedNodePos = -1;
          editor.state.doc.descendants((currentNode, currentPos) => {
            if (currentNode.attrs?.uid === selectedNodeId) {
              movedNodePos = currentPos;
              return false;
            }
            return true;
          });

          if (movedNodePos !== -1) {
            const startPos = movedNodePos + 1;
            if (startPos < editor.state.doc.content.size) {
              editor.chain().focus().setTextSelection(startPos).run();
            }
          }
        } catch (error) {
          console.warn("Fallback focus failed:", error);
        }
      }, 0);
    }

    return success;
  } catch (error) {
    console.error(`Error moving node ${direction}:`, error);
    return false;
  }
};

const moveNodeUp = (editor: Editor, selectedNodeId: string | null): boolean =>
  moveNode(editor, "up", selectedNodeId);
const moveNodeDown = (editor: Editor, selectedNodeId: string | null): boolean =>
  moveNode(editor, "down", selectedNodeId);
const moveNodeToTop = (
  editor: Editor,
  selectedNodeId: string | null,
): boolean => moveNode(editor, "top", selectedNodeId);
const moveNodeToBottom = (
  editor: Editor,
  selectedNodeId: string | null,
): boolean => moveNode(editor, "bottom", selectedNodeId);

const removeNode = (editor: Editor, selectedNodeId: string | null): boolean => {
  const { state } = editor;

  if (!selectedNodeId) {
    console.warn("No node selected for movement");
    return false;
  }

  // Find the node and its parent info
  let foundNode: Node | null = null;
  let foundNodePos = -1;
  let parentNode: Node | null = null;
  let nodeIndex = -1;
  let nodeDepth = 0;

  state.doc.descendants((currentNode, currentPos, parent, index) => {
    if (currentNode.attrs?.uid === selectedNodeId) {
      foundNode = currentNode;
      foundNodePos = currentPos;
      parentNode = parent;
      nodeIndex = index;
      nodeDepth = state.doc.resolve(currentPos).depth;
      return false; // Stop searching
    }
    return true;
  });

  if (!foundNode || foundNodePos === -1) {
    console.warn("Cannot move: node not found");
    return false;
  }

  // Remove the node from the document
  const tr = state.tr;
  tr.delete(foundNodePos, foundNodePos + foundNode.nodeSize);
  editor.view.dispatch(tr);

  return true;
};

const TRANSLATIONS = {
  cs: {
    moveUp: "Přesunout nahoru",
    moveDown: "Přesunout dolů",
    moveToTop: "Nahoru",
    moveToBottom: "Dolu",
    removeNode: "Odstranit",
  },
  en: {
    moveUp: "Move up",
    moveDown: "Move down",
    moveToTop: "Move to top",
    moveToBottom: "Move to bottom",
    removeNode: "Remove",
  },
};

const DRAG_HANDLE_DROPDOWN_OPTIONS = [
  {
    type: "moveUp",
    icon: MoveUp,
    command: moveNodeUp,
  },
  {
    type: "moveDown",
    icon: MoveDown,
    command: moveNodeDown,
  },
  {
    type: "moveToTop",
    icon: ArrowUpToLine,
    command: moveNodeToTop,
  },
  {
    type: "moveToBottom",
    icon: ArrowDownToLine,
    command: moveNodeToBottom,
  },
  {
    type: "removeNode",
    icon: X,
    command: removeNode,
  },
];

export interface DragHandleContentProps {
  /**
   * The TipTap editor instance.
   */
  editor: Editor | null;
  /**
   * The currently selected node ID from the drag handle extension.
   */
  selectedNodeId?: string | null;
}

export function DragHandleContent({
  editor,
  selectedNodeId,
}: DragHandleContentProps) {
  const [openedDropdown, setOpenedDropdown] = React.useState<string | null>(
    null,
  );
  const [persistedNodeId, setPersistedNodeId] = React.useState<string | null>(
    null,
  );

  // Clear persisted node when dropdown closes
  React.useEffect(() => {
    if (openedDropdown === null) {
      setPersistedNodeId(null);
    }
  }, [openedDropdown]);

  if (!editor) {
    return null;
  }

  return (
    <div className="f-tiptap__drag-handle-content">
      <Button
        type="button"
        data-style="ghost"
        role="button"
        tabIndex={-1}
        aria-label="Plus"
        onClick={handlePlusClick}
      >
        <Plus className="tiptap-button-icon" />
      </Button>

      <DropdownMenu
        open={openedDropdown === "drag"}
        onOpenChange={(open: boolean) => {
          if (open && selectedNodeId) {
            // Persist the current node when opening dropdown
            setPersistedNodeId(selectedNodeId);
          }
          setOpenedDropdown(open ? "drag" : null);
        }}
      >
        <DropdownMenuTrigger asChild>
          <Button
            type="button"
            data-style="ghost"
            role="button"
            tabIndex={-1}
            aria-label="Drag"
            onClick={handleDragClick}
          >
            <GripVertical className="tiptap-button-icon" />
          </Button>
        </DropdownMenuTrigger>

        <DropdownMenuContent>
          <DropdownMenuGroup>
            {DRAG_HANDLE_DROPDOWN_OPTIONS.map((option) => (
              <DropdownMenuItem key={option.type} asChild>
                <Button
                  type="button"
                  data-style="ghost"
                  role="button"
                  tabIndex={-1}
                  aria-label={translate(TRANSLATIONS, option.type)}
                  onClick={() => {
                    // Use persisted node ID if available, fallback to current selectedNodeId
                    const nodeIdToUse = persistedNodeId || selectedNodeId;
                    if (nodeIdToUse) {
                      const success = option.command(editor, nodeIdToUse);
                      if (success) {
                        setOpenedDropdown(null);
                      }
                    }
                  }}
                >
                  {React.createElement(option.icon, {
                    className: "tiptap-button-icon",
                  })}
                  {translate(TRANSLATIONS, option.type)}
                </Button>
              </DropdownMenuItem>
            ))}
          </DropdownMenuGroup>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );
}

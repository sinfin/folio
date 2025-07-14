import React, { useState, createElement } from "react";
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

type TargetNodeInfo = {
  resultElement: Element | null;
  resultNode: Node;
  pos: number;
};

const moveNode = (
  editor: Editor,
  direction: MoveDirection,
  targetNode: TargetNodeInfo,
): boolean => {
  try {
    const { state } = editor;

    if (!targetNode.resultNode || targetNode.pos === null) {
      console.error("Invalid target node");
      return false;
    }

    // Find the node's position in the document
    const resolvedPos = state.doc.resolve(targetNode.pos);

    // Work only with root nodes directly under the doc node
    const depth = 1; // Root nodes are at depth 1
    const parentDepth = 0; // Document is at depth 0
    const nodeIndex = resolvedPos.index(parentDepth);
    const parent = resolvedPos.node(parentDepth); // The document node

    // Calculate target index
    let targetIndex: number;
    switch (direction) {
      case "up":
        if (nodeIndex === 0) return false;
        targetIndex = nodeIndex - 1;
        break;
      case "down":
        if (nodeIndex >= parent.childCount - 1) return false;
        targetIndex = nodeIndex + 1;
        break;
      case "top":
        if (nodeIndex === 0) return false;
        targetIndex = 0;
        break;
      case "bottom":
        if (nodeIndex >= parent.childCount - 1) return false;
        targetIndex = parent.childCount - 1;
        break;
      default:
        return false;
    }

    // Execute the move using a simpler approach
    const success = editor
      .chain()
      .focus()
      .command(({ tr }) => {
        try {
          // Use the node we already found from findElementNextToCoords
          const currentNode = targetNode.resultNode;
          const currentNodePos = targetNode.pos;

          if (!currentNode) {
            console.error("No node found at position");
            return false;
          }

          // Calculate target position
          let targetPos: number;
          const parentStart = resolvedPos.start(0); // Start of document

          // Remove the node from its current position first
          tr.delete(currentNodePos, currentNodePos + currentNode.nodeSize);

          // Calculate target position in the updated document
          const updatedDoc = tr.doc;
          const updatedParent = updatedDoc.resolve(parentStart).node(0);

          if (targetIndex === 0) {
            targetPos = parentStart;
          } else {
            // After removal, use targetIndex directly for both up and down movements
            let effectiveTargetIndex = targetIndex;

            // Calculate position by summing node sizes up to target index
            targetPos = parentStart;
            for (
              let i = 0;
              i < effectiveTargetIndex && i < updatedParent.childCount;
              i++
            ) {
              targetPos += updatedParent.child(i).nodeSize;
            }
          }

          // Insert at target position
          tr.insert(targetPos, currentNode);

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

    return success;
  } catch (error) {
    console.error(`Error moving node ${direction}:`, error);
    return false;
  }
};

const moveNodeUp = (editor: Editor, targetNode: TargetNodeInfo): boolean =>
  moveNode(editor, "up", targetNode);
const moveNodeDown = (editor: Editor, targetNode: TargetNodeInfo): boolean =>
  moveNode(editor, "down", targetNode);
const moveNodeToTop = (editor: Editor, targetNode: TargetNodeInfo): boolean =>
  moveNode(editor, "top", targetNode);
const moveNodeToBottom = (
  editor: Editor,
  targetNode: TargetNodeInfo,
): boolean => moveNode(editor, "bottom", targetNode);

const removeNode = (editor: Editor, targetNode: TargetNodeInfo): boolean => {
  try {
    const { state } = editor;

    const tr = state.tr;
    tr.delete(targetNode.pos, targetNode.pos + targetNode.resultNode.nodeSize);
    editor.view.dispatch(tr);

    return true;
  } catch (error) {
    console.error("Error removing node:", error);
    return false;
  }
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

export type FindElementNextToCoords = {
  x: number;
  y: number;
  direction?: "left" | "right";
  editor: Editor;
};

export function findElementNextToCoords(options: FindElementNextToCoords) {
  const { x, y, direction, editor } = options;
  let targetElement: Element | null = null;
  let targetNode: Node | null = null;
  let documentPosition: number | null = null;
  let currentX = x;

  while (targetNode === null && currentX < window.innerWidth && currentX > 0) {
    const elementsAtPoint = document.elementsFromPoint(currentX, y);
    const proseMirrorIndex = elementsAtPoint.findIndex((el) =>
      el.classList.contains("ProseMirror"),
    );
    const relevantElements = elementsAtPoint.slice(0, proseMirrorIndex);

    // console.log({ currentX, y, direction, elementsAtPoint });

    if (relevantElements.length > 0) {
      const currentElement = relevantElements[0];
      targetElement = currentElement;

      // Find the root node at depth 1 (directly under doc)
      let blockElement = currentElement;
      while (blockElement && blockElement.parentElement) {
        const pos = editor.view.posAtDOM(blockElement, 0);
        if (pos >= 0) {
          const resolvedPos = editor.state.doc.resolve(pos);
          // Only look for root nodes at depth 1
          if (resolvedPos.depth >= 1) {
            const rootNode = resolvedPos.node(1);
            if (rootNode.isBlock && rootNode.type.name !== "doc") {
              const nodePos = resolvedPos.before(1);
              documentPosition = nodePos;
              targetNode = rootNode;

              break;
            }
          }
        }
        if (targetNode) break;
        blockElement = blockElement.parentElement;
      }

      // Fallback to original logic if no block node found
      if (!targetNode && documentPosition === null) {
        documentPosition = editor.view.posAtDOM(currentElement, 0);
        if (documentPosition >= 0) {
          targetNode = editor.state.doc.nodeAt(documentPosition);
        }
      }

      if (targetNode) break;
    }

    if (direction === "left") {
      currentX -= 1;
    } else {
      currentX += 1;
    }
  }

  console.log(
    `findElementNextToCoords: Found element at (${currentX}, ${y})`,
    targetElement,
    targetNode,
    documentPosition,
  );

  return {
    resultElement: targetElement,
    resultNode: targetNode,
    pos: documentPosition !== null ? documentPosition : null,
  };
}

export interface DragHandleContentProps {
  /**
   * The TipTap editor instance.
   */
  editor: Editor | null;
}

export function DragHandleContent({ editor }: DragHandleContentProps) {
  const [openedDropdown, setOpenedDropdown] = useState<string | null>(null);

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
        className="f-tiptap__drag-handle-button"
      >
        <Plus className="tiptap-button-icon" />
      </Button>

      <DropdownMenu
        open={openedDropdown === "drag"}
        onOpenChange={(open: boolean) => {
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
            className="f-tiptap__drag-handle-button"
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
                  className="f-tiptap__drag-handle-dropdown-button"
                  onClick={(e) => {
                    const rect = (e.target as HTMLElement)
                      .closest(".tiptap-dropdown-menu")!
                      .getBoundingClientRect();

                    const nodeToUse = findElementNextToCoords({
                      x: rect.left,
                      y: rect.top,
                      direction: "right",
                      editor,
                    });

                    if (
                      nodeToUse &&
                      nodeToUse.resultNode &&
                      nodeToUse.pos !== null
                    ) {
                      const success = option.command(
                        editor,
                        nodeToUse as TargetNodeInfo,
                      );

                      if (success) {
                        setOpenedDropdown(null);
                      }
                    } else {
                      setOpenedDropdown(null);
                    }
                  }}
                >
                  {createElement(option.icon, {
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

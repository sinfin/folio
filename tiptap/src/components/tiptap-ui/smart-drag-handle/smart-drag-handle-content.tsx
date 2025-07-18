import React, { useState, createElement } from "react";
import {
  GripVertical,
  Plus,
  MoveUp,
  MoveDown,
  ArrowUpToLine,
  ArrowDownToLine,
  X,
  SquarePen,
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

import "./smart-drag-handle-content.scss";

const handlePlusClick = ({
  event,
  editor,
}: {
  event: React.MouseEvent;
  editor: Editor;
}) => {
  const rect = (event.target as HTMLElement).getBoundingClientRect();

  const nodeToUse = findElementNextToCoords({
    x: rect.left,
    y: rect.top,
    direction: "right",
    editor,
  });

  if (!nodeToUse || !nodeToUse.resultNode || nodeToUse.pos === null) {
    console.error("No node found at the clicked position");
    return;
  }

  const targetPos = nodeToUse.pos + nodeToUse.resultNode.nodeSize;

  editor
    .chain()
    .focus()
    .insertContentAt(targetPos - 1, {
      type: "paragraph",
      content: [{ type: "text", text: "/" }],
    })
    .run();
};

const handleDragClick = () => {};

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

const editFolioTiptapNode = (
  editor: Editor,
  targetNode: TargetNodeInfo,
): boolean => {
  if (targetNode.resultElement) {
    const event = new CustomEvent("f-tiptap-node:edit")
    targetNode.resultElement.dispatchEvent(event);
    return true
  }

  return false;
};

const TRANSLATIONS = {
  cs: {
    moveUp: "Přesunout",
    moveDown: "Přesunout",
    moveToTop: "Nahoru",
    moveToBottom: "Dolu",
    removeNode: "Odstranit",
    editFolioTiptapNode: "Upravit",
  },
  en: {
    moveUp: "Move",
    moveDown: "Move",
    moveToTop: "Move to top",
    moveToBottom: "Move to bottom",
    removeNode: "Remove",
    editFolioTiptapNode: "Edit",
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

const DRAG_HANDLE_FOLIO_TIPTAP_NODE_OPTION = {
  type: "editFolioTiptapNode",
  icon: SquarePen,
  command: editFolioTiptapNode,
};

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

    if (relevantElements.length > 0) {
      const currentElement = relevantElements[0];
      targetElement = currentElement;
      documentPosition = editor.view.posAtDOM(currentElement, 0);

      if (documentPosition >= 0) {
        targetNode = editor.state.doc.nodeAt(Math.max(documentPosition - 1, 0));
        if (targetNode === null || targetNode.isText) {
          targetNode = editor.state.doc.nodeAt(
            Math.max(documentPosition - 1, 0),
          );
        }
        if (!targetNode) {
          targetNode = editor.state.doc.nodeAt(Math.max(documentPosition, 0));
        }
        break;
      }
    }

    if (direction === "left") {
      currentX -= 1;
    } else {
      currentX += 1;
    }
  }

  return {
    resultElement: targetElement,
    resultNode: targetNode,
    pos: documentPosition !== null ? documentPosition : null,
  };
}

const makeButtonOnClick =
  (
    editor: Editor,
    option: { command: (editor: Editor, nodeInfo: TargetNodeInfo) => boolean },
    setOpenedDropdown: (value: string | null) => void,
  ) =>
  (e: React.MouseEvent) => {
    const rect = (e.target as HTMLElement)
      .closest(".tiptap-dropdown-menu")!
      .getBoundingClientRect();

    const nodeToUse = findElementNextToCoords({
      x: rect.left,
      y: rect.top,
      direction: "right",
      editor,
    });

    if (nodeToUse && nodeToUse.resultNode && nodeToUse.pos !== null) {
      const success = option.command(editor, nodeToUse as TargetNodeInfo);

      if (success) {
        setOpenedDropdown(null);
      }
    } else {
      setOpenedDropdown(null);
    }
  };

export interface SmartDragHandleContentProps {
  /**
   * The TipTap editor instance.
   */
  editor: Editor | null;
  selectedNodeData: {
    type: string;
    x: number;
    y: number;
  } | null;
}

export function SmartDragHandleContent({
  editor,
  selectedNodeData,
}: SmartDragHandleContentProps) {
  const [openedDropdown, setOpenedDropdown] = useState<string | null>(null);

  if (!editor) {
    return null;
  }

  const wrapRef = React.useRef<HTMLDivElement>(null);
  const [nodeHeightPx, setNodeHeightPx] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!wrapRef || !wrapRef.current || !editor) return;
    if (!selectedNodeData || !selectedNodeData.y) return;

    // y changed -> other node -> close
    if (openedDropdown) {
      setOpenedDropdown(null);
    }

    const nodeToUse = findElementNextToCoords({
      x: selectedNodeData.x,
      y: selectedNodeData.y,
      direction: "right",
      editor,
    });

    if (nodeToUse && nodeToUse.resultElement) {
      const nodeHeight = nodeToUse.resultElement.getBoundingClientRect().height;
      return setNodeHeightPx(`${nodeHeight}px`);
    }

    return setNodeHeightPx(null);
  }, [
    selectedNodeData && selectedNodeData.y,
    setNodeHeightPx,
    editor,
    wrapRef && wrapRef.current,
  ]);

  const dragHandleButtonOptions = [
    ...(selectedNodeData && selectedNodeData.type === "folioTiptapNode"
      ? [
          ...DRAG_HANDLE_DROPDOWN_OPTIONS.slice(
            0,
            DRAG_HANDLE_DROPDOWN_OPTIONS.length - 1,
          ),
          DRAG_HANDLE_FOLIO_TIPTAP_NODE_OPTION,
          DRAG_HANDLE_DROPDOWN_OPTIONS[DRAG_HANDLE_DROPDOWN_OPTIONS.length - 1],
        ]
      : DRAG_HANDLE_DROPDOWN_OPTIONS),
  ];

  return (
    <div
      className="f-tiptap-smart-drag-handle-content"
      style={{ minHeight: nodeHeightPx || undefined }}
      ref={wrapRef}
    >
      <Button
        type="button"
        data-style="ghost"
        role="button"
        tabIndex={-1}
        aria-label="Plus"
        onClick={(event) => {
          handlePlusClick({ event, editor });
        }}
        className="f-tiptap-smart-drag-handle__button"
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
            className="f-tiptap-smart-drag-handle__button"
          >
            <GripVertical className="tiptap-button-icon" />
          </Button>
        </DropdownMenuTrigger>

        <DropdownMenuContent>
          <DropdownMenuGroup>
            {dragHandleButtonOptions.map((option) => (
              <DropdownMenuItem key={option.type} asChild>
                <Button
                  type="button"
                  data-style="ghost"
                  role="button"
                  tabIndex={-1}
                  aria-label={translate(TRANSLATIONS, option.type)}
                  className="f-tiptap-smart-drag-handle__dropdown-button"
                  onClick={makeButtonOnClick(editor, option, setOpenedDropdown)}
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

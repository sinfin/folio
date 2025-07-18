import type { Editor } from "@tiptap/react";
import type { Node } from "@tiptap/pm/model";

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
        // Find the top-level node (direct child of doc)
        const resolvedPos = editor.state.doc.resolve(documentPosition);

        // Get the node at depth 1 (direct child of doc)
        if (resolvedPos.depth >= 1) {
          targetNode = resolvedPos.node(1);
        }

        // If we couldn't find a node at depth 1, fall back to the original logic
        if (!targetNode) {
          targetNode = editor.state.doc.nodeAt(
            Math.max(documentPosition - 1, 0),
          );
          if (targetNode === null || targetNode.isText) {
            targetNode = editor.state.doc.nodeAt(
              Math.max(documentPosition - 1, 0),
            );
          }
          if (!targetNode) {
            targetNode = editor.state.doc.nodeAt(Math.max(documentPosition, 0));
          }
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

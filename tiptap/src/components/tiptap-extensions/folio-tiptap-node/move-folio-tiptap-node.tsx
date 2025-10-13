import { type EditorState, TextSelection, type Transaction } from "@tiptap/pm/state";

interface MoveFolioTiptapNodeProps {
  direction: "up" | "down";
  state: EditorState;
  dispatch: (tr: Transaction) => void;
}

export const moveFolioTiptapNode = ({ direction, state, dispatch }: MoveFolioTiptapNodeProps): boolean => {
  if (state.selection.from !== state.selection.to - 1) {
    // If the selection is not a single node, we cannot move it
    return false;
  }

  // @ts-expect-error - node does exist on selection!
  const node = state.selection.node

  if (!node || node.type.name !== "folioTiptapNode") {
    // If the selection is not a folioTiptapNode, we cannot move it
    return false;
  }

  let targetPos

  if (direction === 'up') {
    const targetNodeAtSameDepth = state.doc.resolve(state.selection.from).nodeBefore;
    if (!targetNodeAtSameDepth) return false
    targetPos = state.selection.from - targetNodeAtSameDepth.nodeSize;
  } else {
    const targetNodeAtSameDepth = state.doc.resolve(state.selection.to).nodeAfter;
    if (!targetNodeAtSameDepth) return false
    const deletedNodeShift = 1
    targetPos = state.selection.to + targetNodeAtSameDepth.nodeSize - deletedNodeShift;
  }

  const tr = state.tr

  tr.deleteRange(state.selection.from, state.selection.to)
  tr.insert(targetPos, node)
  tr.setSelection(TextSelection.near(tr.doc.resolve(targetPos)))

  dispatch(tr);

  return true
};

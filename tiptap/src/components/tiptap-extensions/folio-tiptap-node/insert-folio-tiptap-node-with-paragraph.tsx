import type { Transaction } from "@tiptap/pm/state";
import type { Node as ProseMirrorNode, Schema } from "@tiptap/pm/model";
import { Fragment } from "@tiptap/pm/model";
import { TextSelection } from "@tiptap/pm/state";

interface InsertFolioTiptapNodeWithParagraphProps {
  node: ProseMirrorNode;
  pos: number;
  tr: Transaction;
  schema: Schema;
}

/**
 * Sets the cursor at the given position with a fallback to TextSelection.near() if invalid.
 */
function setCursorAtPosition(tr: Transaction, cursorPos: number): void {
  try {
    tr.setSelection(TextSelection.create(tr.doc, cursorPos));
  } catch {
    // Fallback: use TextSelection.near if position is invalid (shouldn't happen)
    tr.setSelection(TextSelection.near(tr.doc.resolve(cursorPos)));
  }
}

/**
 * Inserts a paragraph after the given position and sets the cursor at its start.
 */
function insertParagraphAndSetCursor(
  tr: Transaction,
  schema: Schema,
  insertPos: number,
): void {
  const paragraphNode = schema.nodes.paragraph.create();
  tr.insert(insertPos, paragraphNode);
  setCursorAtPosition(tr, insertPos + 1);
}

/**
 * Inserts a folioTiptapNode at the given position, adding a paragraph after it
 * if we're at the end of a parent node (mimicking the behavior of insertFolioTiptapNode command).
 *
 * @param props - The insertion parameters
 * @param props.node - The folioTiptapNode to insert
 * @param props.pos - The position where to insert the node
 * @param props.tr - The transaction to modify
 * @param props.schema - The ProseMirror schema
 */
export const insertFolioTiptapNodeWithParagraph = ({
  node,
  pos,
  tr,
  schema,
}: InsertFolioTiptapNodeWithParagraphProps): void => {
  const $pos = tr.doc.resolve(pos);

  // Check if we're at a block-level position (paste placeholder) or text-level (command)
  const paragraphStart = $pos.start($pos.depth) - 1;
  const isBlockLevelPosition = paragraphStart < 0;

  if (isBlockLevelPosition) {
    // Block-level position (paste placeholder) - replace placeholder, then add paragraph after
    tr.replaceWith(pos, pos + 1, node);
    const afterNodePos = pos + node.nodeSize;
    insertParagraphAndSetCursor(tr, schema, afterNodePos);
  } else {
    // Text-level position (command) - get the paragraph boundaries
    const paragraphEnd = $pos.end($pos.depth) + 1;
    const paragraphNode = $pos.parent;

    // Check if paragraph is empty or contains only whitespace
    const isParagraphEmpty =
      paragraphNode.content.size === 0 ||
      paragraphNode.textContent.trim().length === 0;

    if (isParagraphEmpty) {
      // Empty or whitespace-only paragraph - replace it with node + paragraph
      const paragraphAfterNode = schema.nodes.paragraph.create();
      const fragment = Fragment.from([node, paragraphAfterNode]);
      tr.replaceWith(paragraphStart, paragraphEnd, fragment);
      // Set cursor at the start of the new paragraph (after the node)
      setCursorAtPosition(tr, paragraphStart + node.nodeSize + 1);
    } else {
      // Paragraph has content - insert node after it, then add paragraph
      tr.insert(paragraphEnd, node);
      const afterNodePos = paragraphEnd + node.nodeSize;
      insertParagraphAndSetCursor(tr, schema, afterNodePos);
    }
  }

  tr.scrollIntoView();
};

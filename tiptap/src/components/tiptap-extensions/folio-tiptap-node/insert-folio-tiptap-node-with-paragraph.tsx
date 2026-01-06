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

  // Check if we're at the end of a parent node (depth > 1 means we're inside something)
  // We use depth - 1 because the max-depth is the paragraph with slash
  const isAtEndOfParent =
    $pos.depth > 2 && $pos.pos + 1 === $pos.end($pos.depth - 1);

  if (isAtEndOfParent) {
    // Insert node + paragraph using fragment
    const paragraphNode = schema.nodes.paragraph.create();
    const fragment = Fragment.from([node, paragraphNode]);

    // Replace the whole paragraph - the -1 is the node opening
    const start = $pos.start($pos.depth) - 1;
    // The +1 is the node closing
    const end = $pos.end($pos.depth) + 1;
    tr.replaceWith(start, end, fragment);

    // Set selection to the beginning of the paragraph (after the node)
    // start + folioTipapNode (leaf -> 1)
    const paragraphPos = start + 1;
    tr.setSelection(TextSelection.near(tr.doc.resolve(paragraphPos + 1)));
  } else {
    // Just insert the node
    tr.replaceWith(pos, pos + 1, node);
    // Move after the inserted node
    const offset = tr.selection.anchor;
    tr.setSelection(TextSelection.near(tr.doc.resolve(offset)));
  }

  tr.scrollIntoView();
};

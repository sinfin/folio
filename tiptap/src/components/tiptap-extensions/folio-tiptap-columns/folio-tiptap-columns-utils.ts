import { findParentNode } from "@tiptap/core";
import { Node } from "@tiptap/pm/model";
import { type EditorState, TextSelection } from "@tiptap/pm/state";

import { FolioTiptapColumnNode, FolioTiptapColumnsNode } from "./index";

export function createColumn(colType: any, index: any, colContent = null) {
  if (colContent) {
    return colType.createChecked({}, colContent);
  }

  return colType.createAndFill({});
}

export function getColumnsNodeTypes(schema: any) {
  if (schema.cached.columnsNodeTypes) {
    return schema.cached.columnsNodeTypes;
  }

  const roles = {
    columns: schema.nodes.folioTiptapColumns,
    column: schema.nodes.folioTiptapColumn,
  };

  schema.cached.columnsNodeTypes = roles;

  return roles;
}

export function createColumns(schema: any, colsCount: any, colContent = null) {
  const types = getColumnsNodeTypes(schema);
  const cols = [];

  for (let index = 0; index < colsCount; index += 1) {
    const col = createColumn(types.column, colContent);

    if (col) {
      // @ts-ignore
      cols.push(col);
    }
  }

  return types.columns.createChecked({}, cols);
}

export function addOrDeleteColumn({
  state,
  dispatch,
  type,
}: {
  state: EditorState;
  dispatch: any;
  type: "addBefore" | "addAfter" | "delete";
}) {
  const maybeColumns = findParentNode(
    (node: Node) => node.type.name === FolioTiptapColumnsNode.name,
  )(state.selection);
  const maybeColumn = findParentNode(
    (node: Node) => node.type.name === FolioTiptapColumnNode.name,
  )(state.selection);

  if (dispatch && maybeColumns && maybeColumn) {
    const cols = maybeColumns.node;
    let colIndex = null

    cols.content.forEach((childNode, pos, index) => {
      if (colIndex !== null) return

      if (childNode === maybeColumn.node) {
        colIndex = index;
        return
      }
    })

    if (colIndex === null) {
      console.warn("Current page not found in cols node");
      return false;
    }

    const colsJSON = cols.toJSON();

    let nextIndex = colIndex;

    if (type === "delete") {
      // If we have 2 or fewer columns, replace the entire columns node with the combined contents
      if (colsJSON.content.length <= 2) {
        // Collect all content from all columns
        const allContent = [];
        colsJSON.content.forEach((column: { content: any[]; }) => {
          if (column.content && column.content.length > 0) {
            allContent.push(...column.content);
          }
        });

        // If no content, add an empty paragraph
        if (allContent.length === 0) {
          allContent.push({ type: "paragraph" });
        }

        const tr = state.tr;

        // Replace the entire columns node with the combined content
        tr.replaceWith(
          maybeColumns.pos,
          maybeColumns.pos + maybeColumns.node.nodeSize,
          allContent.map((content) => Node.fromJSON(state.schema, content)),
        );

        // Position cursor at the start of the replaced content
        tr.setSelection(
          TextSelection.near(tr.doc.resolve(maybeColumns.pos + 1)),
        );

        dispatch(tr);
        return true;
      }

      // For more than 2 columns, merge with adjacent column
      // Get the content of the column to be deleted
      const deletedColumn = colsJSON.content[colIndex];
      const deletedContent = deletedColumn.content || [];

      // Determine which column to merge with
      const targetIndex = colIndex > 0 ? colIndex - 1 : colIndex + 1;
      const targetColumn = colsJSON.content[targetIndex];

      // Merge the content into the target column
      if (deletedContent.length > 0) {
        if (!targetColumn.content) {
          targetColumn.content = [];
        }
        targetColumn.content.push(...deletedContent);
      }

      // Remove the deleted column
      colsJSON.content.splice(colIndex, 1);

      // Set next index for cursor positioning
      nextIndex = colIndex > 0 ? colIndex - 1 : 0;
    } else {
      nextIndex = type === "addBefore" ? colIndex : colIndex + 1;
      colsJSON.content.splice(nextIndex, 0, {
        type: FolioTiptapColumnNode.name,
        content: [
          {
            type: "paragraph",
          },
        ],
      });
    }

    const nextCols = Node.fromJSON(state.schema, colsJSON);

    let nextSelectPos = maybeColumns.pos;
    nextCols.content.forEach((col, pos, index) => {
      if (index < nextIndex) {
        nextSelectPos += col.nodeSize;
      }
    });

    const tr = state.tr;

    tr.replaceWith(
      maybeColumns.pos,
      maybeColumns.pos + maybeColumns.node.nodeSize,
      nextCols,
    ).setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));

    dispatch(tr);
  }

  return true;
}

export function goToColumn({
  state,
  dispatch,
  type,
}: {
  state: EditorState;
  dispatch: any;
  type: "before" | "after";
}) {
  const maybeColumns = findParentNode(
    (node: Node) => node.type.name === FolioTiptapColumnsNode.name,
  )(state.selection);
  const maybeColumn = findParentNode(
    (node: Node) => node.type.name === FolioTiptapColumnNode.name,
  )(state.selection);

  if (dispatch && maybeColumns && maybeColumn) {
    const cols = maybeColumns.node;
    const col = maybeColumn.node;
    let currentIndex = null;

    cols.content.forEach((childNode, pos, index) => {
      if (currentIndex !== null) return

      if (childNode === col) {
        currentIndex = index;
        return
      }
    })

    if (currentIndex === null) {
      console.warn("Current col not found in cols node");
      return false;
    }

    let nextIndex = 0;

    if (type === "before") {
      nextIndex = (currentIndex - 1 + cols.childCount) % cols.childCount;
    } else {
      nextIndex = (currentIndex + 1) % cols.childCount;
    }

    let nextSelectPos = maybeColumns.pos;
    cols.content.forEach((col, pos, index) => {
      if (index < nextIndex) {
        nextSelectPos += col.nodeSize;
      }
    });

    const tr = state.tr;

    tr.setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));
    dispatch(tr);
    return true;
  }

  return false;
}

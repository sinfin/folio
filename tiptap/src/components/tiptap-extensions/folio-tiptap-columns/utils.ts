import { findParentNode } from '@tiptap/core';
import { Node } from '@tiptap/pm/model';
import { type EditorState, TextSelection } from '@tiptap/pm/state';

import { FolioTiptapColumnNode, FolioTiptapColumnsNode } from './index';

export function createColumn(colType: any, index: any, colContent = null) {
  if (colContent) {
    return colType.createChecked({ index }, colContent);
  }

  return colType.createAndFill({ index });
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
    const col = createColumn(types.column, index, colContent);

    if (col) {
      // @ts-ignore
      cols.push(col);
    }
  }

  return types.columns.createChecked({ columnCount: colsCount }, cols);
}

export function addOrDeleteColumn({
  state,
  dispatch,
  type,
}: {
  state: EditorState
  dispatch: any
  type: 'addBefore' | 'addAfter' | 'delete'
}) {
  const maybeColumns = findParentNode((node: Node) => node.type.name === FolioTiptapColumnsNode.name)(state.selection);
  const maybeColumn = findParentNode((node: Node) => node.type.name === FolioTiptapColumnNode.name)(state.selection);

  if (dispatch && maybeColumns && maybeColumn) {
    const cols = maybeColumns.node;
    const colIndex = maybeColumn.node.attrs.index;
    const colsJSON = cols.toJSON();

    let nextIndex = colIndex;

    if (type === 'delete') {
      nextIndex = colIndex - 1;
      colsJSON.content.splice(colIndex, 1);
    } else {
      nextIndex = type === 'addBefore' ? colIndex : colIndex + 1;
      colsJSON.content.splice(nextIndex, 0, {
        type: FolioTiptapColumnNode.name,
        attrs: {
          index: colIndex,
        },
        content: [
          {
            type: 'paragraph',
          },
        ],
      });
    }

    colsJSON.attrs.cols = colsJSON.content.length;

    colsJSON.content.forEach((colJSON: any, index: any) => {
      colJSON.attrs.index = index;
    });

    const nextCols = Node.fromJSON(state.schema, colsJSON);

    let nextSelectPos = maybeColumns.pos;
    nextCols.content.forEach((col, pos, index) => {
      if (index < nextIndex) {
        nextSelectPos += col.nodeSize;
      }
    });

    const tr = state.tr.setTime(Date.now());

    tr.replaceWith(maybeColumns.pos, maybeColumns.pos + maybeColumns.node.nodeSize, nextCols).setSelection(
      TextSelection.near(tr.doc.resolve(nextSelectPos)),
    );

    dispatch(tr);
  }

  return true;
}

export function goToColumn({ state, dispatch, type }: { state: EditorState, dispatch: any, type: 'before' | 'after' }) {
  const maybeColumns = findParentNode((node: Node) => node.type.name === FolioTiptapColumnsNode.name)(state.selection);
  const maybeColumn = findParentNode((node: Node) => node.type.name === FolioTiptapColumnNode.name)(state.selection);

  if (dispatch && maybeColumns && maybeColumn) {
    const cols = maybeColumns.node;
    const colIndex = maybeColumn.node.attrs.index;

    let nextIndex = 0;

    if (type === 'before') {
      nextIndex = (colIndex - 1 + cols.attrs.count) % cols.attrs.count;
    } else {
      nextIndex = (colIndex + 1) % cols.attrs.count;
    }

    let nextSelectPos = maybeColumns.pos;
    cols.content.forEach((col, pos, index) => {
      if (index < nextIndex) {
        nextSelectPos += col.nodeSize;
      }
    });

    const tr = state.tr.setTime(Date.now());

    tr.setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));
    dispatch(tr);
    return true;
  }

  return false;
}

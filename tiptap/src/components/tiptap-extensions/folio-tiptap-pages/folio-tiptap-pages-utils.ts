import { findParentNode } from "@tiptap/core";
import { Node } from "@tiptap/pm/model";
import { type EditorState, TextSelection } from "@tiptap/pm/state";

import { FolioTiptapPageNode, FolioTiptapPagesNode } from "./index";

export function createPage(pageType: any, pageContent = null) {
  if (pageContent) {
    return pageType.createChecked({}, pageContent);
  }

  return pageType.createAndFill({});
}

export function getPagesNodeTypes(schema: any) {
  if (schema.cached.pagesNodeTypes) {
    return schema.cached.pagesNodeTypes;
  }

  const roles = {
    pages: schema.nodes.folioTiptapPages,
    page: schema.nodes.folioTiptapPage,
  };

  schema.cached.pagesNodeTypes = roles;

  return roles;
}

export function createPages(schema: any, pagesCount: any, pageContent = null) {
  const types = getPagesNodeTypes(schema);
  const pages = [];

  for (let index = 0; index < pagesCount; index += 1) {
    const page = createPage(types.page, pageContent);

    if (page) {
      // @ts-ignore
      pages.push(page);
    }
  }

  return types.pages.createChecked({ pageCount: pagesCount }, pages);
}

export function addOrDeletePage({
  state,
  dispatch,
  type,
}: {
  state: EditorState;
  dispatch: any;
  type: "addBefore" | "addAfter" | "delete";
}) {
  const maybePages = findParentNode(
    (node: Node) => node.type.name === FolioTiptapPagesNode.name,
  )(state.selection);
  const maybePage = findParentNode(
    (node: Node) => node.type.name === FolioTiptapPageNode.name,
  )(state.selection);

  if (dispatch && maybePages && maybePage) {
    const pages = maybePages.node;
    let pageIndex = null

    pages.content.forEach((childNode, pos, index) => {
      if (pageIndex !== null) return

      if (childNode === maybePage.node) {
        pageIndex = index;
        return
      }
    })

    if (pageIndex === null) {
      console.warn("Current page not found in pages node");
      return false;
    }

    const pagesJSON = pages.toJSON();

    let nextIndex = pageIndex;

    if (type === "delete") {
      // If we have 2 or fewer pages, replace the entire pages node with the combined contents
      if (pagesJSON.content.length <= 2) {
        // Collect all content from all pages
        const allContent = [];
        pagesJSON.content.forEach((page: { content: any[]; }) => {
          if (page.content && page.content.length > 0) {
            allContent.push(...page.content);
          }
        });

        // If no content, add an empty paragraph
        if (allContent.length === 0) {
          allContent.push({ type: "paragraph" });
        }

        const tr = state.tr;

        // Replace the entire pages node with the combined content
        tr.replaceWith(
          maybePages.pos,
          maybePages.pos + maybePages.node.nodeSize,
          allContent.map((content) => Node.fromJSON(state.schema, content)),
        );

        // Position cursor at the start of the replaced content
        tr.setSelection(
          TextSelection.near(tr.doc.resolve(maybePages.pos + 1)),
        );

        dispatch(tr);
        return true;
      }

      // For more than 2 pages, merge with adjacent page
      // Get the content of the page to be deleted
      const deletedPage = pagesJSON.content[pageIndex];
      const deletedContent = deletedPage.content || [];

      // Determine which page to merge with
      const targetIndex = pageIndex > 0 ? pageIndex - 1 : pageIndex + 1;
      const targetPage = pagesJSON.content[targetIndex];

      // Merge the content into the target page
      if (deletedContent.length > 0) {
        if (!targetPage.content) {
          targetPage.content = [];
        }
        targetPage.content.push(...deletedContent);
      }

      // Remove the deleted page
      pagesJSON.content.splice(pageIndex, 1);

      // Set next index for cursor positioning
      nextIndex = pageIndex > 0 ? pageIndex - 1 : 0;
    } else {
      nextIndex = type === "addBefore" ? pageIndex : pageIndex + 1;
      pagesJSON.content.splice(nextIndex, 0, {
        type: FolioTiptapPageNode.name,
        content: [
          {
            type: "paragraph",
          },
        ],
      });
    }

    const nextCols = Node.fromJSON(state.schema, pagesJSON);

    let nextSelectPos = maybePages.pos;
    nextCols.content.forEach((page, pos, index) => {
      if (index < nextIndex) {
        nextSelectPos += page.nodeSize;
      }
    });

    const tr = state.tr;

    tr.replaceWith(
      maybePages.pos,
      maybePages.pos + maybePages.node.nodeSize,
      nextCols,
    ).setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));

    dispatch(tr);
  }

  return true;
}

export function goToPage({
  state,
  dispatch,
  type,
}: {
  state: EditorState;
  dispatch: any;
  type: "before" | "after";
}) {
  const maybePages = findParentNode(
    (node: Node) => node.type.name === FolioTiptapPagesNode.name,
  )(state.selection);
  const maybePage = findParentNode(
    (node: Node) => node.type.name === FolioTiptapPageNode.name,
  )(state.selection);

  if (dispatch && maybePages && maybePage) {
    const pages = maybePages.node;
    const page  = maybePage.node
    let currentIndex = null;

    pages.content.forEach((childNode, pos, index) => {
      if (currentIndex !== null) return

      if (childNode === page) {
        currentIndex = index;
        return
      }

      index += 1;
    })

    if (currentIndex === null) {
      console.warn("Current page not found in pages node");
      return false;
    }

    const pageIndex = maybePage.node.attrs.index;

    let nextIndex = 0;

    if (type === "before") {
      nextIndex = (currentIndex - 1 + pages.childCount) % pages.childCount;
    } else {
      nextIndex = (currentIndex + 1) % pages.childCount;
    }

    let nextSelectPos = maybePages.pos;

    pages.content.forEach((childNode, pos, index) => {
      if (index < nextIndex) {
        nextSelectPos += childNode.nodeSize;
      }
    });

    const tr = state.tr;

    tr.setSelection(TextSelection.near(tr.doc.resolve(nextSelectPos)));
    dispatch(tr);

    return true;
  }

  return false;
}

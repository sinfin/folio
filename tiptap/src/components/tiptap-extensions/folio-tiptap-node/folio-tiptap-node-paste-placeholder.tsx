import * as React from "react";
import type { NodeViewProps } from "@tiptap/react";
import { NodeViewWrapper } from "@tiptap/react";

import "./folio-tiptap-node-paste-placeholder.scss";
import { storeHtmlToCache } from "./folio-tiptap-node";
import { insertFolioTiptapNodeWithParagraph } from "./insert-folio-tiptap-node-with-paragraph";

const CLASS_NAME = "f-tiptap-node-paste-placeholder";

export const FolioTiptapNodePastePlaceholderComponent: React.FC<
  NodeViewProps
> = (props) => {
  const { node, editor, getPos } = props;
  const { pasted_string, target_node_type, uniqueId } = node.attrs;

  // Effect to send paste request and handle response
  React.useEffect(() => {
    if (!uniqueId || !pasted_string || !target_node_type) {
      return;
    }

    // Send paste request to parent window
    window.parent!.postMessage(
      {
        type: "f-tiptap-node:paste",
        uniqueId,
        pasted_string,
        tiptap_node_type: target_node_type,
      },
      "*",
    );

    // Listen for response
    const handleMessage = (event: MessageEvent) => {
      if (
        process.env.NODE_ENV === "production" &&
        event.origin !== window.origin
      )
        return;

      if (
        event.data.type === "f-input-tiptap:paste-node" &&
        event.data.unique_id === uniqueId
      ) {
        const pos = getPos();
        if (typeof pos !== "number") return;

        if (event.data.tiptap_node) {
          // Success: Cache HTML if provided, then replace placeholder with actual node
          const { state } = editor.view;
          const { tr } = state;
          const nodeAttrs = {
            ...event.data.tiptap_node.attrs,
            uniqueId, // Preserve the uniqueId from the placeholder
          };

          // Store HTML in cache if provided, so the new node can use it immediately
          if (event.data.html) {
            const { uniqueId: _, ...attrsWithoutUniqueId } = nodeAttrs;
            const serializedAttrs = JSON.stringify(attrsWithoutUniqueId);
            storeHtmlToCache({
              html: event.data.html,
              serializedAttrs,
            });
          }

          const actualNode = editor.schema.nodes.folioTiptapNode.createChecked(
            nodeAttrs,
            null,
          );

          insertFolioTiptapNodeWithParagraph({
            node: actualNode,
            pos,
            tr,
            schema: editor.schema,
          });

          editor.view.dispatch(tr);
        } else if (event.data.error) {
          // Failure: Remove placeholder and show alert
          const { state } = editor.view;
          const { tr } = state;
          tr.delete(pos, pos + 1);
          editor.view.dispatch(tr);
          window.alert(event.data.error);
        }

        window.removeEventListener("message", handleMessage);
      }
    };

    window.addEventListener("message", handleMessage);

    return () => {
      window.removeEventListener("message", handleMessage);
    };
  }, [uniqueId, pasted_string, target_node_type, editor, getPos]);

  return (
    <NodeViewWrapper
      className={CLASS_NAME}
      data-pasted-string={pasted_string}
      data-target-node-type={target_node_type}
      data-unique-id={uniqueId}
    >
      <div className={`${CLASS_NAME}__loader-wrap rounded`}>
        <span className="folio-loader" />
      </div>
    </NodeViewWrapper>
  );
};

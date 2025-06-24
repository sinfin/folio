import * as React from "react";
import type { NodeViewProps } from "@tiptap/react";
import { NodeViewWrapper } from "@tiptap/react";
// import "@/components/tiptap-node/image-upload-node/image-upload-node.scss"

import "./folio-tiptap-node.scss";

let uniqueIdForNode = 0;
const getUniqueIdForNode = () => uniqueIdForNode++;

let htmlCache = [];

const storeHtmlToCache = ({ html, serializedAttrs }) => {
  htmlCache = [{ html, serializedAttrs }, ...htmlCache.slice(0, 9)];
};

export const FolioTiptapNode: React.FC<NodeViewProps> = (props) => {
  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented) {
        window.top!.postMessage(
          {
            type: "f-tiptap-node:click",
            attrs: props.node.attrs,
          },
          "*",
        );
      }
    },
    [],
  );

  const [uniqueId, setUniqueId] = React.useState<number>(0);
  const [loaded, setLoaded] = React.useState<boolean>(false);
  const [htmlFromApi, setHtmlFromApi] = React.useState<string>("");

  React.useEffect(() => {
    if (uniqueId === 0) {
      setUniqueId(getUniqueIdForNode());
    }
  }, [uniqueId]);

  // Effect to fetch HTML content from API
  React.useEffect(() => {
    if (!loaded && uniqueId !== 0) {
      const serializedAttrs = JSON.stringify(props.node.attrs);
      // Check if we have cached HTML for these attributes
      const cachedEntry = htmlCache.find(
        (entry) => entry.serializedAttrs === serializedAttrs,
      );

      if (cachedEntry) {
        setHtmlFromApi(cachedEntry.html);
        setLoaded(true);
        return;
      } else {
        window.top!.postMessage(
          {
            type: "f-tiptap-node:render",
            uniqueId,
            attrs: props.node.attrs,
          },
          "*",
        );
      }
    }
  }, [loaded, uniqueId]);

  // Effect to handle messages from the parent window
  React.useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data.type === "f-input-tiptap:render-nodes") {
        event.data.nodes.forEach((node: any) => {
          if (node.unique_id === uniqueId) {
            const serializedAttrs = JSON.stringify(props.node.attrs);
            storeHtmlToCache({ html: node.html, serializedAttrs });

            setHtmlFromApi(node.html);
            setLoaded(true);
          }
        });
      }
    };

    window.addEventListener("message", handleMessage);

    return () => {
      window.removeEventListener("message", handleMessage);
    };
  }, [uniqueId]);

  return (
    <NodeViewWrapper
      className="tiptap-folio-tiptap-node"
      tabIndex={0}
      onClick={handleClick}
    >
      {htmlFromApi ? (
        <div
          className="tiptap-folio-tiptap-node__html"
          dangerouslySetInnerHTML={{ __html: htmlFromApi }}
        />
      ) : (
        <div className="tiptap-folio-tiptap-node__loader-wrap rounded">
          <span className="folio-loader" />
        </div>
      )}
    </NodeViewWrapper>
  );
};

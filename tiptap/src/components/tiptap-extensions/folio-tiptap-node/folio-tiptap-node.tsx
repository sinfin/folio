import * as React from "react";
import type { NodeViewProps } from "@tiptap/react";
import { NodeViewWrapper } from "@tiptap/react";
import { Button } from "@/components/tiptap-ui-primitive/button";
import { EditIcon } from "@/components/tiptap-icons/edit-icon";
import { XIcon } from "@/components/tiptap-icons/x-icon";
import { FolioTiptapNodeExtension } from "./folio-tiptap-node-extension";

import translate from "@/lib/i18n";

import "./folio-tiptap-node.scss";

let uniqueIdForNode = 0;
const getUniqueIdForNode = () => uniqueIdForNode++;

const TRANSLATIONS = {
  cs: {
    remove: "Odstranit",
    edit: "Upravit",
  },
  en: {
    remove: "Remove",
    edit: "Edit",
  },
};

interface StoredHtml {
  html: string;
  serializedAttrs: string;
}

let htmlCache: StoredHtml[] = [];

const storeHtmlToCache = ({ html, serializedAttrs }: StoredHtml) => {
  htmlCache = [{ html, serializedAttrs }, ...htmlCache.slice(0, 9)];
};

export const FolioTiptapNode: React.FC<NodeViewProps> = (props) => {
  const [uniqueId, setUniqueId] = React.useState<number>(-1);
  const [loaded, setLoaded] = React.useState<boolean>(false);
  const [htmlFromApi, setHtmlFromApi] = React.useState<string>("");

  const wrapperRef = React.useRef<HTMLDivElement>(null);

  const handleEditClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented) {
        window.top!.postMessage(
          {
            type: "f-tiptap-node:click",
            attrs: props.node.attrs,
            uniqueId,
          },
          "*",
        );
      }
    },
    [props.node, uniqueId],
  );

  React.useEffect(() => {
    if (uniqueId === -1) {
      setUniqueId(getUniqueIdForNode());
    }
  }, [uniqueId]);

  // Effect to fetch HTML content from API
  React.useEffect(() => {
    if (!loaded && uniqueId !== -1) {
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

  // Effect to handle edit event
  React.useEffect(() => {
    if (wrapperRef && wrapperRef.current) {
      const wrapper = wrapperRef.current;

      // Add event listener for double-click to edit
      wrapper.addEventListener("f-tiptap-node:edit", handleEditClick);

      // Cleanup event listener on unmount
      return () => {
        wrapper.removeEventListener("f-tiptap-node:edit", handleEditClick);
      };
    }
  }, [wrapperRef, handleEditClick]);

  // Effect to handle messages from the parent window
  React.useEffect(() => {
    if (!loaded && uniqueId !== -1) {
      const handleMessage = (event: MessageEvent) => {
        if (
          process.env.NODE_ENV === "production" &&
          event.origin !== window.origin
        )
          return;

        if (event.data.type === "f-input-tiptap:render-nodes") {
          event.data.nodes.forEach((node: any) => {
            if (node.unique_id === uniqueId) {
              const serializedAttrs = JSON.stringify(props.node.attrs);
              storeHtmlToCache({ html: node.html, serializedAttrs });

              setHtmlFromApi(node.html);
              setLoaded(true);
            }
          });
        } else if (
          event.data &&
          event.data.type === "f-c-tiptap-overlay:saved" &&
          event.data.uniqueId === uniqueId
        ) {
          if (event.data.node && event.data.node.attrs) {
            setHtmlFromApi("");
            setLoaded(false);
            props.updateAttributes(event.data.node.attrs);
          }
        }
      };

      window.addEventListener("message", handleMessage);

      return () => {
        window.removeEventListener("message", handleMessage);
      };
    }
  }, [uniqueId, props]);

  return (
    <NodeViewWrapper className="f-tiptap-node" tabIndex={0} data-drag-handle="" onDoubleClick={handleEditClick} ref={wrapperRef}>
      {htmlFromApi ? (
        <div
          className="f-tiptap-node__html"
          dangerouslySetInnerHTML={{ __html: htmlFromApi }}
        />
      ) : (
        <div className="f-tiptap-node__loader-wrap rounded">
          <span className="folio-loader" />
        </div>
      )}
    </NodeViewWrapper>
  );
};

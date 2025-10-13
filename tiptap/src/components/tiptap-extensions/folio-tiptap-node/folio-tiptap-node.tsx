import * as React from "react";
import type { NodeViewProps } from "@tiptap/react";
import { NodeViewWrapper } from "@tiptap/react";
import { makeUniqueId } from './make-unique-id';
import { postEditMessage } from './post-edit-message';

import { InvalidNodeIndicator } from '@/components/tiptap-ui/invalid-node-indicator';

import translate from "@/lib/i18n";

import "./folio-tiptap-node.scss";

const TRANSLATIONS = {
  cs: {
    remove: "Odstranit",
    edit: "Upravit",
    errorMessage: "Tento obsah nebude veřejně zobrazen, protože při jeho zobrazení došlo k chybě. Můžete ho zkusit upravit nebo odstranit.",
    invalidMessage: "Tento obsah nebude veřejně zobrazen. Můžete ho upravit nebo odstranit.",
  },
  en: {
    remove: "Remove",
    edit: "Edit",
    errorMessage: "This content will not be publicly displayed because an error occurred while rendering it. You can try to edit or remove it.",
    invalidMessage: "This content will not be publicly displayed. You can edit or remove it.",
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

// Height storage functions
const getStoredHeight = (serializedAttrs: string): number | null => {
  try {
    const stored = sessionStorage.getItem(`f-tiptap-node-height:${serializedAttrs}`);
    return stored ? parseInt(stored, 10) : null;
  } catch {
    return null;
  }
};

const storeHeight = (serializedAttrs: string, height: number) => {
  try {
    sessionStorage.setItem(`f-tiptap-node-height:${serializedAttrs}`, height.toString());
  } catch {
    // Ignore storage errors
  }
};

interface RespnoseFromApiType {
  html?: string;
  invalid?: boolean;
  errorMessage?: string;
}

export const FolioTiptapNode: React.FC<NodeViewProps> = (props) => {
  const { uniqueId, ...attrsWithoutUniqueId } = props.node.attrs;

  // set uniqueId if one is not present
  React.useEffect(() => {
    if (!uniqueId) {
      props.updateAttributes({ uniqueId: makeUniqueId() });
    }
  }, [uniqueId]);

  if (!uniqueId) return

  const [status, setStatus] = React.useState<string>("initial");
  const [responseFromApi, setResponseFromApi] = React.useState<RespnoseFromApiType>({});

  const wrapperRef = React.useRef<HTMLDivElement>(null);
  const htmlRef = React.useRef<HTMLDivElement>(null);

  const handleEditClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented) {
        postEditMessage(attrsWithoutUniqueId, uniqueId);
      }
    },
    [attrsWithoutUniqueId, uniqueId],
  );

  const handleDomEditEvent = React.useCallback(
    (e: Event) => {
      postEditMessage(attrsWithoutUniqueId, uniqueId);
    },
    [attrsWithoutUniqueId, uniqueId],
  );

  // Effect to fetch HTML content from API
  React.useEffect(() => {
    if (status === "initial" && uniqueId) {
      const serializedAttrs = JSON.stringify(attrsWithoutUniqueId);

      // Check if we have cached HTML for these attributes
      const cachedEntry = htmlCache.find(
        (entry) => entry.serializedAttrs === serializedAttrs,
      );

      if (cachedEntry) {
        setStatus("loaded");
        setResponseFromApi({ html: cachedEntry.html });
        return;
      } else {
        setStatus("loading");

        window.parent!.postMessage(
          {
            type: "f-tiptap-node:render",
            uniqueId,
            attrs: attrsWithoutUniqueId,
          },
          "*",
        );
      }
    }
  }, [status, uniqueId]);

  // Effect to handle edit event
  React.useEffect(() => {
    if (wrapperRef && wrapperRef.current) {
      const wrapper = wrapperRef.current;

      // Add event listener for double-click to edit
      wrapper.addEventListener("f-tiptap-node:edit", handleDomEditEvent);

      // Cleanup event listener on unmount
      return () => {
        wrapper.removeEventListener("f-tiptap-node:edit", handleDomEditEvent);
      };
    }
  }, [wrapperRef, handleDomEditEvent]);

  // Effect to handle messages from the parent window
  React.useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (
        process.env.NODE_ENV === "production" &&
        event.origin !== window.origin
      )
        return;

      if (event.data.type === "f-input-tiptap:render-nodes") {
        event.data.nodes.forEach((node: any) => {
          if (node.unique_id === uniqueId) {
            if (node.html) {
              const serializedAttrs = JSON.stringify(attrsWithoutUniqueId);
              storeHtmlToCache({ html: node.html, serializedAttrs });

              setResponseFromApi({ html: node.html });
              setStatus("loaded");
            } else {
              setResponseFromApi({ invalid: true, errorMessage: node.error_message });
              setStatus("loaded");
            }
          }
        });
      } else if (
        event.data &&
        event.data.type === "f-c-tiptap-overlay:saved" &&
        event.data.uniqueId === uniqueId
      ) {
        if (event.data.node && event.data.node.attrs) {
          setResponseFromApi({});
          setStatus("initial");
          props.updateAttributes(event.data.node.attrs);
        }
      }
    };

    window.addEventListener("message", handleMessage);

    return () => {
      window.removeEventListener("message", handleMessage);
    };
  }, [uniqueId, props, status]);

  // Effect to measure and store height after HTML renders
  React.useEffect(() => {
    if (responseFromApi.html && htmlRef.current) {
      const serializedAttrs = JSON.stringify(attrsWithoutUniqueId);
      const height = htmlRef.current.offsetHeight;
      if (height > 0) {
        storeHeight(serializedAttrs, height);
      }
    }
  }, [responseFromApi.html, attrsWithoutUniqueId]);

  return (
    <NodeViewWrapper
      className="f-tiptap-node"
      tabIndex={0}
      data-drag-handle=""
      data-folio-tiptap-node-version={props.node.attrs.version}
      data-folio-tiptap-node-type={props.node.attrs.type}
      data-folio-tiptap-node-data={JSON.stringify(props.node.attrs.data)}
      data-folio-tiptap-node-unique-id={props.node.attrs.uniqueId}
      onDoubleClick={handleEditClick}
      ref={wrapperRef}
    >
      {responseFromApi.html ? (
        <div
          ref={htmlRef}
          className="f-tiptap-node__html"
          dangerouslySetInnerHTML={{ __html: responseFromApi.html }}
        />
      ) : (
        responseFromApi.invalid ? (
          <InvalidNodeIndicator
            invalidNodeHash={props.node.toJSON()}
            message={translate(TRANSLATIONS, responseFromApi.errorMessage ? 'errorMessage' : 'invalidMessage')}
            errorMessage={responseFromApi.errorMessage}
          />
        ) : (
          <div
            className="f-tiptap-node__loader-wrap rounded"
            style={(() => {
              const serializedAttrs = JSON.stringify(attrsWithoutUniqueId);
              const height = getStoredHeight(serializedAttrs);
              return height ? { height: `${height}px` } : undefined;
            })()}
          >
            <span className="folio-loader" />
          </div>
        )
      )}
    </NodeViewWrapper>
  );
};

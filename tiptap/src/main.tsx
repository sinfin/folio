import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./styles/_variables.scss";
import "./styles/_keyframe-animations.scss";
import "./styles/index.scss";
import "../../app/assets/stylesheets/folio/tiptap/_styles.scss";
import App from "./App.tsx";

import {
  addUniqueIdsToFolioTiptapNodes,
  removeUniqueIdsFromFolioTiptapNodes
} from '@/components/tiptap-extensions/folio-tiptap-node';

// Initialize the Folio namespace if it doesn't exist
window.Folio = window.Folio || {};
window.Folio.Tiptap = window.Folio.Tiptap || {};
window.Folio.Tiptap.root = window.Folio.Tiptap.root || null;

window.Folio.Tiptap.getHeight = () => {
  const editor = document.querySelector(".f-tiptap-editor")
  return editor ? editor.clientHeight : 0;
}

window.Folio.Tiptap.init = (props) => {
  if (window.Folio.Tiptap.root) {
    throw new Error("Tiptap editor is already initialized");
  }

  if (!props.node) {
    throw new Error("Node is required");
  }

  const onCreate = ({ editor }: { editor: TiptapEditor }) => {
    window.top!.postMessage(
      {
        type: "f-tiptap:created",
        height: window.Folio.Tiptap.getHeight(),
      },
      "*",
    );

    if (props.onCreate) {
      props.onCreate({ editor });
    }
  };

  const onUpdate = ({ editor }: { editor: TiptapEditor }) => {
    window.top!.postMessage(
      {
        type: "f-tiptap:updated",
        content: removeUniqueIdsFromFolioTiptapNodes(editor.getJSON()),
        height: window.Folio.Tiptap.getHeight(),
      },
      "*",
    );

    if (props.onUpdate) {
      props.onUpdate({ editor });
    }
  };

  let contentWithFolioTiptapNodeUniqueIds

  if (props.content) {
    contentWithFolioTiptapNodeUniqueIds = addUniqueIdsToFolioTiptapNodes(props.content);
  }

  const folioTiptapConfigDefaults = {
    nodes: [],
    styled_paragraph_variants: [],
    styled_wrap_variants: [],
    enable_pages: false,
  }

  const root = createRoot(props.node);
  root.render(
    <StrictMode>
      <App
        onCreate={onCreate}
        onUpdate={onUpdate}
        defaultContent={contentWithFolioTiptapNodeUniqueIds}
        type={props.type}
        folioTiptapConfig={props.folioTiptapConfig ? { ...folioTiptapConfigDefaults, ...props.folioTiptapConfig } : folioTiptapConfigDefaults}
        readonly={props.readonly}
      />
    </StrictMode>,
  );

  window.Folio.Tiptap.root = root;

  return root;
};

window.Folio.Tiptap.destroy = () => {
  if (!window.Folio.Tiptap.root) return;

  window.Folio.Tiptap.root.unmount();
  window.Folio.Tiptap.root = null;
};

window.addEventListener("message", (e) => {
  if (process.env.NODE_ENV === "production" && e.origin !== window.origin)
    return;
  if (!e.data) return;

  if (e.data.type === "f-input-tiptap:start") {
    if (!window.Folio.Tiptap.root) {
      const node = document.querySelector(
        ".f-tiptap-iframe-content",
      ) as HTMLElement;

      if (!node) {
        throw new Error("Node not found for Tiptap editor");
      }

      if (e.data.lang) {
        document.documentElement.lang = e.data.lang;
      }

      if (e.data.stylesheetPath) {
        const link = document.createElement("link");
        link.rel = "stylesheet";
        link.href = e.data.stylesheetPath;
        document.body.appendChild(link);
      }

      node.classList.toggle(
        "f-tiptap-iframe-content--console-aside",
        !!e.data.windowWidth && e.data.windowWidth >= 1700,
      );

      window.Folio.Tiptap.init({
        node,
        type: node.dataset.tiptapType === "block" ? "block" : "rich-text",
        folioTiptapConfig: e.data.folioTiptapConfig,
        content: e.data.content,
        readonly: !!e.data.readonly,
      });
    }
  } else if (e.data.type === "f-input-tiptap:window-resize") {
    const node = document.querySelector(
      ".f-tiptap-iframe-content",
    ) as HTMLElement;

    if (node) {
      node.classList.toggle(
        "f-tiptap-iframe-content--console-aside",
        !!e.data.windowWidth && e.data.windowWidth >= 1700,
      );
    }
  }
});

// Only run this in dev and not in an iframe
if (process.env.NODE_ENV !== "production" && window.top === window) {
  const rootElement = document.getElementById("folio-tiptap-dev-root");

  if (rootElement) {
    const defaultContent = {"type":"doc","content":[{"type":"folioTiptapPages","attrs":{"count":2},"content":[{"type":"folioTiptapPage","attrs":{"index":0},"content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"prvni stranka"}]}]},{"type":"folioTiptapPage","attrs":{"index":0},"content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"druha stranka"}]}]}]},{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Lorem 1 ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor "},{"type":"text","marks":[{"type":"link","attrs":{"href":"/asf","target":null,"rel":null,"class":null}}],"text":"incididunt ut labore"},{"type":"text","text":" et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."}]},{"type":"table","content":[{"type":"tableRow","content":[{"type":"tableHeader","attrs":{"colspan":1,"rowspan":1,"colwidth":null},"content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"1"}]}]},{"type":"tableHeader","attrs":{"colspan":1,"rowspan":1,"colwidth":null},"content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"2"}]}]}]},{"type":"tableRow","content":[{"type":"tableCell","attrs":{"colspan":1,"rowspan":1,"colwidth":null},"content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"3"}]}]},{"type":"tableCell","attrs":{"colspan":1,"rowspan":1,"colwidth":null},"content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"4"}]}]}]}]},{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Lorem 2 ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."}]},{"type":"folioTiptapFloat","attrs":{"side":"left","size":"medium"},"content":[{"type":"folioTiptapFloatAside","content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Floated to the left lorem 2 ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "}]}]},{"type":"folioTiptapFloatMain","content":[{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Lorem main ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.  proident, sunt in culpa qui officia deserunt mollit anim id est laborum, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."}]}]}]},{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Lorem 3 ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."}]},{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Lorem 4 ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."}]},{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Lorem 5 ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."}]},{"type":"paragraph","attrs":{"textAlign":null},"content":[{"type":"text","text":"Lorem 6 ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."}]}]}

    window.Folio.Tiptap.init({
      node: rootElement,
      type:
        (rootElement as HTMLElement).dataset.tiptapType === "block"
          ? "block"
          : "rich-text",
      content: defaultContent,
      readonly: false,
      folioTiptapConfig: {
        enable_pages: true,
      },
      onCreate: ({ editor }: { editor: TiptapEditor }) => {
        const json = removeUniqueIdsFromFolioTiptapNodes(editor.getJSON());
        if (typeof json !== "object" || json === null) {
          throw new Error("getJSON must return a hash");
        }
        console.log("onCreate", json);
      },
      onUpdate: ({ editor }: { editor: TiptapEditor }) => {
        const json = removeUniqueIdsFromFolioTiptapNodes(editor.getJSON());
        if (typeof json !== "object" || json === null) {
          throw new Error("getJSON must return a hash");
        }
        console.log("onUpdate", json);
      },
    });
  }
}

window.top!.postMessage({ type: "f-tiptap:javascript-evaluated" }, "*");

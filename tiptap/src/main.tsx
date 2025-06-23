import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./styles/_variables.scss";
import "./styles/_keyframe-animations.scss";
import "./styles/index.scss";
import App from "./App.tsx";

// Initialize the Folio namespace if it doesn't exist
window.Folio = window.Folio || {};
window.Folio.Tiptap = window.Folio.Tiptap || {};
window.Folio.Tiptap.root = window.Folio.Tiptap.root || null;

window.Folio.Tiptap.init = (props) => {
  if (window.Folio.Tiptap.root) {
    throw new Error("Tiptap editor is already initialized");
  }

  if (!props.node) {
    throw new Error("Node is required");
  }

  const height = (editor: TiptapEditor) => {
    return editor.view!.dom!.closest('.f-tiptap-editor')!.clientHeight
  };

  const onCreate = ({ editor }: { editor: TiptapEditor }) => {
    window.top!.postMessage(
      {
        type: "f-tiptap:created",
        height: height(editor),
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
        content: editor.getJSON(),
        height: height(editor),
      },
      "*",
    );

    if (props.onUpdate) {
      props.onUpdate({ editor });
    }
  };

  const root = createRoot(props.node);
  root.render(
    <StrictMode>
      <App
        onCreate={onCreate}
        onUpdate={onUpdate}
        defaultContent={props.content}
        type={props.type}
      />
    </StrictMode>,
  );

  return root;
};

window.Folio.Tiptap.destroy = (root: ReturnType<typeof createRoot>) => {
  if (!root) return;
  root.unmount();
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

      if (e.data.stylesheetPath) {
        const link = document.createElement("link");
        link.rel = "stylesheet";
        link.href = e.data.stylesheetPath;
        document.head.insertBefore(link, document.head.firstChild);
      }

      node.classList.toggle('f-tiptap-iframe-content--console-aside', !!e.data.windowWidth && e.data.windowWidth >= 1700);

      window.Folio.Tiptap.init({
        node,
        type: node.dataset.tiptapType === "block" ? "block" : "rich-text",
        content: e.data.content,
      });
    }
  } else if (e.data.type === "f-input-tiptap:window-resize") {
    const node = document.querySelector(
      ".f-tiptap-iframe-content",
    ) as HTMLElement;

    if (node) {
      node.classList.toggle('f-tiptap-iframe-content--console-aside', !!e.data.windowWidth && e.data.windowWidth >= 1700);
    }
  }
});

// Only run this in dev and not in an iframe
if (process.env.NODE_ENV !== "production" && window.top === window) {
  const rootElement = document.getElementById("folio-tiptap-dev-root");

  if (rootElement) {
    window.Folio.Tiptap.init({
      node: rootElement,
      type:
        (rootElement as HTMLElement).dataset.tiptapType === "block"
          ? "block"
          : "rich-text",
      // content: demoContent,
      // onCreate: ({ editor }: { editor: TiptapEditor }) => {
      //   const json = editor.getJSON();
      //   if (typeof json !== "object" || json === null) {
      //     throw new Error("getJSON must return a hash");
      //   }
      //   console.log("onCreate", json);
      // },
      // onUpdate: ({ editor }: { editor: TiptapEditor }) => {
      //   const json = editor.getJSON();
      //   if (typeof json !== "object" || json === null) {
      //     throw new Error("getJSON must return a hash");
      //   }
      //   console.log("onUpdate", json);
      // },
    });
  }
}

window.top!.postMessage({ type: "f-tiptap:javascript-evaluated" }, "*");

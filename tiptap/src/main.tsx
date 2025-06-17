import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import "./styles/_variables.scss";
import "./styles/_keyframe-animations.scss";
import App from "./App.tsx";

import demoContent from "@/components/tiptap-templates/simple/data/content.json";

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

  const onCreate = ({ editor }: { editor: TiptapEditor }) => {
    window.top!.postMessage(
      {
        type: "f-tiptap:created",
        height: props.node.clientHeight,
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
        height: props.node.clientHeight,
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
      window.Folio.Tiptap.init({
        node: document.getElementById("folio-tiptap-dev-root") || document.body,
        content: e.data.content,
      });
    }
  }
});

// Only run this in dev and not in an iframe
if (process.env.NODE_ENV !== "production" && window.top === window) {
  const rootElement = document.getElementById("folio-tiptap-dev-root");

  if (rootElement) {
    window.Folio.Tiptap.init({
      node: rootElement,
      content: demoContent,
      onCreate: ({ editor }: { editor: TiptapEditor }) => {
        const json = editor.getJSON();
        if (typeof json !== "object" || json === null) {
          throw new Error("getJSON must return a hash");
        }
        console.log("onCreate", json);
      },
      onUpdate: ({ editor }: { editor: TiptapEditor }) => {
        const json = editor.getJSON();
        if (typeof json !== "object" || json === null) {
          throw new Error("getJSON must return a hash");
        }
        console.log("onUpdate", json);
      },
    });
  }
}

window.top!.postMessage(
  { type: "f-tiptap:javascript-evaluated" },
  "*",
);

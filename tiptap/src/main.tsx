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

window.Folio.Tiptap.init = (props) => {
  if (!props.node) {
    throw new Error('Node is required');
  }

  const root = createRoot(props.node);
  root.render(
    <StrictMode>
      <App onUpdate={props.onUpdate} defaultContent={props.content} />
    </StrictMode>,
  );

  return root;
};

window.Folio.Tiptap.destroy = (root: ReturnType<typeof createRoot>) => {
  if (!root) return;
  root.unmount();
};

// Don't run this in production build
if (process.env.NODE_ENV !== "production") {
  const rootElement = document.getElementById("folio-tiptap-dev-root");

  if (rootElement) {
    window.Folio.Tiptap.init({
      node: rootElement,
      content: demoContent,
      onUpdate: ({ editor }: { editor: { getJSON: () => Record<string, unknown> } }) => {
        const json = editor.getJSON();
        if (typeof json !== 'object' || json === null) {
          throw new Error('getJSON must return a hash');
        }
        console.log(json);
      }
    });
  }
}

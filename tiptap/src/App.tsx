import { FolioEditor } from "@/components/tiptap-editors/folio/folio-editor";
import type { Content } from "@tiptap/react";

import "./App.css";

interface AppProps {
  onUpdate?: (content: { editor: TiptapEditor }) => void;
  onCreate?: (content: { editor: TiptapEditor }) => void;
  defaultContent?: Content;
  type?: "rich-text" | "block";
  folioTiptapNodes: FolioTiptapNodeFromInput[];
}

function App({
  onCreate,
  onUpdate,
  defaultContent,
  type,
  folioTiptapNodes,
}: AppProps) {
  switch (type) {
    case "block":
    case "rich-text":
      return (
        <FolioEditor
          onCreate={onCreate}
          onUpdate={onUpdate}
          defaultContent={defaultContent}
          type={type as "block" | "rich-text"}
          folioTiptapNodes={folioTiptapNodes}
        />
      );
    default:
      throw new Error(`Unknown editor type: ${type}`);
  }
}

export default App;

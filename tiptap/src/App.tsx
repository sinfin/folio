import { BlockEditor } from "@/components/tiptap-editors/block/block-editor";
import { RichTextEditor } from "@/components/tiptap-editors/rich-text/rich-text-editor";

import "./App.css";

interface AppProps {
  onUpdate?: (content: { editor: TiptapEditor }) => void;
  onCreate?: (content: { editor: TiptapEditor }) => void;
  defaultContent?: any;
  type?: "rich-text" | "block";
}

function App({ onCreate, onUpdate, defaultContent, type }: AppProps) {
  switch (type) {
    case "rich-text":
      return (
        <RichTextEditor
          onCreate={onCreate}
          onUpdate={onUpdate}
          defaultContent={defaultContent}
        />
      );
    case "block":
      return (
        <BlockEditor
          onCreate={onCreate}
          onUpdate={onUpdate}
          defaultContent={defaultContent}
        />
      );
    default:
      throw new Error(`Unknown editor type: ${type}`);
      break;
  }
}

export default App;

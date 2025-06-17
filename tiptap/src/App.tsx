import { RichTextEditor } from "@/components/tiptap-editors/rich-text/rich-text-editor";

import "./App.css";

interface AppProps {
  onUpdate?: (content: { editor: { getJSON: () => Record<string, unknown> } }) => void;
  onCreate?: (content: { editor: { getJSON: () => Record<string, unknown> } }) => void;
  defaultContent?: any;
  type?: "rich-text" | "block";
}

function App({ onCreate, onUpdate, defaultContent, type }: AppProps) {
  switch (type) {
    case "rich-text":
      return <RichTextEditor
        onCreate={onCreate}
        onUpdate={onUpdate}
        defaultContent={defaultContent}
      />
    case "block":
      throw new Error(`To be implemented: ${type}`);
      break;
    default:
      throw new Error(`Unknown editor type: ${type}`);
      break;
  }
}

export default App;

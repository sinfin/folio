import { SimpleEditor } from "@/components/tiptap-templates/simple/simple-editor";

import "./App.css";

interface AppProps {
  onUpdate?: (content: { editor: { getJSON: () => Record<string, unknown> } }) => void;
  onCreate?: (content: { editor: { getJSON: () => Record<string, unknown> } }) => void;
  defaultContent?: any;
}

function App({ onCreate, onUpdate, defaultContent }: AppProps) {
  return <SimpleEditor
    onCreate={onCreate}
    onUpdate={onUpdate}
    defaultContent={defaultContent}
  />;
}

export default App;

import { SimpleEditor } from "@/components/tiptap-templates/simple/simple-editor";

import "./App.css";

interface AppProps {
  onUpdate?: (content: { editor: { getJSON: () => Record<string, unknown> } }) => void;
  defaultContent?: any;
}

function App({ onUpdate, defaultContent }: AppProps) {
  return <SimpleEditor onUpdate={onUpdate} defaultContent={defaultContent} />;
}

export default App;

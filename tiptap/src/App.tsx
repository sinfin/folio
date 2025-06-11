import { SimpleEditor } from "@/components/tiptap-templates/simple/simple-editor";

import "./App.css";

interface AppProps {
  onUpdate?: (content: { editor: { getJSON: () => Record<string, unknown> } }) => void;
}

function App({ onUpdate }: AppProps) {
  return <SimpleEditor onUpdate={onUpdate} />;
}

export default App;

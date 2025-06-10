import {registerDragonSupport} from '@lexical/dragon';
import {createEmptyHistoryState, registerHistory} from '@lexical/history';
import {HeadingNode, QuoteNode, registerRichText} from '@lexical/rich-text';
import {mergeRegister} from '@lexical/utils';
import {$generateHtmlFromNodes} from '@lexical/html';
import {createEditor, HISTORY_MERGE_TAG} from 'lexical';

window.Folio = window.Folio || {}
window.Folio.Lexical = window.Folio.Lexical || {}

window.Folio.Lexical.bind = ({ element }) => {
  element.innerHTML = `
    <div>
      <h1>Lexical Basic - Vanilla JS</h1>
      <div class="editor-wrapper">
        <div class="lexical-editor" contenteditable></div>
      </div>

      <div style="display: flex; gap: 1rem; justify-content: space-between;">
        <div style="flex: 0 0 calc(50% - 0.5rem)">
          <h4>Editor state:</h4>
          <textarea class="lexical-state" rows="50" style="box-sizing: border-box; min-width: 100%;"></textarea>
        </div>

        <div style="flex: 0 0 calc(50% - 0.5rem)">
          <h4>Exported HTML:</h4>
          <textarea class="lexical-export" rows="50" style="box-sizing: border-box; min-width: 100%;"></textarea>
        </div>
      </div>
    </div>
  `;

  const editorRef = element.querySelector('.lexical-editor');
  const stateRef = element.querySelector('.lexical-state');
  const exportRef = element.querySelector('.lexical-export');

  const initialConfig = {
    namespace: 'Folio Lexical',
    // Register nodes specific for @lexical/rich-text
    nodes: [HeadingNode, QuoteNode],
    onError: (error) => { throw error },
    theme: {
      quote: 'FolioLexical__quote',
    },
  };

  const editor = createEditor(initialConfig);
  editor.setRootElement(editorRef);

  // Registering Plugins
  mergeRegister(
    registerRichText(editor),
    registerDragonSupport(editor),
    registerHistory(editor, createEmptyHistoryState(), 300),
  );

  // editor.update(prepopulatedRichText, {tag: HISTORY_MERGE_TAG});

  editor.registerUpdateListener(({editorState}) => {
    stateRef.value = JSON.stringify(editorState.toJSON(), undefined, 2);
    editor.update(() => {
      const html = $generateHtmlFromNodes(editor, null)
      console.log(html)
      exportRef.value = html
    })
  });
}

if (document.getElementById('lexical-demo-editor')) {
  window.Folio.Lexical.bind({ element: document.getElementById('lexical-demo-editor') })
}

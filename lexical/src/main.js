import {registerDragonSupport} from '@lexical/dragon';
import {createEmptyHistoryState, registerHistory} from '@lexical/history';
import {HeadingNode, QuoteNode, registerRichText} from '@lexical/rich-text';
import {mergeRegister} from '@lexical/utils';
import {$generateHtmlFromNodes} from '@lexical/html';
import {createEditor, HISTORY_MERGE_TAG} from 'lexical';

import getToolbarHtml from './plugins/toolbar/ui';

window.Folio = window.Folio || {}

window.Folio = window.Folio || {}
window.Folio.Stimulus = window.Folio.Stimulus || {}

window.Folio.Stimulus.APPLICATION = window.Stimulus.Application.start()

window.Folio.Stimulus.register = (name, klass) => {
  window.Folio.Stimulus.APPLICATION.register(name, klass)
}

window.Folio.Lexical = window.Folio.Lexical || {}

window.Folio.Stimulus.register('f-lexical-editor', class extends window.Stimulus.Controller {
  static targets = ["editor"]

  connect () {
    this.setupDom()
    this.initLexical()
  }

  setupDom () {
    const html = `
      ${getToolbarHtml()}
      <div class="f-lexical-editor__editor p-3 border" contenteditable data-f-lexical-editor-target="editor"></div>
    `
    this.element.dataset.action = "f-lexical-editor-toolbar:toolbarAction->f-lexical-editor#toolbarAction"

    this.element.innerHTML = html
  }

  initLexical () {
    const stateRef = document.querySelector('.lexical-state');
    const exportRef = document.querySelector('.lexical-export');
    const exportHtmlRef = document.querySelector('.lexical-export-html');

    const initialConfig = {
      namespace: 'Folio Lexical',
      // Register nodes specific for @lexical/rich-text
      nodes: [HeadingNode, QuoteNode],
      onError: (error) => { throw error },
      theme: {
        quote: 'FolioLexical__quote',
      },
    };

    this.lexicalEditor = createEditor(initialConfig);
    this.lexicalEditor.setRootElement(this.editorTarget);

    // Registering Plugins
    mergeRegister(
      registerRichText(this.lexicalEditor),
      registerDragonSupport(this.lexicalEditor),
      registerHistory(this.lexicalEditor, createEmptyHistoryState(), 300),
    );

    // this.lexicalEditor.update(prepopulatedRichText, {tag: HISTORY_MERGE_TAG});

    this.lexicalEditor.registerUpdateListener(({editorState}) => {
      stateRef.value = JSON.stringify(editorState.toJSON(), undefined, 2);

      this.lexicalEditor.update(() => {
        let html = $generateHtmlFromNodes(this.lexicalEditor, null)
        if (html === "<p><br></p>") html = ''

        exportRef.value = html
        exportHtmlRef.innerHTML = html
      })
    });
  }

  toolbarAction (e) {
    const action = e.detail.action
    console.log('toolbarAction', action);
    action.command(this.lexicalEditor);
  }
})

window.Folio.Lexical.bind = ({ element }) => {
  element.innerHTML = `
    <div class="p-3">
      <h1>Lexical Basic - Vanilla JS</h1>
      <div class="f-lexical-editor" data-controller="f-lexical-editor">
      </div>

      <div class="mt-3" style="display: flex; gap: 1rem; justify-content: space-between;">
        <div style="flex: 0 0 calc(50% - 0.5rem)">
          <h4>Editor state:</h4>
          <textarea class="lexical-state" rows="50" style="box-sizing: border-box; min-width: 100%;"></textarea>
        </div>

        <div style="flex: 0 0 calc(50% - 0.5rem)">
          <h4>Exported HTML:</h4>
          <textarea class="lexical-export" rows="50" style="box-sizing: border-box; min-width: 100%;"></textarea>
        </div>
      </div>

      <h4 class="mt-3">Rendered HTML:</h4>
      <div class="lexical-export-html"></div>
    </div>
  `;
}

if (document.getElementById('lexical-demo-editor')) {
  window.Folio.Lexical.bind({ element: document.getElementById('lexical-demo-editor') })
}

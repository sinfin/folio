const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const vm = require('node:vm')

function overlayForInput (usageRecord) {
  let Overlay
  const source = {}
  const input = {
    dataset: {
      fInputTiptapPlacementTypeValue: 'Dummy::Blog::Article',
      fInputTiptapPlacementIdValue: '123',
      fInputTiptapAttributeNameValue: 'tiptap_content',
      fInputTiptapUsageRecordValue: usageRecord
    },
    querySelector: () => ({ contentWindow: source })
  }
  const context = {
    window: {
      Stimulus: { Controller: class {} },
      Folio: { Stimulus: { register: (_name, controller) => { Overlay = controller } } }
    },
    document: { querySelectorAll: () => [input] }
  }
  const asset = path.resolve(__dirname, '../../../../../app/components/folio/console/tiptap/overlay_component.js')
  vm.runInNewContext(fs.readFileSync(asset, 'utf8'), context)

  return { overlay: new Overlay(), source }
}

test('opening a Tiptap node sends its parent record context to the form API', () => {
  const { overlay, source } = overlayForInput('signed-parent-record')
  let request
  overlay.ajax = (options) => { request = options }
  overlay.onNodeClickMessage({ source, data: { attrs: { type: 'Dummy::Tiptap::Node::Card' } } })

  assert.equal(request.data.tiptap_editor_context.usage_record, 'signed-parent-record')
  assert.equal(request.data.tiptap_editor_context.placement_id, '123')
})

test('opening a Tiptap node without a persisted parent omits the usage record context', () => {
  const { overlay, source } = overlayForInput(undefined)
  const context = overlay.editorContextForSource(source)

  assert.equal(context.usage_record, undefined)
})

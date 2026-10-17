const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const vm = require('node:vm')

function indexModal () {
  let IndexModal
  const context = {
    URL,
    window: {
      location: { origin: 'https://dummy.example' },
      Stimulus: { Controller: class {} },
      Folio: { Stimulus: { register: (_name, controller) => { IndexModal = controller } } }
    }
  }
  const asset = path.resolve(__dirname, '../../../../../app/components/folio/console/files/index_modal_component.js')
  vm.runInNewContext(fs.readFileSync(asset, 'utf8'), context)

  return new IndexModal()
}

function turboFrame (src) {
  return {
    srcChanges: 0,
    attributes: { src },
    getAttribute (name) { return this.attributes[name] },
    setAttribute (name, value) {
      this.attributes[name] = value
      this.srcChanges += 1
    }
  }
}

test('reopening the modal with the same usage record keeps the loaded frame', () => {
  const modal = indexModal()
  const frame = turboFrame('https://dummy.example/console/file/images/index_for_modal?by_query=cover&usage_record=signed')

  modal.setUsageRecord(frame, 'signed')

  assert.equal(frame.srcChanges, 0)
})

test('opening the modal for a usage record updates an absolute frame src once', () => {
  const modal = indexModal()
  const frame = turboFrame('https://dummy.example/console/file/images/index_for_modal?by_query=cover')

  modal.setUsageRecord(frame, 'signed')
  modal.setUsageRecord(frame, 'signed')

  assert.equal(frame.srcChanges, 1)
  assert.equal(frame.getAttribute('src'), 'https://dummy.example/console/file/images/index_for_modal?by_query=cover&usage_record=signed')
})

test('opening the modal without a usage record drops the previous one', () => {
  const modal = indexModal()
  const frame = turboFrame('/console/file/images/index_for_modal?usage_record=signed&by_query=cover')

  modal.setUsageRecord(frame, undefined)

  assert.equal(frame.getAttribute('src'), 'https://dummy.example/console/file/images/index_for_modal?by_query=cover')
})

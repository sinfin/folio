window.Folio.Stimulus.register('f-c-tiptap-overlay-form-nested-nodes', class extends window.Stimulus.Controller {
  static targets = ['item', 'items', 'template', 'title']

  addNestedNode () {
    const item = this.buildItemFromTemplate()
    if (!item) return

    this.itemsTarget.append(item)
    this.startReactNodes(item)
    this.updatePositions()
  }

  removeNestedNode (e) {
    const item = this.closestItem(e.target)
    if (!item) return

    this.stopReactNodes(item)
    item.remove()
    this.updatePositions()
  }

  duplicateNestedNode (e) {
    const item = this.closestItem(e.target)
    if (!item) return

    const clone = item.cloneNode(true)
    this.copyFormValues(item, clone)
    this.replaceUiKey(clone, item.dataset.nestedNodeUiKey, this.newUiKey())

    item.after(clone)
    this.startReactNodes(clone)
    this.updatePositions()
  }

  moveNestedNodeUp (e) {
    const item = this.closestItem(e.target)
    if (!item || !item.previousElementSibling) return

    item.previousElementSibling.before(item)
    this.updatePositions()
  }

  moveNestedNodeDown (e) {
    const item = this.closestItem(e.target)
    if (!item || !item.nextElementSibling) return

    item.nextElementSibling.after(item)
    this.updatePositions()
  }

  buildItemFromTemplate () {
    const fragment = this.templateTarget.content.cloneNode(true)
    const item = fragment.querySelector('[data-f-c-tiptap-overlay-form-nested-nodes-target~="item"]')
    if (!item) return null

    this.replaceUiKey(item, 'NEW_RECORD', this.newUiKey())

    return item
  }

  replaceUiKey (item, oldKey, newKey) {
    item.dataset.nestedNodeUiKey = newKey

    for (const element of item.querySelectorAll('[name]')) {
      element.name = element.name.replace(`[${oldKey}]`, `[${newKey}]`)
    }

    for (const element of item.querySelectorAll('[id]')) {
      element.id = element.id.replace(`_${oldKey}_`, `_${newKey}_`)
    }

    for (const element of item.querySelectorAll('[for]')) {
      element.htmlFor = element.htmlFor.replace(`_${oldKey}_`, `_${newKey}_`)
    }
  }

  copyFormValues (source, clone) {
    const sourceFields = source.querySelectorAll('input, textarea, select')
    const cloneFields = clone.querySelectorAll('input, textarea, select')

    sourceFields.forEach((sourceField, index) => {
      const cloneField = cloneFields[index]
      if (!cloneField) return

      if (sourceField.type === 'checkbox' || sourceField.type === 'radio') {
        cloneField.checked = sourceField.checked
      } else {
        cloneField.value = sourceField.value
      }
    })
  }

  updatePositions () {
    this.itemTargets.forEach((item, index) => {
      const title = item.querySelector('[data-f-c-tiptap-overlay-form-nested-nodes-target~="title"]')
      if (title) title.textContent = title.textContent.replace(/#\d+$/, `#${index + 1}`)

      const upButton = item.querySelector('[data-action*="#moveNestedNodeUp"]')
      const downButton = item.querySelector('[data-action*="#moveNestedNodeDown"]')

      if (upButton) upButton.disabled = index === 0
      if (downButton) downButton.disabled = index === this.itemTargets.length - 1
    })
  }

  closestItem (target) {
    return target.closest('[data-f-c-tiptap-overlay-form-nested-nodes-target~="item"]')
  }

  startReactNodes (container) {
    for (const reactNode of container.querySelectorAll('.folio-react-wrap')) {
      window.FolioConsole.React.init(reactNode)
    }
  }

  stopReactNodes (container) {
    for (const reactNode of container.querySelectorAll('.folio-react-wrap')) {
      window.FolioConsole.React.destroy(reactNode)
    }
  }

  newUiKey () {
    this.uiKeyCounter = (this.uiKeyCounter || 0) + 1

    return `item_${Date.now()}_${this.uiKeyCounter}`
  }
})

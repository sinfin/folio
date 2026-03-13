//= require tom-select.complete
//= require folio/i18n
//= require folio/api
//= require folio/remote_scripts
//= require folio/debounce

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}
window.Folio.Input.OrderedMultiselect = {}

window.Folio.Input.OrderedMultiselect.I18n = {
  cs: {
    add: 'Přidat...',
    remove: 'Odebrat',
    create: 'Vytvořit',
    rename: 'Přejmenovat',
    cancel: 'Zrušit',
    deleteFromDb: 'Smazat',
    deleteFromDbConfirm: 'Smazat tento záznam z databáze?',
    deleteWarning: 'Tato položka je přiřazena k %{count} dalším záznamům. Smazání ji odebere ze všech. Pokračovat?',
    deleteWarningWithLabels: 'Tato položka je přiřazena k %{count} záznamům:\n%{list}\n\nSmazáním z databáze ji odeberete ze všech.',
    alreadyExists: 'Položka s tímto názvem již existuje.',
    alreadyOnList: 'Tato položka je již na seznamu.',
    deleted: 'Smazáno',
    usedIn: 'Použito v:',
    notUsed: 'Nikde nepoužito',
    noResults: 'Žádné výsledky'
  },
  en: {
    add: 'Add...',
    remove: 'Remove',
    create: 'Create',
    rename: 'Rename',
    cancel: 'Cancel',
    deleteFromDb: 'Delete',
    deleteFromDbConfirm: 'Delete this record from database?',
    deleteWarning: 'This item is assigned to %{count} other records. Deleting it will remove it from all of them. Continue?',
    deleteWarningWithLabels: 'This item is assigned to %{count} records:\n%{list}\n\nDeleting it from the database will remove it from all of them.',
    alreadyExists: 'An item with this name already exists.',
    alreadyOnList: 'This item is already on the list.',
    deleted: 'Deleted',
    usedIn: 'Used in:',
    notUsed: 'Not used anywhere',
    noResults: 'No results'
  }
}

window.Folio.Input.OrderedMultiselect.t = (key) => {
  return window.Folio.i18n(window.Folio.Input.OrderedMultiselect.I18n, key)
}

window.Folio.Input.OrderedMultiselect.escapeHtml = (str) => {
  const div = document.createElement('div')
  div.textContent = str
  return div.innerHTML
}

window.Folio.Input.OrderedMultiselect.isDuplicateLabel = (value, currentLabel, existingLabels, loadedOptions) => {
  if (!value || !value.trim()) return false
  const normalized = value.trim().toLowerCase()
  if (currentLabel && normalized === currentLabel.toLowerCase()) return false
  if (existingLabels && existingLabels.some((l) => l.toLowerCase().trim() === normalized)) return true
  if (loadedOptions) {
    const opts = Array.isArray(loadedOptions) ? loadedOptions : Object.values(loadedOptions)
    if (opts.some((o) => o.text && o.text.toLowerCase().trim() === normalized)) return true
  }
  return false
}

window.Folio.Input.OrderedMultiselect.iconHtml = (name, opts) => {
  const cacheKey = `_icon_${name}`
  if (!window.Folio.Input.OrderedMultiselect[cacheKey]) {
    if (window.Folio.Ui && window.Folio.Ui.Icon) {
      window.Folio.Input.OrderedMultiselect[cacheKey] = window.Folio.Ui.Icon.create(name, opts || { height: 16 }).outerHTML
    } else {
      window.Folio.Input.OrderedMultiselect[cacheKey] = name
    }
  }
  return window.Folio.Input.OrderedMultiselect[cacheKey]
}

window.Folio.Input.OrderedMultiselect.usageHintHtml = (usageLabels, cssClass, showEmpty) => {
  const t = window.Folio.Input.OrderedMultiselect.t
  if (!usageLabels || usageLabels.length === 0) {
    if (!showEmpty) return ''
    return `<span class="${cssClass}">${t('notUsed')}</span>`
  }
  const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
  return `<span class="${cssClass}">${t('usedIn')} ${escape(usageLabels.join(', '))}</span>`
}

window.Folio.Stimulus.register('f-input-ordered-multiselect', class extends window.Stimulus.Controller {
  static values = {
    items: { type: Array, default: [] },
    removedItems: { type: Array, default: [] },
    url: String,
    paramBase: String,
    foreignKey: String,
    sortable: { type: Boolean, default: true },
    currentRecordLabel: { type: String, default: '' },
    createable: { type: Boolean, default: false },
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  static targets = ['list', 'select', 'hiddenContainer']

  connect () {
    this.loadedOptions = {}
    this.initTomSelect()

    if (this.sortableValue) {
      this.initSortable()
    }

    this.renderList()
    this.syncHiddenInputs()
  }

  disconnect () {
    if (this._onDocumentMousedown) {
      document.removeEventListener('mousedown', this._onDocumentMousedown, true)
      this._onDocumentMousedown = null
    }
    this.destroyTomSelect()
    this.destroySortable()
  }

  // --- Tom Select ---

  initTomSelect () {
    const self = this
    const t = window.Folio.Input.OrderedMultiselect.t

    const config = {
      placeholder: t('add'),
      plugins: {},
      valueField: 'value',
      labelField: 'text',
      searchField: ['text'],
      sortField: [{ field: 'text', direction: 'asc' }],
      score (search) {
        const lc = search.toLowerCase()
        return function (item) {
          return (item.text || '').toLowerCase().indexOf(lc) !== -1 ? 1 : 0
        }
      },
      loadThrottle: 300,
      openOnFocus: true,
      maxItems: 1,
      preload: 'focus',
      closeAfterSelect: true,

      load (query, callback) {
        const separator = self.urlValue.includes('?') ? '&' : '?'
        const url = `${self.urlValue}${separator}q=${encodeURIComponent(query)}`

        fetch(url, {
          headers: window.Folio.Api.JSON_HEADERS,
          credentials: 'same-origin'
        })
          .then((r) => r.json())
          .then((json) => {
            const data = (json.data || []).map((item) => ({
              value: String(item.id),
              text: item.label || item.text,
              usage_labels: item.usage_labels || []
            }))

            // Filter out already selected items
            const selectedIds = self.itemsValue.map((i) => String(i.value))
            const filtered = data.filter((d) => !selectedIds.includes(d.value))

            // Accumulate loaded options for duplicate detection.
            // Overlay current record label based on actual selection state —
            // server data doesn't reflect unsaved form changes.
            const currentLabel = self.currentRecordLabelValue
            filtered.forEach((opt) => {
              if (currentLabel) {
                const isSelected = self.itemsValue.some((i) => String(i.value) === opt.value)
                if (isSelected && !opt.usage_labels.includes(currentLabel)) {
                  opt.usage_labels = [...opt.usage_labels, currentLabel]
                } else if (!isSelected) {
                  opt.usage_labels = opt.usage_labels.filter((l) => l !== currentLabel)
                }
              }
              self.loadedOptions[opt.value] = opt
            })

            // Tom Select closes the dropdown when async load returns empty array
            // (no_results renderer only fires for local filtering, not async load).
            // Inject a non-selectable dummy option so the dropdown stays open.
            if (filtered.length === 0) {
              callback([{ value: '__no_results__', text: t('noResults'), disabled: true }])
            } else {
              callback(filtered)
            }
          })
          .catch(() => {
            callback()
          })
      },

      render: {
        option (data, escape) {
          if (data.value === '__no_results__') {
            return `<div class="no-results">${escape(data.text)}</div>`
          }
          if (self.createableValue) {
            return self.renderOptionWithActions(data, escape)
          }
          return `<div>${escape(data.text)}</div>`
        },

        option_create (data, escape) {
          return `<div class="create option">
            ${t('create')} <strong>${escape(data.input)}</strong>&hellip;
          </div>`
        },

        no_results (data) {
          if (data.input) {
            const existingLabels = self.itemsValue.map((i) => i.label)
            if (existingLabels.some((l) => l.toLowerCase().trim() === data.input.toLowerCase().trim())) {
              return `<div class="no-results">${t('alreadyOnList')}</div>`
            }
          }
          return `<div class="no-results">${t('noResults')}</div>`
        },

        loading () {
          return `<div class="spinner"></div>`
        }
      },

      onChange (value) {
        if (!value || value === '__no_results__') return
        self.onItemSelected(value)
        // Reset Tom Select — clear value, keep options so dropdown can reopen
        window.setTimeout(() => {
          if (self.tomSelect) {
            self.tomSelect.clear(true)
            self._needsReload = true
          }
        }, 0)
      }
    }

    if (this.createableValue) {
      config.create = (input, callback) => {
        // Don't add to Tom Select's internal state — we handle it via API
        self.createItem(input)
        callback()
      }

      config.createFilter = (input) => {
        const existingLabels = self.itemsValue.map((i) => i.label)
        return !window.Folio.Input.OrderedMultiselect.isDuplicateLabel(
          input, null, existingLabels, self.loadedOptions
        )
      }
    }

    this.tomSelect = new window.TomSelect(this.selectTarget, config)

    this.tomSelect.on('dropdown_open', () => {
      if (this._needsReload) {
        this._needsReload = false
        this.tomSelect.clearOptions()
        this.tomSelect.load('')
      }
      this.adjustDropdownMaxHeight()
    })

    this.bindDropdownEvents()
  }

  adjustDropdownMaxHeight () {
    if (!this.tomSelect) return
    const content = this.tomSelect.dropdown.querySelector('.ts-dropdown-content')
    if (!content) return

    const footer = document.querySelector('.f-c-form-footer')
    const bottomLimit = footer ? footer.getBoundingClientRect().top : window.innerHeight
    const dropdownTop = this.tomSelect.dropdown.getBoundingClientRect().top
    const available = bottomLimit - dropdownTop - 10

    content.style.maxHeight = Math.max(available, 80) + 'px'
  }

  destroyTomSelect () {
    this.unbindDropdownEvents()
    if (this.tomSelect) {
      this.tomSelect.destroy()
      delete this.tomSelect
    }
  }

  bindDropdownEvents () {
    if (!this.tomSelect) return
    const dropdown = this.tomSelect.dropdown

    this._onDropdownMousedown = (e) => {
      const submitBtn = e.target.closest('.f-input-ordered-multiselect__option-confirm')
      const deleteBtn = e.target.closest('.f-input-ordered-multiselect__option-action--danger')
      const renameBtn = e.target.closest('.f-input-ordered-multiselect__option-action:not(.f-input-ordered-multiselect__option-action--danger):not(.f-input-ordered-multiselect__option-confirm)')

      if (submitBtn || deleteBtn || renameBtn) {
        e.preventDefault()
        e.stopPropagation()
        // Tom Select selects options on 'click' (not mousedown).
        // Block the subsequent click so it doesn't trigger option selection.
        // Store reference so it can be removed if rename is confirmed via Enter (no click follows).
        if (this._pendingClickBlocker) {
          dropdown.removeEventListener('click', this._pendingClickBlocker, true)
        }
        this._pendingClickBlocker = (ce) => { ce.preventDefault(); ce.stopPropagation(); this._pendingClickBlocker = null }
        dropdown.addEventListener('click', this._pendingClickBlocker, { capture: true, once: true })
      }

      if (submitBtn) {
        this.onOptionRenameSubmit({ currentTarget: submitBtn, preventDefault: () => {}, stopPropagation: () => {} })
      } else if (deleteBtn) {
        this.onOptionDeleteClick({ currentTarget: deleteBtn, preventDefault: () => {}, stopPropagation: () => {} })
      } else if (renameBtn) {
        this.onOptionRenameClick({ currentTarget: renameBtn, preventDefault: () => {}, stopPropagation: () => {} })
      }
    }

    this._onDropdownKeydown = (e) => {
      const input = e.target.closest('.f-input-ordered-multiselect__option-edit-input')
      if (!input) return

      if (e.key === 'Enter') {
        e.preventDefault()
        e.stopPropagation()
        this.onOptionRenameSubmit({ currentTarget: input, preventDefault: () => {}, stopPropagation: () => {} })
      } else if (e.key === 'Escape') {
        e.preventDefault()
        e.stopPropagation()
        this.cancelOptionRename(input)
      }
    }

    this._onDropdownInput = (e) => {
      const input = e.target.closest('.f-input-ordered-multiselect__option-edit-input')
      if (!input) return
      this.onOptionRenameInput({ currentTarget: input })
    }

    dropdown.addEventListener('mousedown', this._onDropdownMousedown, true)
    dropdown.addEventListener('keydown', this._onDropdownKeydown, true)
    dropdown.addEventListener('input', this._onDropdownInput, true)
  }

  unbindDropdownEvents () {
    if (!this.tomSelect) return
    const dropdown = this.tomSelect.dropdown
    if (this._onDropdownMousedown) dropdown.removeEventListener('mousedown', this._onDropdownMousedown, true)
    if (this._onDropdownKeydown) dropdown.removeEventListener('keydown', this._onDropdownKeydown, true)
    if (this._onDropdownInput) dropdown.removeEventListener('input', this._onDropdownInput, true)
  }

  renderOptionWithActions (data, escape) {
    // Don't add actions to "create new" options
    if (String(data.value).startsWith('__create__')) {
      return `<div>${escape(data.text)}</div>`
    }

    const t = window.Folio.Input.OrderedMultiselect.t

    const editIcon = window.Folio.Input.OrderedMultiselect.iconHtml('edit_box', { height: 16 })
    const deleteIcon = window.Folio.Input.OrderedMultiselect.iconHtml('delete', { height: 16 })
    const usageHint = window.Folio.Input.OrderedMultiselect.usageHintHtml(data.usage_labels, 'f-input-ordered-multiselect__option-usage', true)

    return `<div class="f-input-ordered-multiselect__option-with-actions" data-option-value="${escape(data.value)}">
      <span class="f-input-ordered-multiselect__option-label">
        ${escape(data.text)}
        ${usageHint}
      </span>
      <span class="f-input-ordered-multiselect__option-actions">
        <button type="button" class="btn btn-none f-input-ordered-multiselect__option-action"
                data-value="${escape(data.value)}"
                data-label="${escape(data.text)}"
                title="${t('rename')}">
          ${editIcon}
        </button>
        <button type="button" class="btn btn-none f-input-ordered-multiselect__option-action f-input-ordered-multiselect__option-action--danger"
                data-value="${escape(data.value)}"
                data-label="${escape(data.text)}"
                title="${t('deleteFromDb')}">
          ${deleteIcon}
        </button>
      </span>
    </div>`
  }

  // --- Item selection ---

  onItemSelected (value) {
    const valueStr = String(value)

    // Skip create values — handled directly in Tom Select create callback
    if (valueStr.startsWith('__create__')) return

    // Check if already selected
    if (this.itemsValue.find((i) => String(i.value) === valueStr)) return

    // Check if was previously removed — restore it
    const removed = this.removedItemsValue.find((i) => String(i.value) === valueStr)
    if (removed) {
      this.removedItemsValue = this.removedItemsValue.filter((i) => String(i.value) !== valueStr)
      const restoredLabels = this._addCurrentLabel(removed.usage_labels)
      this.itemsValue = [...this.itemsValue, { ...removed, usage_labels: restoredLabels }]
      return
    }

    // Find option data from Tom Select
    const option = this.tomSelect.options[value]
    if (!option) return

    const usageLabels = this._addCurrentLabel(option.usage_labels || [])
    this.itemsValue = [...this.itemsValue, {
      id: null,
      label: option.text,
      value: parseInt(valueStr, 10) || valueStr,
      usage_labels: usageLabels
    }]
  }

  // --- CRUD operations ---

  async createItem (label) {
    if (this._busy) return
    const t = window.Folio.Input.OrderedMultiselect.t
    const existingLabels = this.itemsValue.map((i) => i.label)

    if (window.Folio.Input.OrderedMultiselect.isDuplicateLabel(label, null, existingLabels, this.loadedOptions)) {
      window.FolioConsole.Ui.Flash.alert(t('alreadyExists'))
      return
    }

    this._busy = true
    try {
      const response = await window.Folio.Api.apiPost(this.createUrlValue, { label })
      const record = response.data

      const usageLabels = this._addCurrentLabel([])
      this.itemsValue = [...this.itemsValue, {
        id: null,
        label: record.label || record.text,
        value: record.id,
        usage_labels: usageLabels
      }]

      this.resetTomSelect()
    } catch (err) {
      window.FolioConsole.Ui.Flash.alert(err.message || 'Failed to create record')
    } finally {
      this._busy = false
    }
  }

  async renameItem (id, newLabel, isSelectedItem, skipReset) {
    if (this._busy) return false
    const t = window.Folio.Input.OrderedMultiselect.t
    const currentItem = this.itemsValue.find((i) => String(i.value) === String(id))
    const currentLabel = currentItem ? currentItem.label : null
    const existingLabels = this.itemsValue.map((i) => i.label)

    if (window.Folio.Input.OrderedMultiselect.isDuplicateLabel(newLabel, currentLabel, existingLabels, this.loadedOptions)) {
      window.FolioConsole.Ui.Flash.alert(t('alreadyExists'))
      return false
    }

    this._busy = true
    const url = this.updateUrlValue

    try {
      const response = await window.Folio.Api.apiPatch(url, { id, label: newLabel })
      const record = response.data
      const updatedLabel = record.label || record.text

      if (isSelectedItem) {
        this.itemsValue = this.itemsValue.map((item) =>
          String(item.value) === String(id) ? { ...item, label: updatedLabel } : item
        )
      }

      if (!skipReset) this.resetTomSelect()
      return true
    } catch (err) {
      window.FolioConsole.Ui.Flash.alert(err.message || 'Failed to rename record')
      return false
    } finally {
      this._busy = false
    }
  }

  async deleteItem (id) {
    if (this._busy) return false
    const t = window.Folio.Input.OrderedMultiselect.t
    const url = this.deleteUrlValue

    this._busy = true
    try {
      // Check usage first (does not destroy)
      const response = await window.Folio.Api.apiDelete(url, { id })
      const data = response.data

      // Prefer local usage_labels (reflects unsaved form changes) over server-side data
      const localOpt = this.loadedOptions[String(id)]
      const usageLabels = localOpt ? (localOpt.usage_labels || []) : (data.usage_labels || [])
      const usageCount = usageLabels.length

      let message
      if (usageCount > 0 && usageLabels.length > 0) {
        const list = usageLabels.map((l) => `- ${l}`).join('\n')
        message = t('deleteWarningWithLabels')
          .replace('%{count}', usageCount)
          .replace('%{list}', list)
      } else if (usageCount > 0) {
        message = t('deleteWarning').replace('%{count}', usageCount)
      } else {
        message = t('deleteFromDbConfirm')
      }

      if (!window.confirm(message)) return false

      // Confirmed — destroy
      await window.Folio.Api.apiDelete(url, { id, confirmed: 'true' })

      // Remove from items if selected
      this.itemsValue = this.itemsValue.filter((i) => String(i.value) !== String(id))
      // Remove from removedItems too
      this.removedItemsValue = this.removedItemsValue.filter((i) => String(i.value) !== String(id))

      return true
    } catch (err) {
      window.FolioConsole.Ui.Flash.alert(err.message || 'Failed to delete record')
      return false
    } finally {
      this._busy = false
    }
  }

  // --- Dropdown option actions ---

  onOptionRenameClick (e) {
    e.preventDefault()
    e.stopPropagation()

    const btn = e.currentTarget
    const value = btn.dataset.value
    const label = btn.dataset.label
    const optionEl = btn.closest('.f-input-ordered-multiselect__option-with-actions')

    if (!optionEl) return

    // Prevent Tom Select from closing the dropdown while editing
    this.preventDropdownClose()

    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const t = window.Folio.Input.OrderedMultiselect.t
    const confirmIcon = window.Folio.Input.OrderedMultiselect.iconHtml('checkbox_marked', { height: 16 })

    // Get usage_labels from Tom Select option data
    const optionData = this.tomSelect ? this.tomSelect.options[value] : null
    const usageLabels = optionData ? optionData.usage_labels : []
    const usageHint = window.Folio.Input.OrderedMultiselect.usageHintHtml(usageLabels, 'f-input-ordered-multiselect__option-usage', true)

    optionEl.innerHTML = `
      <span class="f-input-ordered-multiselect__option-label">
        <input type="text" class="f-input-ordered-multiselect__option-edit-input"
               value="${escape(label)}"
               data-value="${escape(value)}"
               data-original-label="${escape(label)}">
        ${usageHint}
      </span>
      <span class="f-input-ordered-multiselect__option-actions">
        <span class="f-input-ordered-multiselect__option-action text-success f-input-ordered-multiselect__option-confirm"
              data-value="${escape(value)}"
              data-original-label="${escape(label)}">
          ${confirmIcon}
        </span>
      </span>
    `

    const input = optionEl.querySelector('input')
    input.focus()
    input.select()
  }

  onOptionRenameInput (e) {
    const input = e.currentTarget
    const originalLabel = input.dataset.originalLabel
    const existingLabels = this.itemsValue.map((i) => i.label)
    const t = window.Folio.Input.OrderedMultiselect.t

    const isDuplicate = window.Folio.Input.OrderedMultiselect.isDuplicateLabel(
      input.value, originalLabel, existingLabels, this.loadedOptions
    )

    input.classList.toggle('is-invalid', isDuplicate)

    // Swap usage hint with error message
    const labelEl = input.closest('.f-input-ordered-multiselect__option-label') ||
                    input.closest('.f-input-ordered-multiselect__option-with-actions')
    if (!labelEl) return
    const hintEl = labelEl.querySelector('.f-input-ordered-multiselect__option-usage')
    if (hintEl) {
      if (isDuplicate) {
        if (!hintEl.dataset.originalText) hintEl.dataset.originalText = hintEl.textContent
        hintEl.textContent = t('alreadyExists')
        hintEl.classList.add('text-danger')
      } else {
        if (hintEl.dataset.originalText) hintEl.textContent = hintEl.dataset.originalText
        hintEl.classList.remove('text-danger')
      }
    }
  }

  async onOptionRenameSubmit (e) {
    e.preventDefault()
    e.stopPropagation()

    const input = e.currentTarget.tagName === 'INPUT'
      ? e.currentTarget
      : e.currentTarget.closest('.f-input-ordered-multiselect__option-with-actions').querySelector('.f-input-ordered-multiselect__option-edit-input')

    const value = input.dataset.value
    const newLabel = input.value.trim()
    const originalLabel = input.dataset.originalLabel

    if (!newLabel || newLabel === originalLabel) {
      this.cancelOptionRename(input)
      return
    }
    if (input.classList.contains('is-invalid')) return

    const isSelected = this.itemsValue.some((i) => String(i.value) === String(value))
    const success = await this.renameItem(value, newLabel, isSelected, true)

    if (success) {
      // Update Tom Select's internal option data so selection uses the new label
      if (this.tomSelect && this.tomSelect.options[value]) {
        this.tomSelect.options[value].text = newLabel
      }
      // Update loadedOptions for duplicate checking
      if (this.loadedOptions[String(value)]) {
        this.loadedOptions[String(value)].text = newLabel
      }

      // Update option label in DOM directly — no need to reload
      const optionEl = e.currentTarget.closest('.f-input-ordered-multiselect__option-with-actions') ||
                        e.currentTarget.closest('[data-option-value]')
      if (optionEl) {
        this.restoreOptionHtml(optionEl, value, newLabel)

        // Flash animation
        const parentOption = optionEl.closest('.option')
        if (parentOption) {
          parentOption.classList.add('f-input-ordered-multiselect__item--flash')
          window.setTimeout(() => parentOption.classList.remove('f-input-ordered-multiselect__item--flash'), 600)
        }
      }
      this.restoreDropdownClose(true)
      this.refocusTomSelect()
    } else {
      this.restoreDropdownClose()
    }
  }

  cancelOptionRename (input) {
    if (!input) return
    const value = input.dataset.value
    const originalLabel = input.dataset.originalLabel
    const optionEl = input.closest('.f-input-ordered-multiselect__option-with-actions')
    if (optionEl) {
      this.restoreOptionHtml(optionEl, value, originalLabel)
    }
    // Restore close so the dropdown can be dismissed normally (e.g. second Escape)
    this.restoreDropdownClose(true)
    this.refocusTomSelect()
  }

  refocusTomSelect () {
    if (!this.tomSelect) return
    // Set isFocused synchronously so Tom Select knows it's focused
    // before any click events arrive. Then focus the input asynchronously
    // with ignoreFocus to prevent refreshOptions from re-rendering the DOM.
    this.tomSelect.isFocused = true
    this.tomSelect.refreshState()
    this.tomSelect.ignoreFocus = true
    this.tomSelect.control_input.focus()
    window.setTimeout(() => {
      if (!this.tomSelect) return
      this.tomSelect.ignoreFocus = false
    }, 0)
  }

  restoreOptionHtml (optionEl, value, label) {
    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const t = window.Folio.Input.OrderedMultiselect.t
    const editIcon = window.Folio.Input.OrderedMultiselect.iconHtml('edit_box', { height: 16 })
    const deleteIcon = window.Folio.Input.OrderedMultiselect.iconHtml('delete', { height: 16 })

    const optData = this.tomSelect ? this.tomSelect.options[value] : null
    const usageLabels = optData ? optData.usage_labels : []
    const usageHint = window.Folio.Input.OrderedMultiselect.usageHintHtml(usageLabels, 'f-input-ordered-multiselect__option-usage', true)

    optionEl.innerHTML = `
      <span class="f-input-ordered-multiselect__option-label">
        ${escape(label)}
        ${usageHint}
      </span>
      <span class="f-input-ordered-multiselect__option-actions">
        <button type="button" class="btn btn-none f-input-ordered-multiselect__option-action"
                data-value="${escape(value)}"
                data-label="${escape(label)}"
                title="${t('rename')}">
          ${editIcon}
        </button>
        <button type="button" class="btn btn-none f-input-ordered-multiselect__option-action f-input-ordered-multiselect__option-action--danger"
                data-value="${escape(value)}"
                data-label="${escape(label)}"
                title="${t('deleteFromDb')}">
          ${deleteIcon}
        </button>
      </span>`
  }

  resetTomSelect () {
    if (!this.tomSelect) return
    this.tomSelect.clear(true)
    // Use blur() to properly reset all internal state through Tom Select's normal flow
    this.tomSelect.blur()
    this._needsReload = true
  }

  preventDropdownClose () {
    if (!this.tomSelect) return
    if (!this._originalClose) {
      this._originalClose = this.tomSelect.close.bind(this.tomSelect)
    }
    this.tomSelect.close = () => {}

    // Remove previous outside-click listener if still attached (prevents orphaned listeners)
    if (this._onDocumentMousedown) {
      document.removeEventListener('mousedown', this._onDocumentMousedown, true)
    }

    // Listen for clicks outside the dropdown to cancel editing and close
    this._onDocumentMousedown = (e) => {
      if (!this.tomSelect) return
      const dropdown = this.tomSelect.dropdown
      if (dropdown && !dropdown.contains(e.target)) {
        // Cancel any active rename before closing
        const activeInput = dropdown.querySelector('.f-input-ordered-multiselect__option-edit-input')
        if (activeInput) this.cancelOptionRename(activeInput)
        this.restoreDropdownClose()
      }
    }
    window.setTimeout(() => {
      document.addEventListener('mousedown', this._onDocumentMousedown, true)
    }, 0)
  }

  restoreDropdownClose (keepOpen) {
    // Remove outside-click listener
    if (this._onDocumentMousedown) {
      document.removeEventListener('mousedown', this._onDocumentMousedown, true)
      this._onDocumentMousedown = null
    }

    // Remove any pending click blocker (e.g. rename started via mousedown but confirmed via Enter)
    if (this._pendingClickBlocker && this.tomSelect) {
      this.tomSelect.dropdown.removeEventListener('click', this._pendingClickBlocker, true)
      this._pendingClickBlocker = null
    }

    if (!this.tomSelect || !this._originalClose) return
    this.tomSelect.close = this._originalClose
    this._originalClose = null

    // Always clear value silently to reset Tom Select's internal state
    this.tomSelect.clear(true)

    if (keepOpen) return

    this._needsReload = true
    this.tomSelect.close()
    this.tomSelect.blur()
  }

  async onOptionDeleteClick (e) {
    e.preventDefault()
    e.stopPropagation()

    const btn = e.currentTarget
    const value = btn.dataset.value

    // Keep dropdown open during confirm dialogs (they steal focus → Tom Select would close)
    this.preventDropdownClose()

    const success = await this.deleteItem(value)

    if (success) {
      const t = window.Folio.Input.OrderedMultiselect.t
      window.FolioConsole.Ui.Flash.success(t('deleted'))

      // Animate option removal from dropdown
      const optionEl = btn.closest('.option')
      if (optionEl) {
        optionEl.style.transition = 'opacity 0.3s, max-height 0.3s'
        optionEl.style.overflow = 'hidden'
        optionEl.style.maxHeight = optionEl.offsetHeight + 'px'
        optionEl.style.opacity = '0.5'

        window.setTimeout(() => {
          optionEl.style.opacity = '0'
          optionEl.style.maxHeight = '0'
          optionEl.style.padding = '0'
          optionEl.style.margin = '0'
        }, 100)

        window.setTimeout(() => {
          optionEl.remove()
        }, 400)
      }

      // Check if any real options remain after this deletion
      const allOptions = this.tomSelect.dropdown.querySelectorAll('.option')
      const realRemaining = Array.from(allOptions).filter((el) => el !== optionEl)
      if (realRemaining.length === 0) {
        // No options left — close dropdown completely
        this.restoreDropdownClose()
      } else {
        // More options remain — keep dropdown open for further browsing/deleting
        this.restoreDropdownClose(true)
      }
    } else {
      this.restoreDropdownClose()
    }
  }

  // --- Selected items list ---

  itemsValueChanged () {
    if (this._skipRender) return
    this.renderList()
    this.syncHiddenInputs()
    this.dispatchChangeEvent()
  }

  renderList () {
    if (!this.hasListTarget) return

    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const t = window.Folio.Input.OrderedMultiselect.t
    const dragIcon = window.Folio.Input.OrderedMultiselect.iconHtml('drag', { height: 24 })
    const sortableHandle = this.sortableValue
      ? `<span class="f-input-ordered-multiselect__item-handle">${dragIcon}</span>`
      : ''

    const editIcon = window.Folio.Input.OrderedMultiselect.iconHtml('edit_box', { height: 16 })
    const closeIcon = window.Folio.Input.OrderedMultiselect.iconHtml('close', { height: 16 })

    const createableActions = this.createableValue
      ? (item) => `
          <button type="button" class="btn btn-none f-input-ordered-multiselect__item-action"
                  data-action="click->f-input-ordered-multiselect#onItemRenameClick"
                  data-value="${item.value}"
                  data-label="${escape(item.label)}"
                  title="${t('rename')}">
            ${editIcon}
          </button>`
      : () => ''

    const usageHint = window.Folio.Input.OrderedMultiselect.usageHintHtml

    this.listTarget.innerHTML = this.itemsValue.map((item) => `
      <div class="f-input-ordered-multiselect__item" data-value="${item.value}">
        ${sortableHandle}
        <span class="f-input-ordered-multiselect__item-label">
          ${escape(item.label)}
          ${usageHint(item.usage_labels, 'f-input-ordered-multiselect__item-usage')}
        </span>
        <span class="f-input-ordered-multiselect__item-actions">
          ${createableActions(item)}
          <button type="button" class="btn btn-none f-input-ordered-multiselect__item-action f-input-ordered-multiselect__item-action--danger"
                  data-action="click->f-input-ordered-multiselect#onItemRemoveClick"
                  data-value="${item.value}"
                  title="${t('remove')}">
            ${closeIcon}
          </button>
        </span>
      </div>
    `).join('')

    // Reinitialize sortable after re-render
    if (this.sortableValue && this._sortableInitialized) {
      this.refreshSortable()
    }
  }

  syncHiddenInputs () {
    if (!this.hasHiddenContainerTarget) return

    const paramBase = this.paramBaseValue
    const foreignKey = this.foreignKeyValue
    let html = ''
    let index = 0

    // Selected items
    this.itemsValue.forEach((item) => {
      if (item.id) {
        html += `<input type="hidden" name="${paramBase}[${index}][id]" value="${item.id}">`
      }
      html += `<input type="hidden" name="${paramBase}[${index}][${foreignKey}]" value="${item.value}">`
      html += `<input type="hidden" name="${paramBase}[${index}][position]" value="${index + 1}">`
      index++
    })

    // Removed items (mark for destruction)
    this.removedItemsValue.forEach((item) => {
      if (item.id) {
        html += `<input type="hidden" name="${paramBase}[${index}][id]" value="${item.id}">`
        html += `<input type="hidden" name="${paramBase}[${index}][_destroy]" value="1">`
        index++
      }
    })

    this.hiddenContainerTarget.innerHTML = html
  }

  dispatchChangeEvent () {
    this.element.dispatchEvent(new Event('change', { bubbles: true }))
  }

  // --- Item list actions ---

  onItemRemoveClick (e) {
    e.preventDefault()
    const value = e.currentTarget.dataset.value
    const item = this.itemsValue.find((i) => String(i.value) === String(value))

    if (!item) return

    this.itemsValue = this.itemsValue.filter((i) => String(i.value) !== String(value))

    // Track for _destroy if it was a persisted record
    if (item.id) {
      const updatedLabels = this._removeCurrentLabel(item.usage_labels)
      this.removedItemsValue = [...this.removedItemsValue, { ...item, usage_labels: updatedLabels }]
    }

    // Update loadedOptions so dropdown shows updated usage_labels
    const valStr = String(value)
    if (this.loadedOptions[valStr]) {
      this.loadedOptions[valStr].usage_labels = this._removeCurrentLabel(this.loadedOptions[valStr].usage_labels)
    }

    // Mark dropdown for reload so the removed item appears again
    this._needsReload = true
  }

  onItemRenameClick (e) {
    e.preventDefault()

    const btn = e.currentTarget
    const value = btn.dataset.value
    const label = btn.dataset.label
    const itemEl = btn.closest('.f-input-ordered-multiselect__item')

    if (!itemEl) return

    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const t = window.Folio.Input.OrderedMultiselect.t
    const labelEl = itemEl.querySelector('.f-input-ordered-multiselect__item-label')
    const actionsEl = itemEl.querySelector('.f-input-ordered-multiselect__item-actions')
    const confirmIcon = window.Folio.Input.OrderedMultiselect.iconHtml('checkbox_marked', { height: 16 })
    const item = this.itemsValue.find((i) => String(i.value) === String(value))
    const usageHintStr = window.Folio.Input.OrderedMultiselect.usageHintHtml(item && item.usage_labels, 'f-input-ordered-multiselect__item-usage')

    labelEl.innerHTML = `
      <div class="f-input-ordered-multiselect__field-wrap">
        <input type="text" class="f-input-ordered-multiselect__item-rename-input"
               value="${escape(label)}"
               data-value="${escape(value)}"
               data-original-label="${escape(label)}">
      </div>
      ${usageHintStr}
    `

    // Replace action buttons with green confirm button
    actionsEl.innerHTML = `
      <span class="f-input-ordered-multiselect__item-action text-success f-input-ordered-multiselect__item-confirm" tabindex="0">
        ${confirmIcon}
      </span>
    `

    const input = labelEl.querySelector('input')
    const confirmBtn = actionsEl.querySelector('.f-input-ordered-multiselect__item-confirm')

    // Manual event listeners
    input.addEventListener('input', (e) => this.onItemRenameInputCheck(e))
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        e.stopPropagation()
        this.onItemRenameSubmit(e)
      } else if (e.key === 'Escape') {
        this.onItemRenameCancel(e)
      }
    })
    input.addEventListener('blur', (e) => {
      // Don't cancel if clicking the confirm button
      if (e.relatedTarget && e.relatedTarget.closest('.f-input-ordered-multiselect__item-confirm')) return
      this.onItemRenameCancel(e)
    })

    confirmBtn.addEventListener('mousedown', (e) => {
      e.preventDefault() // prevent blur on input
    })
    confirmBtn.addEventListener('click', (e) => {
      e.preventDefault()
      this.onItemRenameSubmit({ target: input, preventDefault: () => {}, stopPropagation: () => {} })
    })

    input.focus()
    input.select()
  }

  onItemRenameInputCheck (e) {
    const input = e.target || e.currentTarget
    const originalLabel = input.dataset.originalLabel
    const existingLabels = this.itemsValue.map((i) => i.label)
    const t = window.Folio.Input.OrderedMultiselect.t

    const isDuplicate = window.Folio.Input.OrderedMultiselect.isDuplicateLabel(
      input.value, originalLabel, existingLabels, this.loadedOptions
    )

    input.classList.toggle('is-invalid', isDuplicate)

    // Swap usage hint with error message
    const itemLabel = input.closest('.f-input-ordered-multiselect__item-label')
    if (!itemLabel) return
    const hintEl = itemLabel.querySelector('.f-input-ordered-multiselect__item-usage')
    if (hintEl) {
      if (isDuplicate) {
        if (!hintEl.dataset.originalText) hintEl.dataset.originalText = hintEl.textContent
        hintEl.textContent = t('alreadyExists')
        hintEl.classList.add('text-danger')
      } else {
        if (hintEl.dataset.originalText) hintEl.textContent = hintEl.dataset.originalText
        hintEl.classList.remove('text-danger')
      }
    }
  }

  async onItemRenameSubmit (e) {
    e.preventDefault()
    e.stopPropagation()

    const input = e.target.closest('.f-input-ordered-multiselect__item-rename-input') || e.currentTarget
    const value = input.dataset.value
    const newLabel = input.value.trim()
    const originalLabel = input.dataset.originalLabel

    if (!newLabel || newLabel === originalLabel) {
      this.renderList()
      return
    }

    // Check for duplicates at submit time
    const existingLabels = this.itemsValue.map((i) => i.label)
    if (window.Folio.Input.OrderedMultiselect.isDuplicateLabel(newLabel, originalLabel, existingLabels, this.loadedOptions)) {
      input.classList.add('is-invalid')
      return
    }

    const itemEl = input.closest('.f-input-ordered-multiselect__item')
    const success = await this.renameItem(value, newLabel, true)
    if (success) {
      // Re-render then flash the renamed item
      this.renderList()
      if (itemEl) {
        const newItemEl = this.listTarget.querySelector(`[data-value="${value}"]`)
        if (newItemEl) {
          newItemEl.classList.add('f-input-ordered-multiselect__item--flash')
          window.setTimeout(() => newItemEl.classList.remove('f-input-ordered-multiselect__item--flash'), 600)
        }
      }
    } else {
      this.renderList()
    }
  }

  onItemRenameCancel (e) {
    if (e.type === 'blur' && e.relatedTarget && e.relatedTarget.closest('.f-input-ordered-multiselect__item')) {
      return
    }
    this.renderList()
  }

  // --- Sortable ---

  initSortable () {
    window.Folio.RemoteScripts.run('html5sortable', () => {
      if (!this.hasListTarget) return

      window.sortable(this.listTarget, {
        items: '.f-input-ordered-multiselect__item',
        handle: '.f-input-ordered-multiselect__item-handle',
        placeholder: '<div class="f-input-ordered-multiselect__sortable-placeholder"></div>'
      })

      this._onSortUpdate = () => this.onSortUpdate()
      this.listTarget.addEventListener('sortupdate', this._onSortUpdate)
      this._sortableInitialized = true
    })
  }

  refreshSortable () {
    if (window.sortable && this.hasListTarget) {
      window.sortable(this.listTarget)
    }
  }

  destroySortable () {
    if (this._sortableInitialized && window.sortable && this.hasListTarget) {
      this.listTarget.removeEventListener('sortupdate', this._onSortUpdate)
      window.sortable(this.listTarget, 'destroy')
      this._sortableInitialized = false
    }
  }

  onSortUpdate () {
    const itemEls = this.listTarget.querySelectorAll('.f-input-ordered-multiselect__item')
    const newOrder = Array.from(itemEls).map((el) => el.dataset.value)

    const reordered = newOrder.map((val) =>
      this.itemsValue.find((item) => String(item.value) === String(val))
    ).filter(Boolean)

    // Update without triggering re-render (DOM is already in correct order)
    this._skipRender = true
    try {
      this.itemsValue = reordered
    } finally {
      this._skipRender = false
    }
    this.syncHiddenInputs()
    this.dispatchChangeEvent()
  }

  // --- Usage labels helpers ---

  _addCurrentLabel (labels) {
    const current = this.currentRecordLabelValue
    if (!current) return labels || []
    const arr = labels ? [...labels] : []
    if (!arr.includes(current)) arr.push(current)
    return arr
  }

  _removeCurrentLabel (labels) {
    const current = this.currentRecordLabelValue
    if (!current || !labels) return labels || []
    return labels.filter((l) => l !== current)
  }
})

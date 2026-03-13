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
    if (this.sortableValue) this.initSortable()
    this.renderList()
    this.syncHiddenInputs()
  }

  disconnect () {
    if (this._blurCancelTimer) { clearTimeout(this._blurCancelTimer); this._blurCancelTimer = null }
    if (this._onDocumentMousedown) { document.removeEventListener('mousedown', this._onDocumentMousedown, true); this._onDocumentMousedown = null }
    this.destroyTomSelect()
    this.destroySortable()
  }

  // --- Tom Select setup ---

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
        const url = `${self.urlValue}${self.urlValue.includes('?') ? '&' : '?'}q=${encodeURIComponent(query)}`
        fetch(url, { headers: window.Folio.Api.JSON_HEADERS, credentials: 'same-origin' })
          .then((r) => r.json())
          .then((json) => {
            const selectedIds = self.itemsValue.map((i) => String(i.value))
            const filtered = (json.data || [])
              .map((item) => ({ value: String(item.id), text: item.label || item.text, usage_labels: item.usage_labels || [] }))
              .filter((d) => !selectedIds.includes(d.value))

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
          .catch(() => callback())
      },
      render: {
        option (data, escape) {
          if (data.value === '__no_results__') return `<div class="no-results">${escape(data.text)}</div>`
          return self.createableValue ? self.renderOptionWithActions(data, escape) : `<div>${escape(data.text)}</div>`
        },
        option_create (data, escape) {
          return `<div class="create option">${t('create')} <strong>${escape(data.input)}</strong>&hellip;</div>`
        },
        no_results (data) {
          if (data.input && self.itemsValue.some((i) => i.label.toLowerCase().trim() === data.input.toLowerCase().trim())) {
            return `<div class="no-results">${t('alreadyOnList')}</div>`
          }
          return `<div class="no-results">${t('noResults')}</div>`
        },
        loading () { return `<div class="spinner"></div>` }
      },
      onChange (value) {
        if (!value || value === '__no_results__') return
        self.onItemSelected(value)
        window.setTimeout(() => { if (self.tomSelect) { self.tomSelect.clear(true); self._needsReload = true } }, 0)
      }
    }
    if (this.createableValue) {
      config.create = (input, callback) => { self.createItem(input); callback() }
      config.createFilter = (input) => !window.Folio.Input.OrderedMultiselect.isDuplicateLabel(input, null, self.itemsValue.map((i) => i.label), self.loadedOptions)
    }
    this.tomSelect = new window.TomSelect(this.selectTarget, config)
    this.tomSelect.on('dropdown_open', () => {
      if (this._needsReload) { this._needsReload = false; this.tomSelect.clearOptions(); this.tomSelect.load('') }
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
    content.style.maxHeight = Math.max(bottomLimit - this.tomSelect.dropdown.getBoundingClientRect().top - 10, 80) + 'px'
  }

  destroyTomSelect () {
    this.unbindDropdownEvents()
    if (this.tomSelect) { this.tomSelect.destroy(); delete this.tomSelect }
  }

  bindDropdownEvents () {
    if (!this.tomSelect) return
    const dropdown = this.tomSelect.dropdown
    const noop = () => {}
    const fakeEvent = (target) => ({ currentTarget: target, preventDefault: noop, stopPropagation: noop })
    this._onDropdownMousedown = (e) => {
      // Let clicks inside the rename input through for cursor positioning,
      // but stop Tom Select from treating it as option selection.
      // Block both mousedown propagation AND the subsequent click event —
      // Tom Select selects options on click, not mousedown.
      if (e.target.closest('.f-input-ordered-multiselect__option-edit-input')) {
        // stopImmediatePropagation prevents Tom Select's own capture-phase handlers
        // from calling preventDefault (which would block cursor positioning).
        // We do NOT call preventDefault ourselves — the browser must handle cursor placement.
        e.stopImmediatePropagation()
        // Block the subsequent click so Tom Select doesn't select the option
        if (this._pendingClickBlocker) dropdown.removeEventListener('click', this._pendingClickBlocker, true)
        this._pendingClickBlocker = (ce) => { ce.stopImmediatePropagation(); this._pendingClickBlocker = null }
        dropdown.addEventListener('click', this._pendingClickBlocker, { capture: true, once: true })
        return
      }
      const submitBtn = e.target.closest('.f-input-ordered-multiselect__option-confirm')
      const deleteBtn = e.target.closest('.f-input-ordered-multiselect__option-action--danger')
      const renameBtn = e.target.closest('.f-input-ordered-multiselect__option-action:not(.f-input-ordered-multiselect__option-action--danger):not(.f-input-ordered-multiselect__option-confirm)')
      if (submitBtn || deleteBtn || renameBtn) {
        e.preventDefault()
        e.stopPropagation()
        if (this._pendingClickBlocker) dropdown.removeEventListener('click', this._pendingClickBlocker, true)
        this._pendingClickBlocker = (ce) => { ce.preventDefault(); ce.stopPropagation(); this._pendingClickBlocker = null }
        dropdown.addEventListener('click', this._pendingClickBlocker, { capture: true, once: true })
      }
      if (submitBtn) this.onOptionRenameSubmit(fakeEvent(submitBtn))
      else if (deleteBtn) this.onOptionDeleteClick(fakeEvent(deleteBtn))
      else if (renameBtn) this.onOptionRenameClick(fakeEvent(renameBtn))
    }
    this._onDropdownKeydown = (e) => {
      const input = e.target.closest('.f-input-ordered-multiselect__option-edit-input')
      if (!input) return
      if (e.key === 'Enter') { e.preventDefault(); e.stopPropagation(); this.onOptionRenameSubmit(fakeEvent(input)) }
      else if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); this.cancelOptionRename(input) }
    }
    this._onDropdownInput = (e) => {
      const input = e.target.closest('.f-input-ordered-multiselect__option-edit-input')
      if (input) this.onOptionRenameInput({ currentTarget: input })
    }
    dropdown.addEventListener('mousedown', this._onDropdownMousedown, true)
    dropdown.addEventListener('keydown', this._onDropdownKeydown, true)
    dropdown.addEventListener('input', this._onDropdownInput, true)
  }

  unbindDropdownEvents () {
    if (!this.tomSelect) return
    const dd = this.tomSelect.dropdown
    if (this._onDropdownMousedown) dd.removeEventListener('mousedown', this._onDropdownMousedown, true)
    if (this._onDropdownKeydown) dd.removeEventListener('keydown', this._onDropdownKeydown, true)
    if (this._onDropdownInput) dd.removeEventListener('input', this._onDropdownInput, true)
  }

  // --- Shared option HTML (used by renderOptionWithActions + restoreOptionHtml) ---

  optionActionHtml (value, label, usageLabels) {
    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const t = window.Folio.Input.OrderedMultiselect.t
    const editIcon = window.Folio.Input.OrderedMultiselect.iconHtml('edit_box', { height: 16 })
    const deleteIcon = window.Folio.Input.OrderedMultiselect.iconHtml('delete', { height: 16 })
    const usageHint = window.Folio.Input.OrderedMultiselect.usageHintHtml(usageLabels, 'f-input-ordered-multiselect__option-usage', true)
    return `<span class="f-input-ordered-multiselect__option-label">${escape(label)}${usageHint}</span>
      <span class="f-input-ordered-multiselect__option-actions">
        <button type="button" class="btn btn-none f-input-ordered-multiselect__option-action" data-value="${escape(value)}" data-label="${escape(label)}" title="${t('rename')}">${editIcon}</button>
        <button type="button" class="btn btn-none f-input-ordered-multiselect__option-action f-input-ordered-multiselect__option-action--danger" data-value="${escape(value)}" data-label="${escape(label)}" title="${t('deleteFromDb')}">${deleteIcon}</button>
      </span>`
  }

  renderOptionWithActions (data, escape) {
    if (String(data.value).startsWith('__create__')) return `<div>${escape(data.text)}</div>`
    return `<div class="f-input-ordered-multiselect__option-with-actions" data-option-value="${escape(data.value)}">${this.optionActionHtml(data.value, data.text, data.usage_labels)}</div>`
  }

  restoreOptionHtml (optionEl, value, label) {
    const optData = this.tomSelect ? this.tomSelect.options[value] : null
    optionEl.innerHTML = this.optionActionHtml(value, label, optData ? optData.usage_labels : [])
  }

  // --- Item selection & CRUD ---

  onItemSelected (value) {
    const valueStr = String(value)
    if (valueStr.startsWith('__create__')) return
    if (this.itemsValue.find((i) => String(i.value) === valueStr)) return
    const removed = this.removedItemsValue.find((i) => String(i.value) === valueStr)
    if (removed) {
      this.removedItemsValue = this.removedItemsValue.filter((i) => String(i.value) !== valueStr)
      this.itemsValue = [...this.itemsValue, { ...removed, usage_labels: this._addCurrentLabel(removed.usage_labels) }]
      return
    }
    const option = this.tomSelect.options[value]
    if (!option) return
    this.itemsValue = [...this.itemsValue, {
      id: null, label: option.text, value: parseInt(valueStr, 10) || valueStr,
      usage_labels: this._addCurrentLabel(option.usage_labels || [])
    }]
  }

  async createItem (label) {
    if (this._busy) return
    const t = window.Folio.Input.OrderedMultiselect.t
    if (window.Folio.Input.OrderedMultiselect.isDuplicateLabel(label, null, this.itemsValue.map((i) => i.label), this.loadedOptions)) {
      window.FolioConsole.Ui.Flash.alert(t('alreadyExists'))
      return
    }
    this._busy = true
    try {
      const record = (await window.Folio.Api.apiPost(this.createUrlValue, { label })).data
      this.itemsValue = [...this.itemsValue, {
        id: null, label: record.label || record.text, value: record.id,
        usage_labels: this._addCurrentLabel([])
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
    if (window.Folio.Input.OrderedMultiselect.isDuplicateLabel(newLabel, currentItem ? currentItem.label : null, this.itemsValue.map((i) => i.label), this.loadedOptions)) {
      window.FolioConsole.Ui.Flash.alert(t('alreadyExists'))
      return false
    }
    this._busy = true
    try {
      const updatedLabel = ((await window.Folio.Api.apiPatch(this.updateUrlValue, { id, label: newLabel })).data).label || newLabel
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
    this._busy = true
    try {
      const data = (await window.Folio.Api.apiDelete(this.deleteUrlValue, { id })).data
      // Prefer local usage_labels (reflects unsaved form changes) over server-side data
      const localOpt = this.loadedOptions[String(id)]
      const usageLabels = localOpt ? (localOpt.usage_labels || []) : (data.usage_labels || [])
      const usageCount = usageLabels.length
      let message
      if (usageCount > 0 && usageLabels.length > 0) {
        message = t('deleteWarningWithLabels').replace('%{count}', usageCount).replace('%{list}', usageLabels.map((l) => `- ${l}`).join('\n'))
      } else if (usageCount > 0) {
        message = t('deleteWarning').replace('%{count}', usageCount)
      } else {
        message = t('deleteFromDbConfirm')
      }
      if (!window.confirm(message)) return false
      await window.Folio.Api.apiDelete(this.deleteUrlValue, { id, confirmed: 'true' })
      this.itemsValue = this.itemsValue.filter((i) => String(i.value) !== String(id))
      this.removedItemsValue = this.removedItemsValue.filter((i) => String(i.value) !== String(id))
      return true
    } catch (err) {
      window.FolioConsole.Ui.Flash.alert(err.message || 'Failed to delete record')
      return false
    } finally {
      this._busy = false
    }
  }

  // --- Dropdown option inline rename & delete ---

  onOptionRenameClick (e) {
    e.preventDefault()
    e.stopPropagation()
    // Cancel any active rename in the dropdown before starting a new one —
    // just restore HTML, don't touch close/focus (we're staying in edit mode)
    if (this.tomSelect) {
      const activeInput = this.tomSelect.dropdown.querySelector('.f-input-ordered-multiselect__option-edit-input')
      if (activeInput) {
        const activeEl = activeInput.closest('.f-input-ordered-multiselect__option-with-actions')
        if (activeEl) this.restoreOptionHtml(activeEl, activeInput.dataset.value, activeInput.dataset.originalLabel)
      }
    }
    const btn = e.currentTarget
    const value = btn.dataset.value
    const label = btn.dataset.label
    const optionEl = btn.closest('.f-input-ordered-multiselect__option-with-actions')
    if (!optionEl) return
    this.preventDropdownClose()
    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const confirmIcon = window.Folio.Input.OrderedMultiselect.iconHtml('checkbox_marked', { height: 16 })
    const optionData = this.tomSelect ? this.tomSelect.options[value] : null
    const usageHint = window.Folio.Input.OrderedMultiselect.usageHintHtml(optionData ? optionData.usage_labels : [], 'f-input-ordered-multiselect__option-usage', true)
    optionEl.innerHTML = `<span class="f-input-ordered-multiselect__option-label">
        <input type="text" class="f-input-ordered-multiselect__option-edit-input" value="${escape(label)}" data-value="${escape(value)}" data-original-label="${escape(label)}">
        ${usageHint}
      </span>
      <span class="f-input-ordered-multiselect__option-actions">
        <span class="f-input-ordered-multiselect__option-action text-success f-input-ordered-multiselect__option-confirm" data-value="${escape(value)}" data-original-label="${escape(label)}">${confirmIcon}</span>
      </span>`
    const input = optionEl.querySelector('input')
    input.focus()
    input.select()
  }

  onOptionRenameInput (e) {
    this.checkRenameDuplicate(e.currentTarget, '.f-input-ordered-multiselect__option-label, .f-input-ordered-multiselect__option-with-actions', '.f-input-ordered-multiselect__option-usage')
  }

  async onOptionRenameSubmit (e) {
    e.preventDefault()
    e.stopPropagation()
    const input = e.currentTarget.tagName === 'INPUT'
      ? e.currentTarget
      : e.currentTarget.closest('.f-input-ordered-multiselect__option-with-actions').querySelector('.f-input-ordered-multiselect__option-edit-input')
    const value = input.dataset.value
    const newLabel = input.value.trim()
    if (!newLabel || newLabel === input.dataset.originalLabel) { this.cancelOptionRename(input); return }
    if (input.classList.contains('is-invalid')) return
    const success = await this.renameItem(value, newLabel, this.itemsValue.some((i) => String(i.value) === String(value)), true)
    if (success) {
      if (this.tomSelect && this.tomSelect.options[value]) this.tomSelect.options[value].text = newLabel
      if (this.loadedOptions[String(value)]) this.loadedOptions[String(value)].text = newLabel
      const optionEl = e.currentTarget.closest('.f-input-ordered-multiselect__option-with-actions') || e.currentTarget.closest('[data-option-value]')
      if (optionEl) {
        this.restoreOptionHtml(optionEl, value, newLabel)
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
    const optionEl = input.closest('.f-input-ordered-multiselect__option-with-actions')
    if (optionEl) this.restoreOptionHtml(optionEl, input.dataset.value, input.dataset.originalLabel)
    this.restoreDropdownClose(true)
    this.refocusTomSelect()
  }

  refocusTomSelect () {
    if (!this.tomSelect) return
    this.tomSelect.isFocused = true
    this.tomSelect.refreshState()
    this.tomSelect.ignoreFocus = true
    this.tomSelect.control_input.focus()
    window.setTimeout(() => { if (this.tomSelect) this.tomSelect.ignoreFocus = false }, 0)
  }

  resetTomSelect () {
    if (!this.tomSelect) return
    this.tomSelect.clear(true)
    this.tomSelect.blur()
    this._needsReload = true
  }

  preventDropdownClose () {
    if (!this.tomSelect) return
    if (!this._originalClose) this._originalClose = this.tomSelect.close.bind(this.tomSelect)
    this.tomSelect.close = () => {}
    if (this._onDocumentMousedown) document.removeEventListener('mousedown', this._onDocumentMousedown, true)
    this._onDocumentMousedown = (e) => {
      if (!this.tomSelect) return
      const dropdown = this.tomSelect.dropdown
      if (dropdown && !dropdown.contains(e.target)) {
        const activeInput = dropdown.querySelector('.f-input-ordered-multiselect__option-edit-input')
        if (activeInput) this.cancelOptionRename(activeInput)
        this.restoreDropdownClose()
      }
    }
    window.setTimeout(() => { document.addEventListener('mousedown', this._onDocumentMousedown, true) }, 0)
  }

  restoreDropdownClose (keepOpen) {
    if (this._onDocumentMousedown) { document.removeEventListener('mousedown', this._onDocumentMousedown, true); this._onDocumentMousedown = null }
    if (this._pendingClickBlocker && this.tomSelect) { this.tomSelect.dropdown.removeEventListener('click', this._pendingClickBlocker, true); this._pendingClickBlocker = null }
    if (!this.tomSelect || !this._originalClose) return
    this.tomSelect.close = this._originalClose
    this._originalClose = null
    this.tomSelect.clear(true)
    if (keepOpen) return
    this._needsReload = true
    this.tomSelect.close()
    this.tomSelect.blur()
  }

  async onOptionDeleteClick (e) {
    e.preventDefault()
    e.stopPropagation()
    // Cancel any active rename in the dropdown before deleting
    if (this.tomSelect) {
      const activeInput = this.tomSelect.dropdown.querySelector('.f-input-ordered-multiselect__option-edit-input')
      if (activeInput) {
        const activeEl = activeInput.closest('.f-input-ordered-multiselect__option-with-actions')
        if (activeEl) this.restoreOptionHtml(activeEl, activeInput.dataset.value, activeInput.dataset.originalLabel)
      }
    }
    const value = e.currentTarget.dataset.value
    const optionEl = e.currentTarget.closest('.option')
    this.preventDropdownClose()
    const success = await this.deleteItem(value)
    if (success) {
      window.FolioConsole.Ui.Flash.success(window.Folio.Input.OrderedMultiselect.t('deleted'))
      if (optionEl) {
        optionEl.style.transition = 'opacity 0.3s, max-height 0.3s'
        optionEl.style.overflow = 'hidden'
        optionEl.style.maxHeight = optionEl.offsetHeight + 'px'
        optionEl.style.opacity = '0.5'
        window.setTimeout(() => { optionEl.style.opacity = '0'; optionEl.style.maxHeight = '0'; optionEl.style.padding = '0'; optionEl.style.margin = '0' }, 100)
        window.setTimeout(() => { optionEl.remove() }, 400)
      }
      // Check if any real options remain after this deletion
      const allOptions = this.tomSelect.dropdown.querySelectorAll('.option')
      const realRemaining = Array.from(allOptions).filter((el) => el !== optionEl)
      if (realRemaining.length === 0) {
        this.restoreDropdownClose()
      } else {
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
    this.element.dispatchEvent(new Event('change', { bubbles: true }))
  }

  renderList () {
    if (!this.hasListTarget) return
    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const t = window.Folio.Input.OrderedMultiselect.t
    const dragIcon = this.sortableValue ? `<span class="f-input-ordered-multiselect__item-handle">${window.Folio.Input.OrderedMultiselect.iconHtml('drag', { height: 24 })}</span>` : ''
    const editIcon = window.Folio.Input.OrderedMultiselect.iconHtml('edit_box', { height: 16 })
    const closeIcon = window.Folio.Input.OrderedMultiselect.iconHtml('close', { height: 16 })
    const usageHint = window.Folio.Input.OrderedMultiselect.usageHintHtml
    this.listTarget.innerHTML = this.itemsValue.map((item) => `
      <div class="f-input-ordered-multiselect__item" data-value="${item.value}">
        ${dragIcon}
        <span class="f-input-ordered-multiselect__item-label">${escape(item.label)}${usageHint(item.usage_labels, 'f-input-ordered-multiselect__item-usage')}</span>
        <span class="f-input-ordered-multiselect__item-actions">
          ${this.createableValue ? `<button type="button" class="btn btn-none f-input-ordered-multiselect__item-action" data-action="click->f-input-ordered-multiselect#onItemRenameClick" data-value="${item.value}" data-label="${escape(item.label)}" title="${t('rename')}">${editIcon}</button>` : ''}
          <button type="button" class="btn btn-none f-input-ordered-multiselect__item-action f-input-ordered-multiselect__item-action--danger" data-action="click->f-input-ordered-multiselect#onItemRemoveClick" data-value="${item.value}" title="${t('remove')}">${closeIcon}</button>
        </span>
      </div>`).join('')
    if (this.sortableValue && this._sortableInitialized) this.refreshSortable()
    // Prevent mousedown on action buttons from stealing focus from an active rename input.
    // Without this, blur fires before click, the 50ms timer destroys the DOM,
    // and the click event never reaches the target button.
    this.listTarget.querySelectorAll('.f-input-ordered-multiselect__item-action').forEach((btn) => {
      btn.addEventListener('mousedown', (e) => e.preventDefault())
    })
  }

  syncHiddenInputs () {
    if (!this.hasHiddenContainerTarget) return
    const p = this.paramBaseValue
    const fk = this.foreignKeyValue
    let html = ''
    let idx = 0
    this.itemsValue.forEach((item) => {
      if (item.id) html += `<input type="hidden" name="${p}[${idx}][id]" value="${item.id}">`
      html += `<input type="hidden" name="${p}[${idx}][${fk}]" value="${item.value}">`
      html += `<input type="hidden" name="${p}[${idx}][position]" value="${idx + 1}">`
      idx++
    })
    this.removedItemsValue.forEach((item) => {
      if (item.id) {
        html += `<input type="hidden" name="${p}[${idx}][id]" value="${item.id}"><input type="hidden" name="${p}[${idx}][_destroy]" value="1">`
        idx++
      }
    })
    this.hiddenContainerTarget.innerHTML = html
  }

  // --- Item list actions (remove, rename) ---

  onItemRemoveClick (e) {
    e.preventDefault()
    const value = e.currentTarget.dataset.value
    const item = this.itemsValue.find((i) => String(i.value) === String(value))
    if (!item) return
    this.itemsValue = this.itemsValue.filter((i) => String(i.value) !== String(value))
    if (item.id) this.removedItemsValue = [...this.removedItemsValue, { ...item, usage_labels: this._removeCurrentLabel(item.usage_labels) }]
    // Update loadedOptions so dropdown shows updated usage_labels
    const valStr = String(value)
    if (this.loadedOptions[valStr]) {
      this.loadedOptions[valStr].usage_labels = this._removeCurrentLabel(this.loadedOptions[valStr].usage_labels)
    }
    this._needsReload = true
  }

  onItemRenameClick (e) {
    e.preventDefault()
    if (this._blurCancelTimer) { clearTimeout(this._blurCancelTimer); this._blurCancelTimer = null }
    const value = e.currentTarget.dataset.value
    const label = e.currentTarget.dataset.label
    // Cancel any active rename by re-rendering the list, then find the target item fresh
    this.renderList()
    // renderList() destroys the previous rename input, triggering its blur handler
    // which sets a new timer — clear it so it doesn't wipe out the rename we're about to set up
    if (this._blurCancelTimer) { clearTimeout(this._blurCancelTimer); this._blurCancelTimer = null }
    const itemEl = this.listTarget.querySelector(`.f-input-ordered-multiselect__item[data-value="${value}"]`)
    if (!itemEl) return
    const escape = window.Folio.Input.OrderedMultiselect.escapeHtml
    const labelEl = itemEl.querySelector('.f-input-ordered-multiselect__item-label')
    const actionsEl = itemEl.querySelector('.f-input-ordered-multiselect__item-actions')
    const confirmIcon = window.Folio.Input.OrderedMultiselect.iconHtml('checkbox_marked', { height: 16 })
    const item = this.itemsValue.find((i) => String(i.value) === String(value))
    const usageHintStr = window.Folio.Input.OrderedMultiselect.usageHintHtml(item && item.usage_labels, 'f-input-ordered-multiselect__item-usage')
    labelEl.innerHTML = `<div class="f-input-ordered-multiselect__field-wrap">
        <input type="text" class="f-input-ordered-multiselect__item-rename-input" value="${escape(label)}" data-value="${escape(value)}" data-original-label="${escape(label)}">
      </div>${usageHintStr}`
    actionsEl.innerHTML = `<span class="f-input-ordered-multiselect__item-action text-success f-input-ordered-multiselect__item-confirm" tabindex="0">${confirmIcon}</span>`
    const input = labelEl.querySelector('input')
    const confirmBtn = actionsEl.querySelector('.f-input-ordered-multiselect__item-confirm')
    input.addEventListener('input', (e) => this.onItemRenameInputCheck(e))
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') { e.preventDefault(); e.stopPropagation(); this.onItemRenameSubmit(e) }
      else if (e.key === 'Escape') this.onItemRenameCancel(e)
    })
    input.addEventListener('blur', (e) => {
      if (e.relatedTarget && e.relatedTarget.closest('.f-input-ordered-multiselect__item-confirm')) return
      // Delay cancel so that a click on another rename button can fire first
      // and cancel the timer via renderList() in onItemRenameClick
      this._blurCancelTimer = window.setTimeout(() => { this._blurCancelTimer = null; this.renderList() }, 50)
    })
    confirmBtn.addEventListener('mousedown', (e) => e.preventDefault())
    confirmBtn.addEventListener('click', (e) => {
      e.preventDefault()
      this.onItemRenameSubmit({ target: input, preventDefault: () => {}, stopPropagation: () => {} })
    })
    input.focus()
    input.select()
  }

  onItemRenameInputCheck (e) {
    this.checkRenameDuplicate(e.target || e.currentTarget, '.f-input-ordered-multiselect__item-label', '.f-input-ordered-multiselect__item-usage')
  }

  async onItemRenameSubmit (e) {
    e.preventDefault()
    e.stopPropagation()
    const input = e.target.closest('.f-input-ordered-multiselect__item-rename-input') || e.currentTarget
    const value = input.dataset.value
    const newLabel = input.value.trim()
    if (!newLabel || newLabel === input.dataset.originalLabel) { this.renderList(); return }
    if (window.Folio.Input.OrderedMultiselect.isDuplicateLabel(newLabel, input.dataset.originalLabel, this.itemsValue.map((i) => i.label), this.loadedOptions)) {
      input.classList.add('is-invalid')
      return
    }
    const success = await this.renameItem(value, newLabel, true)
    this.renderList()
    if (success) {
      const newItemEl = this.listTarget.querySelector(`[data-value="${value}"]`)
      if (newItemEl) {
        newItemEl.classList.add('f-input-ordered-multiselect__item--flash')
        window.setTimeout(() => newItemEl.classList.remove('f-input-ordered-multiselect__item--flash'), 600)
      }
    }
  }

  onItemRenameCancel () {
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
    if (window.sortable && this.hasListTarget) window.sortable(this.listTarget)
  }

  destroySortable () {
    if (this._sortableInitialized && window.sortable && this.hasListTarget) {
      this.listTarget.removeEventListener('sortupdate', this._onSortUpdate)
      window.sortable(this.listTarget, 'destroy')
      this._sortableInitialized = false
    }
  }

  onSortUpdate () {
    const reordered = Array.from(this.listTarget.querySelectorAll('.f-input-ordered-multiselect__item'))
      .map((el) => this.itemsValue.find((item) => String(item.value) === String(el.dataset.value)))
      .filter(Boolean)
    this._skipRender = true
    try { this.itemsValue = reordered } finally { this._skipRender = false }
    this.syncHiddenInputs()
    this.element.dispatchEvent(new Event('change', { bubbles: true }))
  }

  // --- Shared helpers ---

  checkRenameDuplicate (input, containerSelector, hintSelector) {
    const dup = window.Folio.Input.OrderedMultiselect.isDuplicateLabel(input.value, input.dataset.originalLabel, this.itemsValue.map((i) => i.label), this.loadedOptions)
    input.classList.toggle('is-invalid', dup)
    const container = input.closest(containerSelector)
    const hintEl = container && container.querySelector(hintSelector)
    if (!hintEl) return
    if (dup) {
      if (!hintEl.dataset.originalText) hintEl.dataset.originalText = hintEl.textContent
      hintEl.textContent = window.Folio.Input.OrderedMultiselect.t('alreadyExists')
      hintEl.classList.add('text-danger')
    } else {
      if (hintEl.dataset.originalText) hintEl.textContent = hintEl.dataset.originalText
      hintEl.classList.remove('text-danger')
    }
  }

  _addCurrentLabel (labels) {
    const c = this.currentRecordLabelValue
    if (!c) return labels || []
    const arr = labels ? [...labels] : []
    if (!arr.includes(c)) arr.push(c)
    return arr
  }

  _removeCurrentLabel (labels) {
    const c = this.currentRecordLabelValue
    return (!c || !labels) ? (labels || []) : labels.filter((l) => l !== c)
  }
})

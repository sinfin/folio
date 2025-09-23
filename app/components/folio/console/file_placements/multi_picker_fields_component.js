window.Folio.Stimulus.register('f-c-file-placements-multi-picker-fields', class extends window.Stimulus.Controller {
  static values = {
    empty: Boolean
  }

  static targets = ['source']

  connect () {
    this.hookOntoTabbedTiptapFormWrap()
  }

  hookOntoTabbedTiptapFormWrap () {
    if (this.hookedOntoTabbedTiptapFormWrap) return
    if (!this.hasSourceTarget) return

    const tabPane = this.element.closest('.f-c-ui-tabs-tab-pane')
    if (!tabPane) return

    const tabLink = document.querySelector(`.f-c-ui-tabs__nav-link[data-bs-target="#${tabPane.id}"], .f-c-ui-tabs__nav-link[data-bs-href="#${tabPane.id}"]`)
    if (!tabLink) return

    tabLink.classList.add('f-c-file-placements-multi-picker-fields-nav-link')
    tabPane.classList.add('f-c-file-placements-multi-picker-fields-tab')

    const tiptapFormWrap = tabPane.closest('.f-c-tiptap-simple-form-wrap')
    if (!tiptapFormWrap) return

    this.dispatch('hookOntoFormWrap', {
      detail: {
        element: this.element,
        source: this.sourceTarget
      }
    })

    this.hookedOntoTabbedTiptapFormWrap = true
  }

  onAddToPicker (e) {
    // stopPropagation so that .f-c-tiptap-simple-form-wrap doesn't catch it as well
    // only make it catch when the source div is detached to the editor part
    e.stopPropagation()

    const fields = this.element.querySelector('.f-nested-fields')
    if (!fields) throw new Error('f-nested-fields not found')

    const files = e.detail.files
    if (!files || files.length < 1) throw new Error('files not provided')

    const attributesCollection = files.map((file) => {
      return {
        'data-file': JSON.stringify(file)
      }
    })

    fields.dispatchEvent(new CustomEvent('f-nested-fields:addMultipleWithAttributes', {
      detail: { attributesCollection }
    }))
  }

  onAdded (e) {
    this.onCountChange(e, true)
  }

  onDestroyed (e) {
    this.onCountChange(e, false)
  }

  onCountChange (e, added) {
    const empty = e && e.detail && e.detail.count === 0

    if (empty !== this.emptyValue) {
      this.emptyValue = empty
    }

    // setTimeout to ensure DOM is updated first
    window.setTimeout(() => {
      this.handleDuplicates()
      if (added) {
        this.focusNewlyAdded(e)
      }
    }, 0)
  }

  focusNewlyAdded (e) {
    const placements = this.element.querySelectorAll('.f-c-file-placements-multi-picker-fields-placement')
    if (placements.length < 1) return

    const lastPlacement = placements[placements.length - 1]
    if (!lastPlacement) return

    const input = lastPlacement.querySelector('.f-c-file-placements-multi-picker-fields-placement__field--description .form-control')
    if (!input) return

    lastPlacement.scrollIntoView({ behavior: 'smooth', block: 'center' })
    input.focus()
  }

  handleDuplicates () {
    const placementsHash = {}

    for (const placement of this.element.querySelectorAll('.f-c-file-placements-multi-picker-fields-placement[data-f-c-file-placements-multi-picker-fields-placement-state-value="filled"]')) {
      const destroyInput = placement.closest('.f-nested-fields__fields').querySelector('.f-nested-fields__destroy-input')

      if (destroyInput && destroyInput.value !== '1') {
        const fileIdInput = placement.querySelector('.f-c-files-picker__input--file_id')

        if (fileIdInput && fileIdInput.value) {
          placementsHash[fileIdInput.value] = placementsHash[fileIdInput.value] || []
          placementsHash[fileIdInput.value].push(placement)
        }
      }
    }

    Object.values(placementsHash).forEach((placements) => {
      placements.forEach((placement) => {
        placement.classList.toggle('f-c-file-placements-multi-picker-fields-placement--non-unique-file-id', placements.length > 1)
      })
    })
  }
})

window.Folio.Stimulus.register('f-c-file-placements-multi-picker-fields-add-embed', class extends window.Stimulus.Controller {
  onAddEmbedClick () {
    const fields = this.element.closest('form').querySelector('.f-nested-fields')
    if (!fields) throw new Error('f-nested-fields not found')

    const attributesCollection = [{ 'data-embed': 'true' }]

    fields.dispatchEvent(new CustomEvent('f-nested-fields:addMultipleWithAttributes', {
      detail: { attributesCollection }
    }))
  }
})

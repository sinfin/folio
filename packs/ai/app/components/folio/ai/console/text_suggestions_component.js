(() => {
  const CONTROLLER_NAME = 'f-ai-c-text-suggestions'
  const BEM_CLASS_NAME = 'f-ai-c-text-suggestions'
  const SELECTED_CLASS = `${BEM_CLASS_NAME}__suggestion--selected`

  const registerTextSuggestionsComponentController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = ['instructions']

      static values = {
        targetInputId: String,
        integrationKey: String,
        fieldKey: String
      }

      connect () {
        this.targetInputListener = () => this.onTargetInput()
        this.undoButtonListener = (event) => this.undo(event)
        this.connectedInput = this.input
        this.connectedUndoButton = this.undoButton
        this.connectedInput?.addEventListener('input', this.targetInputListener)
        this.connectedUndoButton?.addEventListener('click', this.undoButtonListener)
        this.syncControls()
      }

      disconnect () {
        this.connectedInput?.removeEventListener('input', this.targetInputListener)
        this.connectedUndoButton?.removeEventListener('click', this.undoButtonListener)
      }

      close (event) {
        this.stopActionEvent(event)
        this.dispatch('close', { bubbles: true })
      }

      regenerate (event) {
        this.stopActionEvent(event)
        this.dispatch('regenerate', {
          bubbles: true,
          detail: { instructions: this.hasInstructionsTarget ? this.instructionsTarget.value : '' }
        })
      }

      undo (event) {
        this.stopActionEvent(event)

        if (this.snapshot === null) return
        if (!this.input) return

        this.writeValue(this.input, this.snapshot)
        this.selectedText = null
        this.clearSelection()
        this.undoVisible = false
        this.syncControls()

        this.dispatch('undo', { detail: this.trackingDetail() })
      }

      accept (event) {
        this.stopActionEvent(event)

        if (!this.input) return

        const text = event.params.text || ''
        this.selectedText = text
        this.writeValue(this.input, text)
        this.markSelected(event.currentTarget)
        this.undoVisible = true
        this.syncControls()

        this.dispatch('accepted', { detail: this.trackingDetail() })
      }

      acceptFromKeyboard (event) {
        if (!['Enter', ' '].includes(event.key)) return

        this.accept(event)
      }

      copy (event) {
        this.stopActionEvent(event)

        const text = event.params.text || ''

        this.copyText(text).then(() => {
          this.dispatch('copied', { detail: this.trackingDetail() })
        })
      }

      stopPropagation (event) {
        event.stopPropagation()
      }

      onTargetInput () {
        if (!this.selectedText) return
        if (!this.input || this.input.value === this.selectedText) return

        this.selectedText = null
        this.clearSelection()
      }

      writeValue (input, value) {
        input.value = value
        input.dispatchEvent(new Event('input', { bubbles: true }))
        input.dispatchEvent(new Event('change', { bubbles: true }))
        input.dispatchEvent(new CustomEvent('folioConsoleCustomChange', { bubbles: true }))
      }

      markSelected (selectedElement) {
        this.clearSelection()

        const suggestion = selectedElement.closest(`.${BEM_CLASS_NAME}__suggestion`) || selectedElement
        suggestion.classList.add(SELECTED_CLASS)
      }

      clearSelection () {
        this.element.querySelectorAll(`.${SELECTED_CLASS}`).forEach((element) => {
          element.classList.remove(SELECTED_CLASS)
        })
      }

      copyText (text) {
        if (navigator.clipboard?.writeText) {
          return navigator.clipboard.writeText(text)
        }

        const input = document.createElement('textarea')
        input.value = text
        input.setAttribute('readonly', 'readonly')
        input.style.position = 'absolute'
        input.style.left = '-9999px'
        document.body.appendChild(input)
        input.select()
        document.execCommand('copy')
        input.remove()

        return Promise.resolve()
      }

      syncControls () {
        if (this.wrapper) {
          this.wrapper.dataset.fAiInputUndoVisible = this.undoVisible ? 'true' : 'false'

          if (this.selectedText) {
            this.wrapper.dataset.fAiInputSelectedText = this.selectedText
          } else {
            delete this.wrapper.dataset.fAiInputSelectedText
          }
        }

        if (this.undoButton) {
          this.undoButton.hidden = !this.undoVisible
        }
      }

      trackingDetail () {
        return {
          integrationKey: this.integrationKeyValue,
          fieldKey: this.fieldKeyValue
        }
      }

      stopActionEvent (event) {
        if (!event) return

        event.preventDefault()
        event.stopPropagation()
      }

      get input () {
        if (this.targetInputIdValue) {
          return document.getElementById(this.targetInputIdValue)
        }

        return this.wrapper?.querySelector('[data-f-ai-input-target~="input"]') || null
      }

      get wrapper () {
        return this.element.closest('.f-ai-input')
      }

      get undoButton () {
        return this.wrapper?.querySelector('.f-ai-input__undo') || null
      }

      get snapshot () {
        return Object.prototype.hasOwnProperty.call(this.wrapper?.dataset || {}, 'fAiInputSnapshot')
          ? this.wrapper.dataset.fAiInputSnapshot
          : null
      }

      get selectedText () {
        return this.wrapper?.dataset.fAiInputSelectedText || null
      }

      set selectedText (value) {
        if (!this.wrapper) return

        if (value) {
          this.wrapper.dataset.fAiInputSelectedText = value
        } else {
          delete this.wrapper.dataset.fAiInputSelectedText
        }
      }

      get undoVisible () {
        return this.wrapper?.dataset.fAiInputUndoVisible === 'true'
      }

      set undoVisible (value) {
        if (!this.wrapper) return

        this.wrapper.dataset.fAiInputUndoVisible = value ? 'true' : 'false'
      }
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerTextSuggestionsComponentController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerTextSuggestionsComponentController, { once: true })
  }
})()

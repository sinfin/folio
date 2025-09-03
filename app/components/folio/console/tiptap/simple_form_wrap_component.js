window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap', class extends window.Stimulus.Controller {
  static targets = ["scrollIco", "scroller", "wordCount"]

  static values = {
    scrolledToBottom: Boolean,
  }

  connect () {
    this.onScroll = Folio.throttle(this.onScrollRaw.bind(this))
  }

  disconnect () {
    delete this.onScroll
  }

  onScrollRaw (e) {
    const scroller = e.target
    this.scrolledToBottomValue = scroller.scrollHeight - scroller.scrollTop <= scroller.clientHeight + 1
  }

  onScrollTriggerClick (e) {
    e.preventDefault()

    const scroller = this.scrollerTarget

    if (this.scrolledToBottomValue) {
      scroller.scrollTo({
        top: 0,
        behavior: 'smooth',
      })
    } else {
      scroller.scrollTo({
        top: scroller.scrollHeight,
        behavior: 'smooth',
      })
    }
  }

  updateWordCount (e) {
    const wordCount = e.detail && e.detail.wordCount
    if (!wordCount) return
    if (!this.hasWordCountTarget) return
    this.wordCountTarget.dispatchEvent(new CustomEvent('f-c-tiptap-simple-form-wrap:updateWordCount', { detail: { wordCount } }))
  }

  onContinueUnsavedChanges (e) {
    const tiptapInput = this.element.querySelector('[data-controller*="f-input-tiptap"]')

    if (tiptapInput) {
      tiptapInput.dispatchEvent(new CustomEvent('f-c-tiptap-simple-form-wrap:tiptapContinueUnsavedChanges'))
    }
  }

  callAutosaveInfoMethod(methodName) {
    const autosaveInfoComponent = this.element.querySelector('[data-controller*="f-c-tiptap-simple-form-wrap-autosave-info"]')

    if (autosaveInfoComponent) {
      const autosaveController = this.application.getControllerForElementAndIdentifier(autosaveInfoComponent, 'f-c-tiptap-simple-form-wrap-autosave-info')
      if (autosaveController && autosaveController[methodName]) {
        autosaveController[methodName]()
      }
    }
  }

  onTiptapContinueUnsavedChanges (e) {
    this.callAutosaveInfoMethod('hideUnsavedChanges')
  }

  onTiptapAutosaveFailed (e) {
    this.callAutosaveInfoMethod('showFailedToSave')
  }

  onTiptapAutosaveSucceeded (e) {
    this.callAutosaveInfoMethod('hideFailedToSave')
  }
})

window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap', class extends window.Stimulus.Controller {
  static targets = ['scrollIco', 'scroller', 'wordCount', 'fields']

  static values = {
    scrolledToBottom: Boolean
  }

  connect () {
    this.onScroll = window.Folio.throttle(this.onScrollRaw.bind(this))
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
        behavior: 'smooth'
      })
    } else {
      scroller.scrollTo({
        top: scroller.scrollHeight,
        behavior: 'smooth'
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

  callAutosaveInfoMethod (methodName) {
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

  onAddToMultiPicker (e) {
    const multiPickers = this.element.querySelectorAll('.f-c-file-placements-multi-picker-fields')

    if (multiPickers.length > 1) {
      throw new Error('More than 1 multi pickers found')
    } else if (multiPickers.length === 0) {
      throw new Error('No multi pickers found')
    }

    multiPickers[0].dispatchEvent(new CustomEvent('f-c-file-placements-multi-picker-fields:addToPicker', {
      detail: e.detail
    }))
  }

  onMultiPickerHookOntoFormWrap (e) {
    const source = e.detail.source

    const wrapper = document.createElement('div')

    // add containter-fluid to extend index filters
    wrapper.className = 'f-c-tiptap-simple-form-wrap__multi-picker-wrap container-fluid'

    wrapper.appendChild(source)
    this.fieldsTarget.insertAdjacentElement('afterend', wrapper)

    this.multiPickerHooked = true
    this.checkTabsForMultiPicker()
  }

  onTabsChange () {
    this.checkTabsForMultiPicker()
  }

  checkTabsForMultiPicker () {
    if (!this.multiPickerHooked) return

    const activeLink = this.element.querySelector('.f-c-ui-tabs__nav-link.active')
    const visible = activeLink.classList.contains('f-c-file-placements-multi-picker-fields-nav-link')
    this.element.classList.toggle('f-c-tiptap-simple-form-wrap--multi-picker-visible', visible)
  }
})

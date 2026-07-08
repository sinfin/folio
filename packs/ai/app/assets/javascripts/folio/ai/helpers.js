(() => {
  window.Folio = window.Folio || {}
  window.Folio.Ai = window.Folio.Ai || {}

  window.Folio.Ai.i18n = {
    cs: {
      genericError: 'Návrhy AI se nepodařilo vygenerovat.',
      requestTimeout: 'Generování návrhů AI trvá příliš dlouho. Zkuste to prosím znovu.'
    },
    en: {
      genericError: 'AI suggestions could not be generated.',
      requestTimeout: 'AI suggestions are taking too long. Please try again.'
    }
  }

  const addSnapshotValue = (snapshot, key, value) => {
    if (Object.prototype.hasOwnProperty.call(snapshot, key)) {
      snapshot[key] = Array.isArray(snapshot[key])
        ? [...snapshot[key], value]
        : [snapshot[key], value]
    } else {
      snapshot[key] = value
    }
  }

  const errorDetail = (responseData) => {
    if (!responseData.errors || responseData.errors.length === 0) return null

    return responseData.errors[0].detail || responseData.errors[0].title
  }

  window.Folio.Ai.cssEscape = (value) => {
    value = value.toString()

    if (window.CSS?.escape) return window.CSS.escape(value)

    return value.replace(/["\\]/g, '\\$&')
  }

  window.Folio.Ai.formSnapshot = (form) => {
    if (!form) return {}

    const snapshot = {}
    const formData = new FormData(form)

    formData.forEach((value, key) => {
      if (value instanceof File) return

      addSnapshotValue(snapshot, key, value.toString())
    })

    return snapshot
  }

  window.Folio.Ai.errorMessage = (error, fallback) => {
    const responseData = error?.responseData || {}
    const detail = responseData.message || errorDetail(responseData)

    return detail || error?.message || fallback
  }

  window.Folio.Ai.textInputState = (input) => {
    if (!input) return null

    return {
      value: input.value,
      focused: document.activeElement === input,
      selectionStart: input.selectionStart,
      selectionEnd: input.selectionEnd,
      selectionDirection: input.selectionDirection
    }
  }

  window.Folio.Ai.restoreTextInputState = (input, state) => {
    if (!input || !state) return

    input.value = state.value

    if (state.focused) {
      input.focus()
      input.setSelectionRange(state.selectionStart, state.selectionEnd, state.selectionDirection)
    }
  }

  window.Folio.Ai.writeInputValue = (input, value, { folioAutosave = true } = {}) => {
    if (!input) return

    input.value = value

    const eventTypes = ['input', 'change', 'folioConsoleCustomChange']

    eventTypes.forEach((type) => {
      input.dispatchEvent(new CustomEvent(type, {
        bubbles: true,
        detail: { folioAutosave }
      }))
    })
  }
})()

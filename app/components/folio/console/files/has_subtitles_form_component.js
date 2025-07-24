window.Folio.Stimulus.register('f-c-files-has-subtitles-form', class extends window.Stimulus.Controller {
  static targets = ["loader"]

  static values = {
    reloadUrl: String,
    retranscribeUrl: String
  }

  disconnect () {
    this.abortAjax()
  }

  abortAjax () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  ajax ({ url, data, apiMethod = 'apiGet' }) {
    this.abortAjax()
    this.abortController = new AbortController()

    window.Folio.Api[apiMethod](url, data, this.abortController.signal).then((res) => {
      if (res && res.data) {
        this.element.outerHTML = res.data
      } else {
        window.alert('Invalid server response')
      }
    }).catch((e) => {
      window.alert('Error: ' + e.message)
      this.loaderTarget.hidden = true
    }).finally(() => {
      delete this.abortController
    })
  }

  retranscribe (e) {
    window.Folio.Confirm.confirm(() => {
      this.ajax({
        url: this.retranscribeUrlValue,
        apiMethod: "apiPost",
      })
    })
  }

  reload (e) {
    this.ajax({
      url: this.reloadUrlValue,
    })
  }

  cancelForm () {
    window.Folio.Confirm.confirm(() => {
      this.reload()
    })
  }

  onFormSubmit (e) {
    e.preventDefault()

    if (!this.loaderTarget.hidden) return
    this.loaderTarget.hidden = false

    const form = e.target

    this.ajax({
      url: form.action,
      apiMethod: 'apiPatch',
      data: window.Folio.formToHash(form),
    })
  }
})

window.Folio.MessageBus.callbacks['f-c-files-has-subtitles-form'] = (data) => {
  if (!data || (data.type !== 'Folio::OpenAi::TranscribeSubtitlesJob/updated' && 
                data.type !== 'Folio::ElevenLabs::TranscribeSubtitlesJob/updated')) return

  const wraps = document.querySelectorAll(`.f-c-files-has-subtitles-form[data-f-c-files-has-subtitles-form-file-id-value="${data.data.id}"]`)

  for (const wrap of wraps) {
    wrap.dispatchEvent(new CustomEvent('f-c-files-has-subtitles-form:reload'))
  }
}

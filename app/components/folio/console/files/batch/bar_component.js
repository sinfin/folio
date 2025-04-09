window.Folio.Stimulus.register('f-c-files-batch-bar', class extends window.Stimulus.Controller {
  static values = {
    baseApiUrl: String,
    loading: Boolean
  }

  disconnect () {
    this.abortAjax()
  }

  abortAjax () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  batchActionFromFile (e) {
    this.abortAjax()

    const { action, id } = e.detail

    let url = this.baseApiUrlValue
    const data = {}

    switch (action) {
      case 'add':
        url = `${url}/add_to_batch`
        data.file_ids = [id]
        break
      case 'remove':
        url = `${url}/remove_from_batch`
        data.file_ids = [id]
        break
      case 'add-all':
        url = `${url}/add_to_batch`
        data.file_ids = []

        for (const checkbox of document.querySelectorAll('.f-file-list-file__checkbox')) {
          if (checkbox.value && checkbox.value !== 'all') {
            const numericId = parseInt(checkbox.value)
            if (numericId) {
              checkbox.checked = true
              data.file_ids.push(numericId)
            }
          }
        }

        break
      case 'remove-all':
        url = `${url}/remove_from_batch`
        data.file_ids = []

        for (const checkbox of document.querySelectorAll('.f-file-list-file__checkbox:checked')) {
          if (checkbox.value && checkbox.value !== 'all') {
            const numericId = parseInt(checkbox.value)
            if (numericId) {
              checkbox.checked = false
              data.file_ids.push(numericId)
            }
          }
        }

        break
    }

    if (!url || !data) return

    this.loadingValue = true
    this.abortController = new AbortController()

    window.Folio.Api.apiPost(url, data, this.abortController.signal).then((res) => {
      if (res && res.data) {
        this.element.outerHTML = res.data
        this.loadingValue = false
      } else {
        throw new Error('Failed to perform batch action')
      }
    }).catch((error) => {
      const message = error.message || 'An error occurred'
      window.FolioConsole.Flash.alert(message)
      this.loadingValue = false
    }).finally(() => {
      delete this.abortController
    })
  }
})

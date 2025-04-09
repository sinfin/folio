//= require folio/confirm

window.Folio.Stimulus.register('f-c-files-batch-bar', class extends window.Stimulus.Controller {
  static values = {
    baseApiUrl: String,
    loading: Boolean,
    fileIdsJson: String
  }

  disconnect () {
    this.abortAjax()
  }

  abortAjax () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  settings () {
    console.log('settings')
  }

  download () {
    console.log('download')
  }

  delete () {
    window.Folio.Confirm.confirm(() => {
      this.ajax({
        url: `${this.baseApiUrlValue}/batch_delete`,
        data: { file_ids: JSON.parse(this.fileIdsJsonValue) },
        apiMethod: 'apiDelete'
      })
    }, 'delete')
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

    this.ajax({ url, data })
  }

  ajax ({ url, data, apiMethod = 'apiPost' }) {
    this.loadingValue = true
    this.abortController = new AbortController()

    window.Folio.Api[apiMethod](url, data, this.abortController.signal).then((res) => {
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

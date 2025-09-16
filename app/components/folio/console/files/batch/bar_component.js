//= require folio/confirm

window.Folio.Stimulus.register('f-c-files-batch-bar', class extends window.Stimulus.Controller {
  static values = {
    baseApiUrl: String,
    status: String,
    fileIdsJson: String,
    changeToPropagate: Object
  }

  static targets = ['form']

  changeToPropagateValueChanged (from, to) {
    if (this.changeToPropagateValue && this.changeToPropagateValue.file_ids) {
      let eventName

      if (this.changeToPropagateValue.change === 'update') {
        eventName = 'updated'
      } else if (this.changeToPropagateValue.change === 'delete') {
        eventName = 'deleted'
      }

      this.changeToPropagateValue.file_ids.forEach((fileId) => {
        for (const fileElement of document.querySelectorAll(`.f-file-list-file[data-f-file-list-file-id-value="${fileId}"]`)) {
          fileElement.dispatchEvent(new CustomEvent(`f-file-list-file:${eventName}`))
        }
      })
    }
  }

  connect () {
    this.onReloadTrigger = window.Folio.throttle(() => {
      console.log('onReloadTrigger')
      this.onReloadTriggerRaw()
    })
  }

  disconnect () {
    this.abortAjax()
    delete this.onReloadTrigger
  }

  abortAjax () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  openForm () {
    this.ajax({
      url: `${this.baseApiUrlValue}/open_batch_form`
    })
  }

  cancelForm () {
    this.ajax({
      url: `${this.baseApiUrlValue}/close_batch_form`
    })
  }

  cancelDownload () {
    this.ajax({
      url: `${this.baseApiUrlValue}/cancel_batch_download`
    })
  }

  submitForm (e) {
    const { data } = e.detail

    this.ajax({
      url: `${this.baseApiUrlValue}/batch_update`,
      apiMethod: 'apiPatch',
      data: { ...data, file_ids: JSON.parse(this.fileIdsJsonValue) }
    })
  }

  download () {
    this.ajax({
      url: `${this.baseApiUrlValue}/batch_download`,
      data: { file_ids: JSON.parse(this.fileIdsJsonValue) }
    })
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

    const { action, ids } = e.detail

    this.queue = this.queue || { add: [], remove: [] }

    const url = this.baseApiUrlValue

    switch (action) {
      case 'add':
        this.queue.add = [...this.queue.add, ...ids]
        break
      case 'remove':
        this.queue.remove = [...this.queue.remove, ...ids]
        break
      case 'add-all':
        for (const checkbox of document.querySelectorAll('.f-file-list-file-batch-checkbox__input')) {
          if (checkbox.value && checkbox.value !== 'all') {
            const numericId = parseInt(checkbox.value)
            if (numericId) {
              checkbox.checked = true
              this.queue.add.push(numericId)
            }
          }
        }

        break
      case 'remove-all':
        for (const checkbox of document.querySelectorAll('.f-file-list-file-batch-checkbox__input:checked')) {
          if (checkbox.value && checkbox.value !== 'all') {
            const numericId = parseInt(checkbox.value)
            if (numericId) {
              checkbox.checked = false
              this.queue.remove.push(numericId)
            }
          }
        }

        break
    }

    if (this.queue.add.length === 0 && this.queue.remove.length === 0) return

    const addCallbackIds = this.queue.add ? [...this.queue.add] : []
    const removeCallbackIds = this.queue.remove ? [...this.queue.remove] : []

    const callback = () => {
      if (addCallbackIds) {
        this.dispatchCheckboxEvents(addCallbackIds, 'add')
      }

      if (removeCallbackIds) {
        this.dispatchCheckboxEvents(removeCallbackIds, 'remove')
      }
    }

    this.ajax({ url: `${url}/handle_batch_queue`, data: { queue: this.queue }, status: 'reloading', callback })
  }

  ajax ({ url, data, callback, apiMethod = 'apiPost', status = 'loading' }) {
    this.statusValue = status
    this.abortController = new AbortController()

    window.Folio.Api[apiMethod](url, data, this.abortController.signal).then((res) => {
      if (res && res.data) {
        if (this.element.parentNode) {
          // only replace if still in the DOM
          this.element.outerHTML = res.data
          this.statusValue = 'loaded'
        }

        if (callback) callback()
      } else {
        throw new Error('Failed to perform batch action')
      }
    }).catch((error) => {
      console.log('if', 'error.name:', error.name, 'AbortError')
      if (error.name === 'AbortError') return

      const message = error.message || 'An error occurred'
      window.FolioConsole.Flash.alert(message)
      this.statusValue = 'loaded'
    }).finally(() => {
      delete this.abortController
    })
  }

  cancel () {
    const fileIds = JSON.parse(this.fileIdsJsonValue)

    this.dispatchCheckboxEvents(fileIds, 'remove')

    this.queue = this.queue || { add: [], remove: [] }
    fileIds.forEach((id) => {
      this.queue.remove.push(id)
    })

    this.ajax({
      url: `${this.baseApiUrlValue}/handle_batch_queue`,
      data: { queue: this.queue },
      status: 'reloading'
    })
  }

  onMessage (e) {
    if (!e.detail || !e.detail.message) return

    const { message } = e.detail

    if (message.type === 'Folio::File::BatchDownloadJob/success') {
      this.ajax({
        url: `${this.baseApiUrlValue}/batch_download_success`,
        data: { file_ids: JSON.parse(this.fileIdsJsonValue), url: message.data.url }
      })
    } else if (message.type === 'Folio::File::BatchDownloadJob/failure') {
      this.ajax({
        url: `${this.baseApiUrlValue}/batch_download_failure`,
        data: { file_ids: JSON.parse(this.fileIdsJsonValue), message: message.data.message }
      })
    }
  }

  dispatchCheckboxEvents (fileIds, checkboxAction) {
    fileIds.forEach((fileId) => {
      const selector = `.f-file-list-file-batch-checkbox__input[value="${fileId}"]`
      const checkboxes = document.querySelectorAll(selector)

      for (const checkbox of checkboxes) {
        checkbox.dispatchEvent(new CustomEvent('f-c-files-batch-bar:batchUpdated', { detail: { action: checkboxAction } }))
      }
    })
  }

  onReloadTriggerRaw () {
    console.log('onReloadTriggerRaw')
    this.ajax({
      url: `${this.baseApiUrlValue}/batch_bar`,
      apiMethod: 'apiGet'
    })
  }
})

window.Folio.MessageBus.callbacks['f-c-files-batch-bar'] = (message) => {
  if (!message) return
  if (!message.type) return
  if (!message.type.startsWith('Folio::File::BatchDownloadJob')) return

  for (const bar of document.querySelectorAll('.f-c-files-batch-bar')) {
    bar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:message', { detail: { message } }))
  }
}

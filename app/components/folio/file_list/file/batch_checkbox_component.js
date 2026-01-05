(() => {
  let lastCheckedId

  window.Folio.Stimulus.register('f-file-list-file-batch-checkbox', class extends window.Stimulus.Controller {
    static targets = ['input']

    disconnect () {
      if (lastCheckedId && lastCheckedId === this.inputTarget.value) {
        lastCheckedId = null
      }
    }

    onGlobalBatchActionCheckboxInput (e) {
      const batchBar = document.querySelector('.f-c-files-batch-bar')
      if (!batchBar) return
      const action = e.target.checked ? 'add-all' : 'remove-all'
      batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:action', { detail: { action } }))
    }

    onBatchActionCheckboxInput (e) {
      this.handleChangeTo(e.target.checked)
    }

    batchUpdated (e) {
      this.inputTarget.checked = e.detail.action === 'add'
    }

    onToggleTriggered (e) {
      const shiftKey = e && e.detail && e.detail.shiftKey

      if (shiftKey && lastCheckedId) {
        if (this.handleShiftSelect()) {
          return
        }
      }

      this.inputTarget.checked = !this.inputTarget.checked
      this.handleChangeTo(this.inputTarget.checked)
    }

    handleChangeTo (checked) {
      const batchBar = document.querySelector('.f-c-files-batch-bar')
      if (!batchBar) return

      const action = checked ? 'add' : 'remove'

      batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:action', { detail: { action, ids: [this.inputTarget.value] } }))

      if (checked) {
        lastCheckedId = this.inputTarget.value
      }
    }

    handleShiftSelect () {
      if (!lastCheckedId) return false

      const batchBar = document.querySelector('.f-c-files-batch-bar')
      if (!batchBar) return false

      const fileList = this.element.closest('.f-file-list--primary-action-index_for_picker, .f-file-list--primary-action-index')
      if (!fileList) return false

      const selectedInput = fileList.querySelector(`.f-file-list-file-batch-checkbox__input[value="${lastCheckedId}"]`)
      if (!selectedInput) return false

      const selectedFileParent = selectedInput.closest('.f-file-list__flex-item')
      if (!selectedFileParent) return false

      const thisFileParent = this.element.closest('.f-file-list__flex-item')
      if (!thisFileParent) return false

      // select all flex items between selected and this
      const fileParentsBetween = []
      const allFileParents = Array.from(fileList.querySelectorAll('.f-file-list__flex-item'))

      const selectedIndex = allFileParents.indexOf(selectedFileParent)
      const thisIndex = allFileParents.indexOf(thisFileParent)

      if (selectedIndex !== -1 && thisIndex !== -1) {
        const startIndex = Math.min(selectedIndex, thisIndex)
        const endIndex = Math.max(selectedIndex, thisIndex)

        for (let i = startIndex; i <= endIndex; i++) {
          fileParentsBetween.push(allFileParents[i])
        }
      }

      const ids = []

      fileParentsBetween.forEach((fileParent) => {
        const input = fileParent.querySelector('.f-file-list-file-batch-checkbox__input')
        if (input && input.value) {
          input.checked = true
          ids.push(input.value)
        }
      })

      batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:action', { detail: { action: 'add', ids } }))
      lastCheckedId = null

      return true
    }
  })
})()

window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.File = window.FolioConsole.File || {}
window.FolioConsole.File.ProcessingNotifier = {}

window.FolioConsole.File.ProcessingNotifier.i18n = {
  cs: {
    audioDone: 'Zpracování audia bylo dokončeno.',
    audioProcessing: 'Audio se zpracovává.',
    videoDone: 'Zpracování videa bylo dokončeno.',
    videoProcessing: 'Video se zpracovává.'
  },
  en: {
    audioDone: 'Audia was finished.',
    audioProcessing: 'Audio is being processed.',
    videoDone: 'Videa was finished.',
    videoProcessing: 'Video is being processed.'
  }
}

window.FolioConsole.File.ProcessingNotifier.handleFile = (notifier, data) => {
  if (data.attributes.human_type !== 'audio' && data.attributes.human_type !== 'video') return

  const alerts = document.querySelectorAll(`.f-c-flash-wrap .alert[data-file-id="${data.id}"]`)
  let existingStateAlert

  for (const alert of alerts) {
    if (alert.dataset.fileState === data.attributes.aasm_state) {
      existingStateAlert = alert
      break
    }
  }

  if (existingStateAlert) return

  for (const alert of alerts) {
    alert.parentElement.removeChild(alert)
  }

  if (data.attributes.aasm_state === 'ready') {
    const msg = window.Folio.i18n(window.FolioConsole.File.ProcessingNotifier.i18n, `${data.attributes.human_type}Done`)
    window.FolioConsole.Flash.success(msg, false, { fileId: data.id, fileState: data.attributes.aasm_state })
  } else {
    let msg = window.Folio.i18n(window.FolioConsole.File.ProcessingNotifier.i18n, `${data.attributes.human_type}Processing`)

    if (notifier.dataset.pendingAppend) {
      msg += ` ${notifier.dataset.pendingAppend}`
    }

    window.FolioConsole.Flash.pending(msg, false, { fileId: data.id, fileState: data.attributes.aasm_state })
  }
}

window.Folio.MessageBus.callbacks['window.FolioConsole.File.ProcessingNotifier'] = (data) => {
  if (!data || data.type !== 'Folio::ApplicationJob/file_update') return

  const notifiers = document.querySelectorAll(`.f-c-file-processing-notifier[data-file-id="${data.data.id}"]`)

  for (const notifier of notifiers) {
    window.FolioConsole.File.ProcessingNotifier.handleFile(notifier, data.data)
  }
}

window.Folio.Stimulus.register('f-c-file-processing-notifier', class extends window.Stimulus.Controller {
  connect () {
    window.FolioConsole.File.ProcessingNotifier.handleFile(this.element, JSON.parse(this.element.dataset.file))
  }
})

//= require dropzone-6-0-0-beta-1

window.Folio = window.Folio || {}
window.Folio.S3Upload = {}

window.Folio.S3Upload.newUpload = ({ file }) => {
  return window.Folio.Api.apiPost('/folio/api/s3/before', { file_name: file.name })
}

window.Folio.S3Upload.finishedUpload = ({ s3_path, type, existingId }) => {
  return window.Folio.Api.apiPost('/folio/api/s3/after', { s3_path, type, existing_id: existingId })
}

window.Folio.S3Upload.previousDropzoneId = 0

window.Folio.S3Upload.consolePreviewTemplate = () => `
  <div class="f-c-r-dropzone__preview">
    <img data-dz-thumbnail class="f-c-r-dropzone__preview-thumbnail" />
    <div class="f-c-r-dropzone__preview-progress">
      <span class="f-c-r-dropzone__preview-progress-inner" data-dz-uploadprogress></span>
      <span class="f-c-r-dropzone__preview-progress-text"></span>
    </div>
  </div>
`

window.Folio.S3Upload.createDropzone = ({
  dropzoneOptions,
  element,
  fileType,
  filterMessageBusMessages,
  onStart,
  onProgress,
  onSuccess,
  onFailure,
  onThumbnail,
  folioConsole,
  dontRemoveFileOnSuccess,
  hidden
}) => {
  if (!fileType) throw new Error('Missing fileType')
  if (!element) throw new Error('Missing element')

  const dropzoneId = window.Folio.S3Upload.previousDropzoneId += 1

  const options = {
    url: '#',
    method: 'PUT',
    paramName: 'file',
    previewsContainer: null,
    clickable: true,
    thumbnailMethod: 'contain',
    thumbnailWidth: 150,
    thumbnailHeight: 150,
    timeout: 0,
    parallelUploads: 1,
    maxFilesize: 5120,
    autoProcessQueue: false,

    sending: function (file, xhr) {
      const _send = xhr.send
      xhr.send = () => { _send.call(xhr, file) }
    },

    accept: function (file, done) {
      const dropzone = this

      window.Folio.S3Upload.newUpload({ file })
        .then((result) => {
          file.file_name = result.file_name
          file.s3_path = result.s3_path
          file.s3_url = result.s3_url

          if (onThumbnail && file.dataURL && !file.thumbnail_notified) {
            file.thumbnail_notified = true
            onThumbnail(file.s3_path, file.dataURL)
          }

          if (onStart) onStart(file.s3_path, { file_name: result.file_name, file_size: file.size })

          done()

          setTimeout(() => dropzone.processFile(file), 0)
        })
        .catch((err) => {
          done('Failed to get an S3 signed upload URL', err)
        })
    },

    success: function (file) {
      window.Folio.S3Upload.finishedUpload({
        s3_path: file.s3_path,
        type: fileType
      })
    },

    error: function (file, message) {
      if (window.FolioConsole && window.FolioConsole.Flash) {
        if (typeof message === "string") {
          window.FolioConsole.Flash.alert(message)
        } else {
          window.FolioConsole.Flash.flashMessageFromApiErrors(message)
        }
      }

      const dropzone = this

      setTimeout(() => { dropzone.removeFile(file) }, 0)

      if (onFailure) onFailure(file.s3_path)
    },

    processing: function (file) {
      this.options.url = file.s3_url
    },

    uploadprogress: function (file, progress, _bytesSent) {
      const rounded = Math.round(progress)

      if (onProgress) onProgress(file.s3_path, rounded)

      if (folioConsole && file.previewElement) {
        file
          .previewElement
          .querySelector('.f-c-r-file-upload-progress__slider, .f-c-r-dropzone__preview-progress-inner')
          .style.width = `${rounded}%`

        file
          .previewElement
          .querySelector('.f-c-r-file-upload-progress__inner, .f-c-r-dropzone__preview-progress-text')
          .innerText = rounded === 100 ? window.FolioConsole.translations.finalizing : `${rounded}%`
      }
    },

    thumbnail: function (file, dataUrl) {
      if (onThumbnail) {
        if (file.s3_path) {
          file.thumbnail_notified = true
          onThumbnail(file.s3_path, dataUrl)
        }
      }
    },

    ...(dropzoneOptions || {})
  }

  if (document.documentElement.lang === "cs") {
    options.dictFileTooBig = "Soubor je přiliš veliký ({{filesize}}MiB). Maximální velikost: {{maxFilesize}}MiB."
    options.dictInvalidFileType = "Soubory tohoto typu nejsou povoleny."
  }

  const dropzone = new window.Dropzone(element, options)
  dropzone.dropzoneId = dropzoneId

  filterMessageBusMessages = filterMessageBusMessages || ((msg) => {
    const s3Path = msg && msg.data && msg.data.s3_path

    if (!s3Path) return false

    let isFromThisDropzone = false

    dropzone.files.forEach((file) => {
      if (file.s3_path === s3Path) {
        isFromThisDropzone = true
      }
    })

    return isFromThisDropzone
  })

  window.Folio.MessageBus.callbacks[`Folio::CreateFileFromS3Job-dropzone-${dropzoneId}`] = (msg) => {
    if (!msg) return
    if (msg.type !== 'Folio::CreateFileFromS3Job') return
    if (msg.data.file_type !== fileType) return
    if (!filterMessageBusMessages(msg)) return

    switch (msg.data.type) {
      case 'start':
        return dropzone.files.forEach((file) => {
          if (file.s3_path === msg.data.s3_path) {
            file.s3_job_started_at = new Date()
          }
        })
      case 'success': {
        if (!dontRemoveFileOnSuccess) {
          dropzone.files.forEach((file) => {
            if (file.s3_path === msg.data.s3_path) {
              setTimeout(() => { dropzone.removeFile(file) }, 0)
            }
          })
        }

        if (onSuccess) onSuccess(msg.data.s3_path, msg.data.file)

        return
      }
      case 'failure': {
        if (msg.data.errors && msg.data.errors.length) {
          if (window.FolioConsole && window.FolioConsole.Flash) {
            window.FolioConsole.Flash.alert(msg.data.errors.join('<br>'))
          } else {
            window.alert(msg.data.errors.join('\n'))
          }
        }

        dropzone.files.forEach((file) => {
          if (file.s3_path === msg.data.s3_path) {
            setTimeout(() => { dropzone.removeFile(file) }, 0)
          }
        })

        if (onFailure) onFailure(msg.data.s3_path)
      }
    }
  }

  return dropzone
}

window.Folio.S3Upload.createConsoleDropzone = (opts) => {
  const options = {
    ...opts,
    folioConsole: true,
    dropzoneOptions: {
      ...opts.dropzoneOptions,
      previewTemplate: window.Folio.S3Upload.consolePreviewTemplate()
    }
  }

  return window.Folio.S3Upload.createDropzone(options)
}

window.Folio.S3Upload.createHiddenDropzone = (opts) => {
  const options = {
    ...opts,
    hidden: true,
    dropzoneOptions: {
      ...opts.dropzoneOptions,
      disablePreviews: true,
      previewsContainer: false
    }
  }

  return window.Folio.S3Upload.createDropzone(options)
}

window.Folio.S3Upload.destroyDropzone = (dropzone) => {
  delete window.Folio.MessageBus.callbacks[`Folio::CreateFileFromS3Job-dropzone-${dropzone.dropzoneId}`]
  dropzone.destroy()
}

window.Folio.S3Upload.triggerDropzone = (dropzone) => {
  dropzone.hiddenFileInput.click()
}

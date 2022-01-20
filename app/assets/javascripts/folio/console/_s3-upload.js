window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.S3Upload = {}

window.FolioConsole.S3Upload.newUpload = ({ filesUrl, file }) => {
  return window.FolioConsole.Api.apiPost(`${filesUrl}/s3_before`, { file_name: file.name })
}

window.FolioConsole.S3Upload.finishedUpload = ({ filesUrl, s3_path, type }) => {
  return window.FolioConsole.Api.apiPost(`${filesUrl}/s3_after`, { s3_path, type })
}

window.FolioConsole.S3Upload.previousDropzoneId = 0

window.FolioConsole.S3Upload.consolePreviewTemplate = () => `
  <div class="dz-preview dz-file-preview">
    <div class="dz-details">
      <div class="dz-filename"><span data-dz-name></span></div>
      <div class="dz-size" data-dz-size></div>
      <img data-dz-thumbnail />
    </div>
    <div class="dz-progress"><span class="dz-upload" data-dz-uploadprogress></span></div>
    <div class="dz-success-mark"><span>✔</span></div>
    <div class="dz-error-mark"><span>✘</span></div>
    <div class="dz-error-message"><span data-dz-errormessage></span></div>
  </div>
`

window.FolioConsole.S3Upload.createConsoleDropzone = ({
  dropzoneOptions,
  element,
  filesUrl,
  fileType,
  onStart,
  onProgress,
  onSuccess,
  onFailure,
  onThumbnail,
}) => {
  if (!filesUrl) throw "Missing filesUrl"
  if (!fileType) throw "Missing fileType"
  if (!element) throw "Missing element"

  const dropzoneId = window.FolioConsole.S3Upload.previousDropzoneId += 1
  const uniqueDropzoneClassName = `f-c-r-dropzone--${dropzoneId}`

  const options = {
    url: "#",
    method: 'PUT',
    paramName: 'file',
    previewsContainer: `.${uniqueDropzoneClassName} .f-c-r-dropzone__previews`,
    previewTemplate: window.FolioConsole.S3Upload.consolePreviewTemplate(),
    clickable: `.${uniqueDropzoneClassName} .f-c-r-dropzone__trigger`,
    thumbnailMethod: 'contain',
    thumbnailWidth: 150,
    thumbnailHeight: 150,
    timeout: 0,
    parallelUploads: 1,
    maxFilesize: 4096,
    autoProcessQueue: false,

    sending: function (file, xhr) {
      const _send = xhr.send
      xhr.send = () => { _send.call(xhr, file) }
    },

    accept: function (file, done) {
      const dropzone = this

      window.FolioConsole.S3Upload.newUpload({ filesUrl, file })
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
      window.FolioConsole.S3Upload.finishedUpload({
        filesUrl,
        s3_path: file.s3_path,
        type: fileType
      })
    },

    error: function (file, message) {
      window.FolioConsole.Flash.flashMessageFromApiErrors(message)
      if (onFailure) onFailure(file.s3_path)
    },

    processing: function (file) {
      this.options.url = file.s3_url
    },

    uploadprogress: function (file, progress, _bytesSent) {
      const rounded = Math.round(progress)

      if (onProgress) onProgress(file.s3_path, rounded)

      if (file.previewElement) {
        file
          .previewElement
          .querySelector('.f-c-r-file-upload-progress__slider')
          .style['width'] = `${rounded}%`

        file
          .previewElement
          .querySelector('.f-c-r-file-upload-progress__inner')
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

    ...(dropzoneOptions || {}),
  }

  element.classList.add(uniqueDropzoneClassName)
  const dropzone = new Dropzone(element, options)
  dropzone.dropzoneId = dropzoneId

  window.Folio.MessageBus.callbacks[`Folio::CreateFileFromS3Job-dropzone-${dropzoneId}`] = (msg) => {
    if (!msg || msg.type !== 'Folio::CreateFileFromS3Job') return

    switch (msg.data.type) {
      case 'start':
        return dropzone.files.forEach((file) => {
          if (file.s3_path === msg.data.s3_path) {
            file.s3_job_started_at = new Date()
          }
        })
      case 'success': {
        dropzone.files.forEach((file) => {
          if (file.s3_path === msg.data.s3_path) {
            setTimeout(() => { dropzone.removeFile(file) }, 0)
          }
        })

        if (onSuccess) onSuccess(msg.data.s3_path, msg.data.file)

        return
      }
      case 'failure': {
        if (msg.data.errors && msg.data.errors.length) {
          window.FolioConsole.Flash.alert(msg.data.errors.join('<br>'))
        }

        dropzone.files.forEach((file) => {
          if (file.s3_path === msg.data.s3_path) {
            setTimeout(() => { dropzone.removeFile(file) }, 0)
          }
        })

        if (onFailure) onFailure(msg.data.s3_path)

        return
      }
      default:
    }
  }

  return dropzone
}

window.FolioConsole.S3Upload.destroyDropzone = (dropzone) => {
  delete window.Folio.MessageBus.callbacks[`Folio::CreateFileFromS3Job-dropzone-${dropzone.dropzoneId}`]
  dropzone.destroy()
}

window.FolioConsole.S3Upload.triggerDropzone = (dropzone) => {
  dropzone.hiddenFileInput.click()
}

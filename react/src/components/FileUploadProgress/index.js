import React from 'react'

const FileUploadProgress = ({ progress, progressText }) => {
  if (typeof progress === 'undefined') return null

  let message

  if (progressText) {
    message = progressText
  } else if (progress === 100) {
    message = window.Folio.i18n(window.Folio.S3Upload.i18n, 'finalizing')
  } else {
    message = `${progress || 0}%`
  }

  return (
    <span className='f-c-r-file-upload-progress'>
      <span
        className='f-c-r-file-upload-progress__slider'
        style={{ width: `${progress || 0}%` }}
      />

      <div className='f-c-r-file-upload-progress__inner'>
        {message}
      </div>
    </span>
  )
}

export default FileUploadProgress

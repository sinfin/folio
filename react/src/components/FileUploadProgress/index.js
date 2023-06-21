import React from 'react'

const FileUploadProgress = ({ progress }) => {
  if (typeof progress === 'undefined') return null

  let message

  if (progress === 100) {
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

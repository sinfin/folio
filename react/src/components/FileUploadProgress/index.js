import React from 'react'

const FileUploadProgress = ({ progress }) => {
  if (typeof progress === 'undefined') return null

  let message

  if (progress === 100) {
    message = `${window.FolioConsole.translations.finalizing}…`
  } else {
    message = `${progress || 0}%`
  }

  return (
    <span className='folio-console-file-upload-progress'>
      <span
        className='folio-console-file-upload-progress__slider'
        style={{ width: `${progress || 0}%` }}
      />

      <div className='folio-console-file-upload-progress__inner'>
        {message}
      </div>
    </span>
  )
}

export default FileUploadProgress

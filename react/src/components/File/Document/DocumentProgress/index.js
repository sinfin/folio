import React from 'react'

const Progress = ({ progress }) => {
  if (typeof progress === 'undefined') return null

  let message

  if (progress === 100)  {
    message = `${window.FolioConsole.translations.finalizing}…`
  } else {
    message = `${progress || 0}%`
  }

  return (
    <span className="folio-console-file-table__upload-progress">
      <span
        className="folio-console-file-table__upload-progress-slider"
        style={{ width: `${progress || 0}%` }}
      />

      <span className="folio-console-file-table__upload-progress-inner">
        {message}
      </span>
    </span>
  )
}

export default Progress

import React from 'react'

const FileTableHeader = ({ fileTypeIsImage, massSelect }) => {
  const className = 'f-c-file-table__tr f-c-file-table__tr--header'

  return (
    <div className={className}>
      {massSelect && (
        <div className='f-c-file-table__td f-c-file-table__td--mass-select pl-0' />
      )}

      {fileTypeIsImage ? (
        <div className='f-c-file-table__td f-c-file-table__td--image py-0' />
      ) : (
        <div className='f-c-file-table__td f-c-file-table__td--extension'>
          {window.FolioConsole.translations.fileTableHeaderType}
        </div>
      )}

      <div className='f-c-file-table__td f-c-file-table__td--main'>
        {window.FolioConsole.translations.fileTableHeaderFileName}
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--size'>
        {window.FolioConsole.translations.fileTableHeaderFileSize}
      </div>

      {massSelect && <div className='f-c-file-table__td f-c-file-table__td--extension' />}

      <div className='f-c-file-table__td f-c-file-table__td--tags'>
        {window.FolioConsole.translations.fileTableHeaderTags}
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--actions' />
    </div>
  )
}

export default FileTableHeader

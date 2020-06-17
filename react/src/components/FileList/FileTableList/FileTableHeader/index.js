import React from 'react'

const FileTableHeader = ({ fileTypeIsImage, massSelect }) => {
  const className = 'f-c-file-table__tr f-c-file-table__tr--header'

  return (
    <div className={className}>
      {massSelect && (
        <div className='f-c-file-table__td f-c-file-table__td--mass-select pl-0' />
      )}

      {fileTypeIsImage ? (
        <div className='f-c-file-table__td f-c-file-table__td--image py-0'>
          img
        </div>
      ) : (
        <div className='f-c-file-table__td f-c-file-table__td--extension'>
          Typ
        </div>
      )}

      <div className='f-c-file-table__td f-c-file-table__td--main'>
        Nazev souboru
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--size'>
        Velikost
      </div>

      {massSelect && <div className='f-c-file-table__td f-c-file-table__td--extension' />}

      <div className='f-c-file-table__td f-c-file-table__td--tags'>
        Klicova slova
      </div>

      <div className='f-c-file-table__td f-c-file-table__td--actions pr-0' />
    </div>
  )
}

export default FileTableHeader

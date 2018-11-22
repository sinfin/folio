import React from 'react'

const FileThumbnailHover = ({ onClick, progress, file }) => {
  if (!onClick || typeof progress !== 'undefined') return null

  return (
    <div className='folio-console-file-list__file-hover' onClick={() => onClick(file)}>
      <i className='fa fa-check-circle'></i>
    </div>
  )
}

export default FileThumbnailHover

import React from 'react'

const FileThumbnailHover = ({ onClick, progress, file, selecting }) => {
  if (!onClick || !selecting || typeof progress !== 'undefined') return null

  const icon = selecting === 'multiple' ? 'fa fa-arrow-circle-up' : 'fa fa-check-circle'

  return (
    <div className='folio-console-file-list__file-hover' onClick={() => onClick(file)}>
      <i className={icon} />
    </div>
  )
}

export default FileThumbnailHover

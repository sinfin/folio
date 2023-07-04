import React from 'react'

import FolioUiIcon from 'components/FolioUiIcon'

const FileThumbnailHover = ({ onClick, progress, file, selecting }) => {
  if (!onClick || !selecting || typeof progress !== 'undefined') return null

  const iconName = selecting === 'multiple' ? 'arrow_up' : 'check_circle_outline'

  return (
    <div className='f-c-file-list__file-hover' onClick={() => onClick(file)}>
      <FolioUiIcon name={iconName} />
    </div>
  )
}

export default FileThumbnailHover

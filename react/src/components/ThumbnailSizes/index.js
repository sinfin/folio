import React from 'react'

import ThumbnailSize from './ThumbnailSize'

function ThumbnailSizes ({ file, updateThumbnail, destroyThumbnail }) {
  const thumbnailSizes = file.attributes.thumbnail_sizes
  if (!thumbnailSizes) return null
  const keys = Object.keys(thumbnailSizes).sort()
  if (keys.length === 0) return null

  return (
    <React.Fragment>
      <h4 className='mt-0'>{window.FolioConsole.translations.thumbnailSizes}</h4>

      <div className='d-flex flex-wrap'>
        {keys.map((key) => (
          <ThumbnailSize
            key={key}
            thumbKey={key}
            thumb={thumbnailSizes[key]}
            file={file}
            updateThumbnail={updateThumbnail}
            destroyThumbnail={destroyThumbnail}
          />
        ))}
      </div>
    </React.Fragment>
  )
}

export default ThumbnailSizes

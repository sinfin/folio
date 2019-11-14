import React from 'react'
import LazyLoad from 'react-lazyload'

import FileUploadProgress from 'components/FileUploadProgress'
import FileThumbnailHover from './FileThumbnailHover'

const FileThumbnail = ({ file, link, overflowingParent, onClick, selecting }) => {
  const Tag = link ? 'a' : 'div'
  let className = 'folio-console-file-list__file'
  const persistedOnClick = !file.attributes.uploading && onClick

  if (file.attributes.freshlyUploaded) {
    className = 'folio-console-file-list__file folio-console-file-list__file--fresh'
  } else if (file.attributes.uploading) {
    className = 'folio-console-file-list__file folio-console-file-list__file--uploading'
  }

  return (
    <Tag
      href={(link && file.links) ? file.links.edit : undefined}
      className={className}
    >
      <div className='folio-console-file-list__img-wrap' style={{ background: file.attributes.dominant_color }}>
        {file.attributes.thumb && (
          <LazyLoad height={150} once overflow={overflowingParent}>
            <img
              src={file.attributes.thumb}
              className='folio-console-file-list__img'
              alt={file.attributes.file_name}
            />
          </LazyLoad>
        )}
      </div>

      <FileUploadProgress progress={file.attributes.progress} />
      <FileThumbnailHover
        progress={file.attributes.progress}
        onClick={persistedOnClick}
        file={file}
        selecting={selecting}
      />
    </Tag>
  )
}

export default FileThumbnail

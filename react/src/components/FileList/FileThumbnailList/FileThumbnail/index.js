import React from 'react'
import LazyLoad from 'react-lazyload'

import FileUploadProgress from 'components/FileUploadProgress';

const FileThumbnail = ({ file, link }) => {
  const Tag = link ? 'a' : 'div'

  return (
    <Tag href={link ? file.edit_path : undefined} className='folio-console-file-list__file'>
      <div className='folio-console-file-list__img-wrap' style={{ background: file.dominant_color }}>
        {file.thumb && (
          <LazyLoad height={150} once overflow={false}>
            <img
              src={file.thumb}
              className='folio-console-file-list__img'
              alt={file.file_name}
            />
          </LazyLoad>
        )}
      </div>
      <FileUploadProgress progress={file.progress} />
    </Tag>
  )
}

export default FileThumbnail

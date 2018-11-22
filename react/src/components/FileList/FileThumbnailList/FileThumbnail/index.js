import React from 'react'
import LazyLoad from 'react-lazyload'

import FileUploadProgress from 'components/FileUploadProgress';
import FileThumbnailHover from './FileThumbnailHover';

const FileThumbnail = ({ file, link, overflowingParent, onClick }) => {
  const Tag = link ? 'a' : 'div'

  return (
    <Tag
      href={link ? file.edit_path : undefined}
      className='folio-console-file-list__file'
    >
      <div className='folio-console-file-list__img-wrap' style={{ background: file.dominant_color }}>
        {file.thumb && (
          <LazyLoad height={150} once overflow={overflowingParent}>
            <img
              src={file.thumb}
              className='folio-console-file-list__img'
              alt={file.file_name}
            />
          </LazyLoad>
        )}
      </div>

      <FileUploadProgress progress={file.progress} />
      <FileThumbnailHover progress={file.progress} onClick={onClick} file={file} />
    </Tag>
  )
}

export default FileThumbnail

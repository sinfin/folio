import React from 'react'
import LazyLoad from 'react-lazyload'

import FileUploadProgress from 'components/FileUploadProgress'
import FileThumbnailHover from './FileThumbnailHover'
import FileThumbnailMassCheckbox from './FileThumbnailMassCheckbox'

const FileThumbnail = ({ file, link, onClick, selecting, massSelect, massSelectVisible }) => {
  const Tag = link ? 'a' : 'div'
  let className = 'f-c-file-list__file'
  const persistedOnClick = !file.attributes.uploading && onClick

  if (file.attributes.freshlyUploaded) {
    className = 'f-c-file-list__file f-c-file-list__file--fresh'
  } else if (file.attributes.uploading) {
    className = 'f-c-file-list__file f-c-file-list__file--uploading'
  }

  return (
    <Tag
      href={(link && file.links) ? file.links.edit : undefined}
      className={className}
    >
      <div className='f-c-file-list__img-wrap' style={{ background: file.attributes.dominant_color }}>
        {file.attributes.thumb && (
          <LazyLoad height={150} once overflow>
            <img
              src={file.attributes.thumb}
              className='f-c-file-list__img'
              alt={file.attributes.file_name}
            />
          </LazyLoad>
        )}
      </div>

      <FileUploadProgress progress={file.attributes.progress} />
      {massSelect ? (
        <React.Fragment>
          <FileThumbnailMassCheckbox
            select={massSelect}
            visible={massSelectVisible}
            file={file}
          />

          {file.attributes.file_placements_count ? (
            <div className='f-c-file-list__file-placements-count'>
              {file.attributes.file_placements_count}
            </div>
          ) : null}
        </React.Fragment>
      ) : (
        <FileThumbnailHover
          progress={file.attributes.progress}
          onClick={persistedOnClick}
          file={file}
          selecting={selecting}
        />
      )}
    </Tag>
  )
}

export default FileThumbnail

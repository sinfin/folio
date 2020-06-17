import React from 'react'

import DropzoneTrigger from './DropzoneTrigger'
import FileThumbnail from './FileThumbnail'

const FileThumbnailList = ({
  fileType,
  files,
  dropzoneTrigger,
  openFileModal,
  onClick,
  openFileModalOnClick,
  selecting,
  massSelect,
  massSelectVisible
}) => (
  <div className='f-c-file-list'>
    {dropzoneTrigger && <DropzoneTrigger />}

    {files.map((file) => (
      <FileThumbnail
        key={file.id}
        fileType={fileType}
        file={file}
        openFileModal={openFileModal}
        onClick={onClick}
        openFileModalOnClick={openFileModalOnClick}
        selecting={selecting}
        massSelect={massSelect}
        massSelectVisible={massSelectVisible}
      />
    ))}
  </div>
)

export default FileThumbnailList

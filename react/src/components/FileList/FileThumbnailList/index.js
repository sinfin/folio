import React from 'react'

import DropzoneTrigger from './DropzoneTrigger'
import FileThumbnail from './FileThumbnail'

const FileThumbnailList = ({
  filesKey,
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
        filesKey={filesKey}
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

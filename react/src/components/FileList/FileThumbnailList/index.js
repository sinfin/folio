import React from 'react'

import DropzoneTrigger from './DropzoneTrigger'
import FileThumbnail from './FileThumbnail'

const FileThumbnailList = ({
  files,
  dropzoneTrigger,
  link,
  onClick,
  selecting,
  massSelect,
  massSelectVisible
}) => (
  <div className='f-c-file-list'>
    {dropzoneTrigger && <DropzoneTrigger />}

    {files.map((file) => (
      <FileThumbnail
        key={file.id}
        file={file}
        link={link}
        onClick={onClick}
        selecting={selecting}
        massSelect={massSelect}
        massSelectVisible={massSelectVisible}
      />
    ))}
  </div>
)

export default FileThumbnailList

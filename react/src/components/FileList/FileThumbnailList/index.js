import React from 'react'

import DropzoneTrigger from './DropzoneTrigger';
import FileThumbnail from './FileThumbnail';

const FileThumbnailList = ({ files, dropzoneTrigger, link, overflowingParent, onClick, selecting }) => (
  <div className="folio-console-file-list">
    {dropzoneTrigger  && <DropzoneTrigger />}

    {files.map((file) => (
      <FileThumbnail
        key={file.id}
        file={file}
        link={link}
        overflowingParent={overflowingParent}
        onClick={onClick}
        selecting={selecting}
      />
    ))}
  </div>
)

export default FileThumbnailList

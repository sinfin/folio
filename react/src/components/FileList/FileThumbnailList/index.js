import React from 'react'

import DropzoneTrigger from './DropzoneTrigger';
import FileThumbnail from './FileThumbnail';

const FileThumbnailList = ({ files, dropzoneTrigger, link }) => (
  <div className="folio-console-file-list">
    {dropzoneTrigger  && <DropzoneTrigger />}

    {files.map(({ key, ...file }) => (
      <FileThumbnail
        key={key}
        link={link}
        {...file}
      />
    ))}
  </div>
)

export default FileThumbnailList

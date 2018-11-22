import React from 'react'

import { DropzoneTrigger } from 'components/File';

const FileThumbnailList = ({ files, dropzoneTrigger }) => (
  <div className="folio-console-file-list">
    {dropzoneTrigger  && <DropzoneTrigger />}

    {files.map(({ Component, files }) => {
      return files.map(({ key, ...file }) => (
        <Component key={key} {...file} />
      ))
    })}
  </div>
)

export default FileThumbnailList

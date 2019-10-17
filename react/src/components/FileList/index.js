import React from 'react'
import { forceCheck } from 'react-lazyload'

import Pagination from 'components/Pagination'

import FileTableList from './FileTableList'
import FileThumbnailList from './FileThumbnailList'

const FileList = (props) => {
  setTimeout(forceCheck, 0)

  return (
    <React.Fragment>
      {(props.fileTypeIsImage && props.displayAsThumbs) ? FileThumbnailList(props) : FileTableList(props)}
      <Pagination pagination={props.pagination} changeFilesPage={props.changeFilesPage} />
    </React.Fragment>
  )
}

export default FileList

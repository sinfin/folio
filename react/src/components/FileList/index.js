import React from 'react'
import { forceCheck } from 'react-lazyload'

import Pagination from 'components/Pagination'

import FileTableList from './FileTableList'
import FileThumbnailList from './FileThumbnailList'

const FileList = (props) => {
  setTimeout(forceCheck, 0)

  const pagination = (
    <Pagination
      pagination={props.pagination}
      changeFilesPage={props.changeFilesPage}
      fileTypeIsImage={props.fileTypeIsImage}
    />
  )

  return (
    <React.Fragment>
      {pagination}
      {(props.fileTypeIsImage && props.displayAsThumbs) ? FileThumbnailList(props) : FileTableList(props)}
      {pagination}
    </React.Fragment>
  )
}

export default FileList

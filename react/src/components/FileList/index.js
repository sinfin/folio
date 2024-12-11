import React from 'react'

import Pagination from 'components/Pagination'

import FileTableList from './FileTableList'
import FileThumbnailList from './FileThumbnailList'

const FileList = (props) => {
  const pagination = (
    <Pagination
      pagination={props.pagination}
      changePage={props.changeFilesPage}
      fileTypeIsImage={props.fileTypeIsImage}
    />
  )

  const displayAsThumbs = props.fileTypeIsImage && props.displayAsThumbs

  return (
    <React.Fragment>
      {pagination}
      {displayAsThumbs ? <FileThumbnailList {...props} /> : <FileTableList {...props} />}
      {pagination}
    </React.Fragment>
  )
}

export default FileList

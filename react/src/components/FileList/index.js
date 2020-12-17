import React from 'react'
import FileTableList from './FileTableList'
import FileThumbnailList from './FileThumbnailList'

import Pagination from 'components/Pagination'

const FileList = (props) => {
  const pagination = (
    <Pagination
      pagination={props.pagination}
      changePage={props.changeFilesPage}
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

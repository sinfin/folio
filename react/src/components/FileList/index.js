import { forceCheck } from 'react-lazyload'

import FileTableList from './FileTableList'
import FileThumbnailList from './FileThumbnailList'

const FileList = (props) => {
  setTimeout(forceCheck, 0)
  if (props.fileTypeIsImage && props.displayAsThumbs) {
    return FileThumbnailList(props)
  } else {
    return FileTableList(props)
  }
}

export default FileList

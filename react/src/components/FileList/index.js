import FileTableList from './FileTableList'
import FileThumbnailList from './FileThumbnailList'

const FileList = (props) => {
  if (props.fileTypeIsImage && props.displayAsThumbs) {
    return FileThumbnailList(props)
  } else {
    return FileTableList(props)
  }
}

export default FileList

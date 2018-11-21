import DocumentList from './DocumentList'
import ImageList from './ImageList'

const FileList = (props) => props.fileTypeIsImage ? ImageList(props) : DocumentList(props)

export default FileList

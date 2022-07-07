import React, { Component } from 'react'
import { connect } from 'react-redux'

import Loader from 'components/Loader'

import {
  showTagger,
  addDropzoneFile,
  updateDropzoneFile,
  removeDropzoneFile,
  thumbnailDropzoneFile,
  makeUploadsSelector
} from 'ducks/uploads'

import { uploadedFile } from 'ducks/files'

const date = new Date()
let month = date.getMonth() + 1
if (month < 10) month = `0${month}`

export const UploaderContext = React.createContext(() => {})

class Uploader extends Component {
  constructor (props) {
    super(props)
    this.dropzoneDivRef = React.createRef()
  }

  triggerFileInput = () => {
    window.FolioConsole.S3Upload.triggerDropzone(this.dropzone)
  }

  componentDidMount () {
    this.dropzone = window.FolioConsole.S3Upload.createConsoleDropzone({
      element: this.dropzoneDivRef.current,
      filesUrl: this.props.filesUrl,
      fileType: this.props.fileType,
      onStart: (s3Path, fileAttributes) => {
        this.props.dispatch(addDropzoneFile(this.props.fileType, s3Path, fileAttributes))
      },
      onSuccess: (s3Path, fileFromApi) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        this.props.dispatch(removeDropzoneFile(this.props.fileType, s3Path))
        this.props.dispatch(uploadedFile(this.props.fileType, fileFromApi))
        this.props.dispatch(showTagger(this.props.fileType, fileFromApi.id))
      },
      onFailure: (s3Path) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        this.props.dispatch(removeDropzoneFile(this.props.fileType, s3Path))
      },
      onProgress: (s3Path, progress) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        this.props.dispatch(updateDropzoneFile(this.props.fileType, s3Path, { progress }))
      },
      onThumbnail: (s3Path, dataThumbnail) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        this.props.dispatch(thumbnailDropzoneFile(this.props.fileType, s3Path, dataThumbnail))
      },
      dropzoneOptions: {
        clickable: true,
        previewsContainer: false,
        previewTemplate: '',
        disablePreviews: true
      }
    })
  }

  componentWillUnmount () {
    window.FolioConsole.S3Upload.destroyDropzone(this.dropzone)
    this.dropzone = null
  }

  render () {
    const { fileType } = this.props
    if (!fileType) return <Loader />

    return (
      <UploaderContext.Provider value={this.triggerFileInput}>
        <div className='f-c-r-dropzone' ref={this.dropzoneDivRef}>
          {this.props.children}
        </div>
      </UploaderContext.Provider>
    )
  }
}

const mapStateToProps = (state, props) => ({
  uploads: props.fileType ? makeUploadsSelector(props.fileType)(state) : null
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Uploader)

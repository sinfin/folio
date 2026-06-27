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

const SUCCESS_REMOVAL_DELAY = 600
const FAILURE_REMOVAL_DELAY = 6000

export const UploaderContext = React.createContext(() => {})

class Uploader extends Component {
  constructor (props) {
    super(props)
    this.dropzoneDivRef = React.createRef()
    this.uploadStateRemovalTimers = []
  }

  triggerFileInput = () => {
    window.Folio.S3Upload.triggerDropzone(this.dropzone)
  }

  scheduleUploadStateRemoval = (delay, callback) => {
    const timer = window.setTimeout(() => {
      this.uploadStateRemovalTimers = this.uploadStateRemovalTimers.filter((candidate) => candidate !== timer)
      callback()
    }, delay)

    this.uploadStateRemovalTimers.push(timer)
  }

  componentDidMount () {
    this.dropzone = window.Folio.S3Upload.createConsoleDropzone({
      element: this.dropzoneDivRef.current,
      filesUrl: this.props.filesUrl,
      fileType: this.props.fileType,
      fileHumanType: this.props.reactType,
      onStart: (s3Path, fileAttributes) => {
        this.props.dispatch(addDropzoneFile(this.props.fileType, s3Path, fileAttributes))
      },
      onS3UploadSuccess: (s3Path, attributes) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        this.props.dispatch(updateDropzoneFile(this.props.fileType, s3Path, attributes))
      },
      onProcessingStart: (s3Path, attributes) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        this.props.dispatch(updateDropzoneFile(this.props.fileType, s3Path, attributes))
      },
      onSuccess: (s3Path, fileFromApi, attributes) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        if (attributes) {
          this.props.dispatch(updateDropzoneFile(this.props.fileType, s3Path, attributes))
        }

        this.scheduleUploadStateRemoval(SUCCESS_REMOVAL_DELAY, () => {
          this.props.dispatch(removeDropzoneFile(this.props.fileType, s3Path))
          this.props.dispatch(uploadedFile(this.props.fileType, fileFromApi))
          this.props.dispatch(showTagger(this.props.fileType, fileFromApi.id))
        })
      },
      onFailure: (s3Path, _message, attributes) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        if (attributes) {
          this.props.dispatch(updateDropzoneFile(this.props.fileType, s3Path, attributes))
        }

        this.scheduleUploadStateRemoval(FAILURE_REMOVAL_DELAY, () => {
          this.props.dispatch(removeDropzoneFile(this.props.fileType, s3Path))
        })
      },
      onProgress: (s3Path, progress, progressText) => {
        if (!this.props.uploads.dropzoneFiles[s3Path]) return

        this.props.dispatch(updateDropzoneFile(this.props.fileType, s3Path, { progress, progressText }))
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
      },
      filterMessageBusMessages: (msg) => {
        if (msg && msg.data && msg.data.s3_path && this.props.uploads && this.props.uploads.dropzoneFiles[msg.data.s3_path]) {
          return true
        } else {
          return false
        }
      }
    })
  }

  componentWillUnmount () {
    this.uploadStateRemovalTimers.forEach((timer) => window.clearTimeout(timer))
    this.uploadStateRemovalTimers = []

    window.Folio.S3Upload.destroyDropzone(this.dropzone)
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

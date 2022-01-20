import React, { Component } from 'react'
import { connect } from 'react-redux'

import Loader from 'components/Loader'
import { showTagger } from 'ducks/uploads'
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
        console.log('start', s3Path, fileAttributes)
      },
      onSuccess: (s3Path, fileFromApi) => {
        console.log('success', s3Path)
        this.props.dispatch(showTagger(this.props.fileType, fileFromApi.id))
        this.props.dispatch(uploadedFile(this.props.fileType, fileFromApi))
      },
      onFailure: (s3Path) => {
        console.log('failure', s3Path)
      },
      onProgress: (s3Path, progress) => {
        console.log('progress', progress, s3Path)
      },
      dropzoneOptions: {
        clickable: true,
        previewsContainer: false,
        previewTemplate: ''
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
        <div className='f-c-r-dropzone' ref={this.dropzoneDivRef} />

        {this.props.children}
      </UploaderContext.Provider>
    )
  }
}

const mapStateToProps = (state, props) => ({})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Uploader)

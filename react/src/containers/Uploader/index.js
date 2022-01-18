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
      onSuccess: (fileFromApi) => {
        this.props.dispatch(showTagger(this.props.fileType, fileFromApi.id))
        this.props.dispatch(uploadedFile(this.props.fileType, fileFromApi))
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
          <div className='f-c-r-dropzone__previews dropzone-previews' />
          <div className='f-c-r-dropzone__trigger' />

          {this.props.children}
        </div>
      </UploaderContext.Provider>
    )
  }
}

const mapStateToProps = (state, props) => ({})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Uploader)

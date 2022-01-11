import React, { Component } from 'react'
import { connect } from 'react-redux'
import DropzoneComponent from 'react-dropzone-component'
import styled from 'styled-components'
import { uniqueId } from 'lodash'

import { CSRF } from 'utils/api'

import Loader from 'components/Loader'
import {
  addedFile,
  thumbnail,
  success,
  error,
  progress,
  makeUploadsSelector
} from 'ducks/uploads'

import { HIDDEN_DROPZONE_TRIGGER_CLASSNAME } from './constants'

const date = new Date()
let month = date.getMonth() + 1
if (month < 10) month = `0${month}`

const StyledDropzone = styled(DropzoneComponent)`
  .dz-default.dz-message {
    display: none;
  }

  .${HIDDEN_DROPZONE_TRIGGER_CLASSNAME} {
    position: absolute;
    visibility: hidden;
    width: 0;
    height: 0;
  }
`

export const UploaderContext = React.createContext(() => {})

class Uploader extends Component {
  state = { uploaderClassName: uniqueId('folio-console-uploader-') }

  dropzone = null

  eventHandlers () {
    const { dispatch, fileType } = this.props

    return {
      addedfile: (file) => dispatch(addedFile(fileType, file, this.dropzone)),
      thumbnail: (file, dataUrl) => dispatch(thumbnail(fileType, file, dataUrl)),
      success: (file, response) => dispatch(success(fileType, file, response)),
      error: (file, message) => {
        window.FolioConsole.Flash.flashMessageFromApiErrors(message)
        dispatch(error(fileType, file))
      },
      uploadprogress: (file, percentage) => dispatch(progress(fileType, file, Math.round(percentage))),
      init: (dropzone) => { this.dropzone = dropzone }
    }
  }

  config () {
    return {
      iconFiletypes: ['.jpg', '.png', '.gif'],
      showFiletypeIcon: false,
      postUrl: this.props.filesUrl
    }
  }

  djsConfig () {
    const params = {}
    params['file[type]'] = this.props.fileType
    params['file[attributes][type]'] = this.props.fileType
    params['file[attributes][tag_list]'] = this.props.uploads.uploadAttributes.tags.join(',')

    return {
      headers: CSRF,
      method: 'PUT',
      paramName: 'file[attributes][file]',
      previewTemplate: '<span></span>',
      clickable: `.${this.state.uploaderClassName} .${HIDDEN_DROPZONE_TRIGGER_CLASSNAME}`,
      thumbnailMethod: 'contain',
      thumbnailWidth: 150,
      thumbnailHeight: 150,
      timeout: 0,
      parallelUploads: 25,
      maxFilesize: 4096,
      autoProcessQueue: false,
      params
    }
  }

  triggerFileInput = () => {
    this.dropzone.hiddenFileInput.click()
  }

  componentWillUnmount () {
    this.dropzone = null
  }

  render () {
    const { fileType } = this.props
    if (!fileType) return <Loader />

    return (
      <UploaderContext.Provider value={this.triggerFileInput}>
        <StyledDropzone
          config={this.config()}
          djsConfig={this.djsConfig()}
          eventHandlers={this.eventHandlers()}
          className={this.state.uploaderClassName}
        >
          {this.props.children}
          <span className={HIDDEN_DROPZONE_TRIGGER_CLASSNAME} />
        </StyledDropzone>
      </UploaderContext.Provider>
    )
  }
}

const mapStateToProps = (state, props) => ({
  uploads: makeUploadsSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Uploader)

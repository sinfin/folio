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
  uploadsSelector,
} from 'ducks/uploads'
import { fileTypeSelector } from 'ducks/app'

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
    const { dispatch } = this.props

    return {
      addedfile: (file) => dispatch(addedFile(file)),
      thumbnail: (file, dataUrl) => dispatch(thumbnail(file, dataUrl)),
      success: (file, response) => dispatch(success(file, response.file)),
      error: (file, message) => {
        const flash = (typeof message === 'object') ? message.error : message
        dispatch(error(file, flash))
      },
      uploadprogress: (file, percentage) => dispatch(progress(file, Math.round(percentage))),
      init: (dropzone) => this.dropzone = dropzone
    }
  }

  config () {
    return {
      iconFiletypes: ['.jpg', '.png', '.gif'],
      showFiletypeIcon: false,
      postUrl: this.props.fileType === 'Folio::Document' ? '/console/documents' : '/console/images',
    }
  }

  djsConfig () {
    return {
      headers: CSRF,
      paramName: 'file[file][]',
      previewTemplate: '<span></span>',
      clickable: `.${this.state.uploaderClassName} .${HIDDEN_DROPZONE_TRIGGER_CLASSNAME}`,
      thumbnailMethod: 'contain',
      thumbnailWidth: 150,
      thumbnailHeight: 150,
      params: {
        'file[type]': this.props.fileType,
        'file[tag_list]': this.props.uploads.uploadTags.join(','),
      }
    }
  }

  triggerFileInput = () => {
    this.dropzone.hiddenFileInput.click()
  }

  componentWillUnmount() {
    this.dropzone = null
  }

  render() {
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

const mapStateToProps = (state) => ({
  fileType: fileTypeSelector(state),
  uploads: uploadsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Uploader)

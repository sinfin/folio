import React, { Component } from 'react'
import { connect } from 'react-redux'
import DropzoneComponent from 'react-dropzone-component'
import styled from 'styled-components'
import { uniqueId } from 'lodash'

import { CSRF } from 'utils/api'
import { flashMessageFromApiErrors } from 'utils/flash'

import Loader from 'components/Loader'
import {
  addedFile,
  thumbnail,
  success,
  error,
  progress,
  makeUploadsSelector
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
    const { dispatch, filesKey } = this.props

    return {
      addedfile: (file) => dispatch(addedFile(filesKey, file)),
      thumbnail: (file, dataUrl) => dispatch(thumbnail(filesKey, file, dataUrl)),
      success: (file, response) => dispatch(success(filesKey, file, response)),
      error: (file, message) => {
        dispatch(error(filesKey, file, flashMessageFromApiErrors(message)))
      },
      uploadprogress: (file, percentage) => dispatch(progress(filesKey, file, Math.round(percentage))),
      init: (dropzone) => { this.dropzone = dropzone }
    }
  }

  config () {
    return {
      iconFiletypes: ['.jpg', '.png', '.gif'],
      showFiletypeIcon: false,
      postUrl: this.props.fileType === 'Folio::Document' ? '/console/api/documents' : '/console/api/images'
    }
  }

  djsConfig () {
    const params = {}
    params['file[type]'] = this.props.fileType
    params['file[attributes][type]'] = this.props.fileType
    params['file[attributes][tag_list]'] = this.props.uploads.uploadTags.join(',')

    return {
      headers: CSRF,
      paramName: 'file[attributes][file]',
      previewTemplate: '<span></span>',
      clickable: `.${this.state.uploaderClassName} .${HIDDEN_DROPZONE_TRIGGER_CLASSNAME}`,
      thumbnailMethod: 'contain',
      thumbnailWidth: 150,
      thumbnailHeight: 150,
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
  fileType: fileTypeSelector(state),
  uploads: makeUploadsSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Uploader)

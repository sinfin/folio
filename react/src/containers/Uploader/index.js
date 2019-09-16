import React, { Component } from 'react'
import { connect } from 'react-redux'
import DropzoneComponent from 'react-dropzone-component'
import styled from 'styled-components'
import { uniqueId } from 'lodash'

import { CSRF } from 'utils/api'
import { flashMessageFromApiErrors } from 'utils/flash'
import fileKeyToType from 'utils/fileKeyToType'

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
      postUrl: `/console/api/${this.props.filesKey}`
    }
  }

  djsConfig () {
    const params = {}
    const fileType = fileKeyToType(this.props.filesKey)
    params['file[type]'] = fileType
    params['file[attributes][type]'] = fileType
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
    const { filesKey } = this.props
    if (!filesKey) return <Loader />

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
  uploads: makeUploadsSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Uploader)

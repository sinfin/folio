import React, { Component } from 'react'
import { connect } from 'react-redux'
import DropzoneComponent from 'react-dropzone-component'
import styled from 'styled-components'
import { uniqueId } from 'lodash';

import { CSRF } from 'utils/api'

import { UploadingFile, DropzoneTrigger } from 'components/File'
import Loader from 'components/Loader'
import {
  addedFile,
  thumbnail,
  success,
  error,
  uploadsSelector,
} from 'ducks/uploads'
import { fileTypeSelector } from 'ducks/app'

const date = new Date()
let month = date.getMonth() + 1
if (month < 10) month = `0${month}`
const DATE_TAG = [date.getFullYear(), month].join('/')

const StyledDropzone = styled(DropzoneComponent)`
  .dz-default.dz-message {
    display: none;
  }
`

class Uploader extends Component {
  state = { uploaderClassName: uniqueId('folio-console-uploader-') }

  eventHandlers () {
    const { dispatch } = this.props

    return {
      addedfile: (file) => dispatch(addedFile(file)),
      thumbnail: (file, dataUrl) => dispatch(thumbnail(file, dataUrl)),
      success: (file, response) => dispatch(success(file, response.file)),
      error: (file, message) => dispatch(error(file, message)),
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
      clickable: `.${this.state.uploaderClassName} .folio-console-dropzone-trigger`,
      params: {
        'file[type]': this.props.fileType,
        'file[tag_list]': DATE_TAG,
      }
    }
  }

  render() {
    const { fileType } = this.props
    if (!fileType) return <Loader />

    return (
      <StyledDropzone
        config={this.config()}
        djsConfig={this.djsConfig()}
        eventHandlers={this.eventHandlers()}
        className={this.state.uploaderClassName}
      >
        {this.props.showUploading && <DropzoneTrigger />}
        {this.props.showUploading && (
          this.props.uploads.records.map((upload, index) => (
            <UploadingFile
              upload={upload}
              key={upload.id}
            />
          ))
        )}
        {this.props.children}
      </StyledDropzone>
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

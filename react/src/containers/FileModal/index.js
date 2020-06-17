import React, { Component } from 'react'
import { connect } from 'react-redux'

import ReactModal from 'react-modal'

import { updateFile, deleteFile } from 'ducks/files'
import {
  updateFileThumbnail,
  closeFileModal,
  fileModalSelector,
  uploadNewFileInstead,
  markModalFileAsUpdating
} from 'ducks/fileModal'

import { makeTagsSelector } from 'ducks/filters'

import FileModalFile from './FileModalFile'

ReactModal.setAppElement('body')

class Modal extends Component {
  state = {}

  constructor (props) {
    super(props)
    if (props.fileModal.file) {
      this.state = {
        author: props.fileModal.file.attributes.author,
        description: props.fileModal.file.attributes.description,
        tags: props.fileModal.file.attributes.tags
      }
    } else {
      this.state = { author: null, description: null, tags: [] }
    }
  }

  componentDidUpdate (prevProps) {
    if (this.props.fileModal.file) {
      if (!prevProps.fileModal.file || (prevProps.fileModal.updating && this.props.fileModal.updating === false)) {
        this.setState({
          ...this.state,
          author: this.props.fileModal.file.attributes.author,
          description: this.props.fileModal.file.attributes.description,
          tags: this.props.fileModal.file.attributes.tags
        })
      }
    }
  }

  saveModal = () => {
    const { fileModal } = this.props

    this.props.dispatch(markModalFileAsUpdating(fileModal.file))
    this.props.dispatch(updateFile(this.props.fileType, fileModal.file, this.state))
  }

  closeFileModal = () => {
    this.props.dispatch(closeFileModal())
  }

  updateThumbnail = (thumbKey, params) => {
    this.props.dispatch(updateFileThumbnail(this.props.fileType, this.props.fileModal.file, thumbKey, params))
  }

  deleteFile = (file) => {
    this.closeFileModal()
    this.props.dispatch(deleteFile(this.props.fileType, file))
  }

  uploadNewFileInstead = (fileIo) => {
    this.props.dispatch(uploadNewFileInstead(this.props.fileType, this.props.fileModal.file, fileIo))
  }

  onTagsChange = (tags) => {
    this.setState({ ...this.state, tags })
  }

  onValueChange = (key, value) => {
    this.setState({ ...this.state, [key]: value })
  }

  render () {
    const { fileModal, tags } = this.props
    const isOpen = fileModal.file !== null

    return (
      <ReactModal
        isOpen={isOpen}
        onRequestClose={this.closeFileModal}
        className='ReactModal'
      >
        {fileModal.file && (
          <FileModalFile
            fileModal={fileModal}
            onTagsChange={this.onTagsChange}
            saveModal={this.saveModal}
            closeFileModal={this.closeFileModal}
            updateThumbnail={this.updateThumbnail}
            deleteFile={this.deleteFile}
            uploadNewFileInstead={this.uploadNewFileInstead}
            onValueChange={this.onValueChange}
            tags={tags}
            formState={this.state}
          />
        )}
      </ReactModal>
    )
  }
}

const mapStateToProps = (state, props) => ({
  fileModal: fileModalSelector(state),
  tags: makeTagsSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Modal)

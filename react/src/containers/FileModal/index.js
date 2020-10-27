import React, { Component } from 'react'
import { connect } from 'react-redux'

import ReactModal from 'react-modal'

import { updateFile, deleteFile } from 'ducks/files'
import {
  updateFileThumbnail,
  closeFileModal,
  fileModalSelector,
  uploadNewFileInstead,
  markModalFileAsUpdating,
  changeFilePlacementsPage
} from 'ducks/fileModal'

import FileModalFile from './FileModalFile'

ReactModal.setAppElement('body')

class FileModal extends Component {
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
    this.props.dispatch(updateFile(this.props.fileModal.fileType, this.props.fileModal.filesUrl, fileModal.file, this.state))
  }

  closeFileModal = () => {
    this.props.dispatch(closeFileModal())
  }

  updateThumbnail = (thumbKey, params) => {
    this.props.dispatch(updateFileThumbnail(this.props.fileModal.fileType,
      this.props.fileModal.filesUrl,
      this.props.fileModal.file,
      thumbKey,
      params))
  }

  deleteFile = (file) => {
    this.closeFileModal()
    this.props.dispatch(deleteFile(this.props.fileModal.fileType, this.props.fileModal.filesUrl, file))
  }

  uploadNewFileInstead = (fileIo) => {
    this.props.dispatch(uploadNewFileInstead(this.props.fileModal.fileType, this.props.fileModal.filesUrl, this.props.fileModal.file, fileIo))
  }

  changeFilePlacementsPage = (page) => {
    this.props.dispatch(changeFilePlacementsPage(this.props.fileModal.file, page))
  }

  onTagsChange = (tags) => {
    this.setState({ ...this.state, tags })
  }

  onValueChange = (key, value) => {
    this.setState({ ...this.state, [key]: value })
  }

  render () {
    const { fileModal, readOnly } = this.props
    const isOpen = fileModal.file !== null

    return (
      <ReactModal
        isOpen={isOpen}
        onRequestClose={this.closeFileModal}
        className='ReactModal ReactModal--FileModal'
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
            formState={this.state}
            changeFilePlacementsPage={this.changeFilePlacementsPage}
            readOnly={readOnly}
          />
        )}
      </ReactModal>
    )
  }
}

const mapStateToProps = (state, props) => ({
  fileModal: fileModalSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileModal)

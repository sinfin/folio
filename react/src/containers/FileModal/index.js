import React, { Component } from 'react'
import { connect } from 'react-redux'
import { uniqueId } from 'lodash'

import ReactModal from 'react-modal'

import { updateFile, deleteFile, updatedFiles } from 'ducks/files'
import {
  updateFileThumbnail,
  destroyFileThumbnail,
  closeFileModal,
  fileModalSelector,
  uploadNewFileInstead,
  uploadNewFileInsteadSuccess,
  uploadNewFileInsteadFailure,
  updatedFileModalFile,
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
        default_gravity: props.fileModal.file.attributes.default_gravity,
        description: props.fileModal.file.attributes.description,
        preview_duration: props.fileModal.file.attributes.preview_duration,
        sensitive_content: props.fileModal.file.attributes.sensitive_content,
        tags: props.fileModal.file.attributes.tags
      }
    } else {
      this.state = {
        author: null,
        default_gravity: '',
        description: null,
        preview_duration: 30,
        sensitive_content: false,
        tags: []
      }
    }
  }

  componentDidMount () {
    this.listenOnMessageBus()
  }

  componentWillUnmount () {
    this.stopListeningOnMessageBus()
  }

  componentDidUpdate (prevProps) {
    if (this.props.fileModal.file) {
      if (!prevProps.fileModal.file || (prevProps.fileModal.updating && this.props.fileModal.updating === false)) {
        this.setState({
          ...this.state,
          author: this.props.fileModal.file.attributes.author,
          default_gravity: this.props.fileModal.file.attributes.default_gravity,
          description: this.props.fileModal.file.attributes.description,
          preview_duration: this.props.fileModal.file.attributes.preview_duration,
          sensitive_content: this.props.fileModal.file.attributes.sensitive_content,
          tags: this.props.fileModal.file.attributes.tags
        })
      }
    }
  }

  listenOnMessageBus () {
    if (!window.Folio.MessageBus.callbacks) return

    this.messageBusCallbackKey = `Folio::GenerateThumbnailJob-react-files-app-file-modal-${uniqueId()}`

    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (msg) => {
      if (!msg) return
      if (!this.props.fileModal.file) return

      if (msg.type === 'Folio::CreateFileFromS3Job' && msg.data.file) {
        if (Number(msg.data.file.id) === Number(this.props.fileModal.file.id)) {
          if (msg.data.type === 'replace-success') {
            this.props.dispatch(updatedFileModalFile(msg.data.file))
            this.props.dispatch(updatedFiles(this.props.fileModal.fileType, [msg.data.file]))
            this.props.dispatch(uploadNewFileInsteadSuccess(msg.data.file))
          } else if (msg.data.type === 'replace-failure') {
            window.FolioConsole.Flash.alert(msg.data.errors.join('<br>'))
            this.props.dispatch(uploadNewFileInsteadFailure(this.props.fileModal.file))
          }
        }
      }
    }
  }

  stopListeningOnMessageBus () {
    delete window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]
    this.messageBusCallbackKey = null
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

  destroyThumbnail = (thumbKey, thumb) => {
    this.props.dispatch(destroyFileThumbnail(
      this.props.fileModal.fileType,
      this.props.fileModal.filesUrl,
      this.props.fileModal.file,
      thumbKey,
      thumb
    ))
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
    const { fileModal, readOnly, canDestroyFiles, taggable } = this.props
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
            taggable={taggable}
            onTagsChange={this.onTagsChange}
            saveModal={this.saveModal}
            closeFileModal={this.closeFileModal}
            updateThumbnail={this.updateThumbnail}
            destroyThumbnail={this.destroyThumbnail}
            canDestroyFiles={canDestroyFiles}
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

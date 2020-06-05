import React, { Component } from 'react'
import { connect } from 'react-redux'

import ReactModal from 'react-modal'

import { updateFile } from 'ducks/files'

import {
  closeFileModal,
  changeFileModalTags,
  fileModalSelector
} from 'ducks/fileModal'

import { makeTagsSelector } from 'ducks/filters'

import FileModalFile from './FileModalFile'

ReactModal.setAppElement('body')

class Modal extends Component {
  onTagsChange = (tags) => {
    this.props.dispatch(changeFileModalTags(tags))
  }

  saveModal = () => {
    const { fileModal } = this.props

    const attributes = {
      tags: fileModal.newTags || []
    }
    this.props.dispatch(updateFile(this.props.filesKey, fileModal.file, attributes))
    this.props.dispatch(closeFileModal())
  }

  closeFileModal = () => {
    this.props.dispatch(closeFileModal())
  }

  render () {
    const { fileModal, tags } = this.props
    const isOpen = fileModal.file !== null && (fileModal.loading || fileModal.loaded)

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
            tags={tags}
          />
        )}
      </ReactModal>
    )
  }
}

const mapStateToProps = (state, props) => ({
  fileModal: fileModalSelector(state),
  tags: makeTagsSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Modal)

import React, { Component } from 'react'
import { connect } from 'react-redux'

import ReactModal from 'react-modal'

import { updateFile } from 'ducks/files'

import {
  closeModal,
  changeModalTags,
  modalSelector
} from 'ducks/modal'

import { makeTagsSelector } from 'ducks/filters'

import ModalFile from './ModalFile'

ReactModal.setAppElement('body')

class Modal extends Component {
  closeModal = () => {
    this.props.dispatch(closeModal())
  }

  onTagsChange = (tags) => {
    this.props.dispatch(changeModalTags(tags))
  }

  saveModal = () => {
    const { modal } = this.props

    const attributes = {
      tags: modal.newTags || []
    }
    this.props.dispatch(updateFile(this.props.filesKey, modal.file, attributes))
    this.props.dispatch(closeModal())
  }

  closeModal = () => {
    this.props.dispatch(closeModal())
  }

  render () {
    const { modal, tags } = this.props

    return (
      <ReactModal
        isOpen={modal.file !== null}
        onRequestClose={this.closeModal}
        className='ReactModal'
      >
        {modal.file && (
          <ModalFile
            modal={modal}
            onTagsChange={this.onTagsChange}
            saveModal={this.saveModal}
            closeModal={this.closeModal}
            tags={tags}
          />
        )}
      </ReactModal>
    )
  }
}

const mapStateToProps = (state, props) => ({
  modal: modalSelector(state),
  tags: makeTagsSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Modal)

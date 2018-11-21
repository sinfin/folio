import React, { Component } from 'react'
import { connect } from 'react-redux'

import ReactModal from 'react-modal'

import { updateFile } from 'ducks/files';

import {
  cancelModal,
  changeModalTags,
  modalSelector,
} from 'ducks/modal';

import { tagsSelector } from 'ducks/filters'

import ModalFile from './ModalFile';

export const ModalContext = React.createContext(() => {})

ReactModal.setAppElement('body')

class Modal extends Component {
  cancelModal = () => {
    this.props.dispatch(cancelModal())
  }

  onTagsChange = (tags) => {
    this.props.dispatch(changeModalTags(tags))
  }

  saveModal = () => {
    const { modal } = this.props

    const attributes = {
      tags: modal.newTags,
    }
    this.props.dispatch(updateFile(modal.file, attributes))
    this.props.dispatch(cancelModal())
  }

  cancelModal = () => {
    this.props.dispatch(cancelModal())
  }

  render() {
    const { modal, tags } = this.props

    return (
      <ReactModal
        isOpen={modal.file !== null}
        onRequestClose={this.cancelModal}
        className='ReactModal'
      >
        {modal.file && (
          <ModalFile
            modal={modal}
            onTagsChange={this.onTagsChange}
            saveModal={this.saveModal}
            cancelModal={this.cancelModal}
            tags={tags}
          />
        )}
      </ReactModal>
    )
  }
}

const mapStateToProps = (state) => ({
  modal: modalSelector(state),
  tags: tagsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Modal)

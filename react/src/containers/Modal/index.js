import React, { Component } from 'react'
import { connect } from 'react-redux'

import ReactModal from 'react-modal'

import {
  openModal,
  saveModal,
  cancelModal,
  changeModalTags,
  modalSelector,
} from 'ducks/modal';

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

  render() {
    const { modal } = this.props

    return (
      <ReactModal
        isOpen={modal.file !== null}
        onRequestClose={this.cancelModal}
        className='ReactModal'
      >
        {modal.file && <ModalFile modal={modal} onTagsChange={this.onTagsChange} />}
      </ReactModal>
    )
  }
}

const mapStateToProps = (state) => ({
  modal: modalSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Modal)

import React, { Component } from 'react'
import { connect } from 'react-redux'
import { uniqueId } from 'lodash'

import { getFiles, messageBusFileUpdated, makeFilesLoadedSelector, uploadedFile } from 'ducks/files'
import { openFileModal } from 'ducks/fileModal'

import SingleSelect from 'containers/SingleSelect'
import MultiSelect from 'containers/MultiSelect'
import IndexMode from 'containers/IndexMode'
import ModalSingleSelect from 'containers/ModalSingleSelect'
import FileModal from 'containers/FileModal'
import Atoms from 'containers/Atoms'

import FilesAppWrap from './styled/FilesAppWrap'

class FilesApp extends Component {
  componentDidMount () {
    if (this.shouldAutoLoadFiles()) {
      this.loadFiles(this.props.app.fileType, this.props.app.filesUrl)
    }
    this.listenOnMessageBus()
  }

  componentWillUnmount () {
    if (this.messageBusCallbackKey && window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]) {
      delete window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]
      this.messageBusCallbackKey = null
    }
  }

  loadFiles = (fileType, filesUrl) => {
    if (!this.props.filesLoaded) {
      this.props.dispatch(getFiles(fileType, filesUrl))
    }
  }

  listenOnMessageBus () {
    if (!window.Folio.MessageBus.callbacks) return

    this.messageBusCallbackKey = `folio-react/FilesApp--${uniqueId()}`

    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (message) => {
      if (!message) return

      if (message.type === 'Folio::ApplicationJob/file_update') {
        this.props.dispatch(messageBusFileUpdated(
          this.props.app.fileType,
          this.props.app.filesUrl,
          message.data
        ))
      } else if (message.type === 'Folio::File/created') {
        const file = message.data

        if (this.props.app.fileType === file.attributes.type) {
          this.props.dispatch(uploadedFile(this.props.app.fileType, file))
        }
      }
    }
  }

  shouldAutoLoadFiles () {
    return this.props.app.mode !== 'modal-single-select' && this.props.app.mode !== 'atoms'
  }

  openFileModal = (fileType, filesUrl, file, autoFocusField) => {
    this.props.dispatch(openFileModal(fileType, filesUrl, file, autoFocusField))
  }

  renderMode () {
    const { mode, fileType, filesUrl, readOnly, reactType, taggable } = this.props.app

    if (mode === 'multi-select') {
      return <MultiSelect fileType={fileType} filesUrl={filesUrl} taggable={taggable} reactType={reactType} />
    }

    if (mode === 'single-select') {
      return <SingleSelect fileType={fileType} filesUrl={filesUrl} taggable={taggable} reactType={reactType} />
    }

    if (mode === 'index') {
      return <IndexMode fileType={fileType} filesUrl={filesUrl} readOnly={readOnly} taggable={taggable} reactType={reactType} />
    }

    if (mode === 'modal-single-select') {
      return (
        <ModalSingleSelect
          fileType={fileType}
          filesUrl={filesUrl}
          taggable={taggable}
          reactType={reactType}
          loadFiles={this.loadFiles}
          openFileModal={this.openFileModal}
        />
      )
    }

    if (mode === 'atoms') {
      return (
        <Atoms />
      )
    }

    return (
      <div className='alert alert-danger'>
        Unknown mode: {mode}
      </div>
    )
  }

  render () {
    return (
      <FilesAppWrap className='folio-react-app'>
        {this.renderMode()}

        <FileModal
          readOnly={this.props.app.readOnly}
          taggable={this.props.app.taggable}
          canDestroyFiles={this.props.app.canDestroyFiles}
        />
      </FilesAppWrap>
    )
  }
}

const mapStateToProps = (state, props) => ({
  app: state.app,
  filesLoaded: makeFilesLoadedSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FilesApp)

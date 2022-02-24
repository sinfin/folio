import React, { Component } from 'react'
import { connect } from 'react-redux'
import { forceCheck } from 'react-lazyload'
import { uniqueId } from 'lodash'

import { getFiles, messageBusThumbnailGenerated, makeFilesLoadedSelector } from 'ducks/files'
import { openFileModal } from 'ducks/fileModal'

import SingleSelect from 'containers/SingleSelect'
import MultiSelect from 'containers/MultiSelect'
import IndexMode from 'containers/IndexMode'
import ModalSingleSelect from 'containers/ModalSelect/ModalSingleSelect'
import FileModal from 'containers/FileModal'
import Atoms from 'containers/Atoms'

import FilesAppWrap from './styled/FilesAppWrap'

class FilesApp extends Component {
  componentWillMount () {
    if (this.shouldAutoLoadFiles()) {
      this.loadFiles(this.props.app.fileType, this.props.app.filesUrl)
    }
    this.listenOnMessageBus()
    window.addEventListener('checkLazyload', forceCheck)
  }

  loadFiles = (fileType, filesUrl) => {
    if (!this.props.filesLoaded) {
      this.props.dispatch(getFiles(fileType, filesUrl))
    }
  }

  listenOnMessageBus () {
    if (!window.Folio.MessageBus.callbacks) return

    this.messageBusCallbackKey = `Folio::GenerateThumbnailJob-react-files-app-${uniqueId()}`

    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (data) => {
      if (!data || data.type !== 'Folio::GenerateThumbnailJob') return
      if (!data.data.temporary_url || !data.data.url) return
      this.props.dispatch(messageBusThumbnailGenerated(
        this.props.app.fileType,
        this.props.app.filesUrl,
        data.data
      ))
    }
  }

  shouldAutoLoadFiles () {
    return this.props.app.mode !== 'modal-single-select' && this.props.app.mode !== 'atoms'
  }

  openFileModal = (fileType, filesUrl, file) => {
    this.props.dispatch(openFileModal(fileType, filesUrl, file))
  }

  renderMode () {
    const { mode, fileType, filesUrl, readOnly, reactType } = this.props.app

    if (mode === 'multi-select') {
      return <MultiSelect fileType={fileType} filesUrl={filesUrl} />
    }

    if (mode === 'single-select') {
      return <SingleSelect fileType={fileType} filesUrl={filesUrl} />
    }

    if (mode === 'index') {
      return <IndexMode fileType={fileType} filesUrl={filesUrl} readOnly={readOnly} />
    }

    if (mode === 'modal-single-select') {
      return (
        <ModalSingleSelect
          fileType={fileType}
          filesUrl={filesUrl}
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

        <FileModal readOnly={this.props.app.readOnly} />
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
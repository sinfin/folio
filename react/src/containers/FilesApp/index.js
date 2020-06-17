import React, { Component } from 'react'
import { connect } from 'react-redux'
import { forceCheck } from 'react-lazyload'

import { getFiles, thumbnailGenerated, makeFilesLoadedSelector } from 'ducks/files'
import { openFileModal } from 'ducks/fileModal'

import SingleSelect from 'containers/SingleSelect'
import MultiSelect from 'containers/MultiSelect'
import IndexMode from 'containers/IndexMode'
import ModalSingleSelect from 'containers/ModalSelect/ModalSingleSelect'
import ModalMultiSelect from 'containers/ModalSelect/ModalMultiSelect'
import FileModal from 'containers/FileModal'
import Atoms from 'containers/Atoms'

import FilesAppWrap from './styled/FilesAppWrap'

class FilesApp extends Component {
  componentWillMount () {
    if (this.shouldAutoLoadFiles()) {
      this.loadFiles(this.props.app.fileType, this.props.app.filesUrl)
    }
    this.listenOnActionCable()
    window.addEventListener('checkLazyload', forceCheck)
  }

  loadFiles = (fileType, filesUrl) => {
    if (!this.props.filesLoaded) {
      this.props.dispatch(getFiles(fileType, filesUrl))
    }
  }

  listenOnActionCable () {
    if (!window.FolioCable) return
    this.cableSubscription = window.FolioCable.cable.subscriptions.create('FolioThumbnailsChannel', {
      received: (data) => {
        if (!data) return
        if (!data.temporary_url || !data.url) return
        this.props.dispatch(thumbnailGenerated('images', data.temporary_url, data.url))
      }
    })
  }

  shouldAutoLoadFiles () {
    return this.props.app.mode !== 'modal-single-select' && this.props.app.mode !== 'modal-multi-select' && this.props.app.mode !== 'atoms'
  }

  openFileModal = (filesKey, file) => {
    this.props.dispatch(openFileModal(filesKey, file))
  }

  renderMode () {
    const { mode, fileType, filesKey, filesUrl } = this.props.app

    if (mode === 'multi-select') {
      return <MultiSelect filesKey={filesKey} />
    }

    if (mode === 'single-select') {
      return <SingleSelect filesKey={filesKey} />
    }

    if (mode === 'index') {
      return <IndexMode filesKey={filesKey} filesUrl={filesUrl} />
    }

    if (mode === 'modal-single-select') {
      return (
        <ModalSingleSelect
          fileType={fileType}
          filesKey={filesKey}
          loadFiles={this.loadFiles}
          openFileModal={this.openFileModal}
        />
      )
    }

    if (mode === 'modal-multi-select') {
      return (
        <ModalMultiSelect
          fileType={fileType}
          filesKey={filesKey}
          loadFiles={this.loadFiles}
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

        <FileModal filesKey={this.props.app.filesKey} />
      </FilesAppWrap>
    )
  }
}

const mapStateToProps = (state, props) => ({
  app: state.app,
  filesLoaded: makeFilesLoadedSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FilesApp)

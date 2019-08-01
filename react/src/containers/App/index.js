import React, { Component } from 'react'
import { connect } from 'react-redux'
import { forceCheck } from 'react-lazyload'

import { getFiles, thumbnailGenerated, filesLoadedSelector } from 'ducks/files'
import { openModal } from 'ducks/modal'

import SingleSelect from 'containers/SingleSelect'
import MultiSelect from 'containers/MultiSelect'
import IndexMode from 'containers/IndexMode'
import ModalSingleSelect from 'containers/ModalSelect/ModalSingleSelect'
import ModalMultiSelect from 'containers/ModalSelect/ModalMultiSelect'
import Modal, { ModalContext } from 'containers/Modal'
import Atoms from 'containers/Atoms'

import AppWrap from './styled/AppWrap'

class App extends Component {
  componentWillMount () {
    if (this.shouldAutoLoadFiles()) {
      this.loadFiles()
    }
    this.listenOnActionCable()
    window.addEventListener('checkLazyload', forceCheck)
  }

  loadFiles = () => {
    if (!this.props.filesLoaded) {
      this.props.dispatch(getFiles())
    }
  }

  openModal = (file) => {
    this.props.dispatch(openModal(file))
  }

  listenOnActionCable () {
    if (!window.FolioCable) return
    this.cableSubscription = window.FolioCable.cable.subscriptions.create('FolioThumbnailsChannel', {
      received: (data) => {
        if (!data) return
        if (!data.temporary_url || !data.url) return
        this.props.dispatch(thumbnailGenerated(data.temporary_url, data.url))
      }
    })
  }

  shouldAutoLoadFiles () {
    return this.props.app.mode !== 'modal-single-select' && this.props.app.mode !== 'modal-multi-select' && this.props.app.mode !== 'atoms'
  }

  renderMode () {
    const { mode, fileType } = this.props.app

    if (mode === 'multi-select') {
      return <MultiSelect />
    }

    if (mode === 'single-select') {
      return <SingleSelect />
    }

    if (mode === 'index') {
      return <IndexMode />
    }

    if (mode === 'modal-single-select') {
      return (
        <ModalSingleSelect
          fileType={fileType}
          loadFiles={this.loadFiles}
        />
      )
    }

    if (mode === 'modal-multi-select') {
      return (
        <ModalMultiSelect
          fileType={fileType}
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
      <AppWrap className='folio-react-app'>
        <ModalContext.Provider value={this.openModal}>
          {this.renderMode()}
        </ModalContext.Provider>

        <Modal />
      </AppWrap>
    )
  }
}

const mapStateToProps = (state) => ({
  app: state.app,
  filesLoaded: filesLoadedSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(App)

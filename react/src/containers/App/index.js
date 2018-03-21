import React, { Component } from 'react'
import { connect } from 'react-redux'
import { forceCheck } from 'react-lazyload'

import { getFiles, thumbnailGenerated } from 'ducks/files'

import SingleSelect from 'containers/SingleSelect'
import MultiSelect from 'containers/MultiSelect'
import IndexMode from 'containers/IndexMode'
import ModalSelect from 'containers/ModalSelect'

import AppWrap from './AppWrap'

class App extends Component {
  componentWillMount () {
    this.props.dispatch(getFiles())
    this.listenOnActionCable()
    window.addEventListener('checkLazyload', forceCheck)
  }

  listenOnActionCable () {
    if (!window.FolioCable) return
    this.cableSubscription = window.FolioCable.cable.subscriptions.create('FolioThumbnailsChannel', {
      received: (data) => {
        if (!data) return
        const { temporary_url, url } = data
        if (!temporary_url || !url) return
        this.props.dispatch(thumbnailGenerated(temporary_url, url))
      }
    })
  }

  renderMode () {
    const { mode } = this.props.app

    if (mode === 'multi-select') {
      return <MultiSelect />
    }

    if (mode === 'single-select') {
      return <SingleSelect />
    }

    if (mode === 'index') {
      return <IndexMode />
    }

    if (mode === 'modal-select') {
      return <ModalSelect />
    }

    return (
      <div className='alert alert-danger'>
        Unknown mode: {mode}
      </div>
    )
  }

  render () {
    return <AppWrap>{this.renderMode()}</AppWrap>
  }
}

const mapStateToProps = (state) => ({
  app: state.get('app').toJS()
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(App)

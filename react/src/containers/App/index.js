import React, { Component } from 'react'
import { connect } from 'react-redux'

import { getImages } from 'ducks/images'
import Loader from 'components/Loader'

import AppWrap from './AppWrap'
import './index.css'

class App extends Component {
  componentWillMount () {
    this.props.dispatch(getImages())
  }

  renderContent () {
    const { images } = this.props
    if (images.loading) return <Loader />

    return (
      <div>
        {images.records.map((image) => (
          <img src={image.thumb} key={image.id} />
        ))}
      </div>
    )
  }

  render() {
    return <AppWrap>{this.renderContent()}</AppWrap>
  }
}

const mapStateToProps = (state) => ({
  images: state.get('images').toJS()
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(App)

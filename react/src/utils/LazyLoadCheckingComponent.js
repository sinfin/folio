import { Component } from 'react'
import { forceCheck } from 'react-lazyload'

class LazyLoadCheckingComponent extends Component {
  componentDidUpdate (pastProps) {
    if (pastProps.filesForList.length !== this.props.filesForList.length) {
      forceCheck()
    }
  }
}

export default LazyLoadCheckingComponent

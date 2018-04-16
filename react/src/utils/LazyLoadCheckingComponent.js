import { Component } from 'react'
import { forceCheck } from 'react-lazyload'

class LazyLoadCheckingComponent extends Component {
  componentDidUpdate (pastProps) {
    if (pastProps.files.selectable.length !== this.props.files.selectable.length) {
      forceCheck()
    }
  }
}

export default LazyLoadCheckingComponent

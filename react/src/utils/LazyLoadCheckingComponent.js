import { Component } from 'react'
import { forceCheck } from 'react-lazyload'

class LazyLoadCheckingComponent extends Component {
  componentDidUpdate (pastProps) {
    if (pastProps.filesForList[1].files.length !== this.props.filesForList[1].files.length) {
      forceCheck()
    }
  }
}

export default LazyLoadCheckingComponent

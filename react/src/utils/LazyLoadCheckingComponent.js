import { Component } from 'react'
import { forceCheck } from 'react-lazyload'

class LazyLoadCheckingComponent extends Component {
  componentDidUpdate (pastProps) {
    const past = (pastProps.filesForList || pastProps.unselectedFilesForList)
    const present = (this.props.filesForList || this.props.unselectedFilesForList)

    if (past.length !== present.length) {
      forceCheck()
    }
  }
}

export default LazyLoadCheckingComponent

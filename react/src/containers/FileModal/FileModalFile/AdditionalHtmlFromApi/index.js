import React from 'react'

import { apiGet } from 'utils/api'
import Loader from 'components/Loader'

import Wrap from './styled/Wrap'

class AdditionalHtmlFromApi extends React.PureComponent {
  state = { loading: false, loaded: false, html: null, error: null }

  componentDidMount () {
    if (!this.state.loaded && !this.state.loading) {
      apiGet(this.props.apiUrl)
        .then((response) => {
          this.setState({ ...this.state, loading: false, loaded: true, html: response.data })
        })
        .catch((error) => {
          this.setState({ ...this.state, loading: true, loaded: true, error })
        })

      this.setState({ ...this.state, loading: true, loaded: false, html: null, error: null })
    }
  }

  render () {
    if (!this.props.apiUrl) return null

    return (
      <Wrap>
        {this.state.loading ? (
          <Loader standalone={50} />
        ) : <div dangerouslySetInnerHTML={{ __html: this.state.html }} />}
      </Wrap>
    )
  }
}

export default AdditionalHtmlFromApi

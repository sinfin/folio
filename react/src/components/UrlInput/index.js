import React from 'react'
import { Input } from 'reactstrap'

import { LINKS_URL } from 'constants/urls'

class UrlInput extends React.PureComponent {
  state = { hinted: false }

  constructor (props) {
    super(props)
    this.selectRef = React.createRef()
    this.inputRef = React.createRef()
    this.timeout = null
  }

  componentDidMount () {
    const $select = window.jQuery(this.selectRef.current)

    $select.select2({
      width: '100%',
      language: document.documentElement.lang,
      ajax: {
        url: LINKS_URL,
        dataType: 'JSON',
        minimumInputLength: 0,
        cache: false,
        data: (params) => ({ q: params.term })
      }
    })

    $select.on('select2:select', (e) => {
      this.inputRef.current.value = e.params.data.id
      this.props.onValueChange(e.params.data.id)
      this.setState({ hinted: true })
      this.timeout = setTimeout(() => {
        this.setState({ hinted: false })
      }, 1000)
    })
  }

  componentWillUnmount () {
    if (this.timeout) window.clearTimeout(this.timeout)

    const $select = window.jQuery(this.selectRef.current)
    $select.select2('destroy')
    $select.off('select2:select')
  }

  render () {
    return (
      <div className='row'>
        <div className='col-md-4'>
          <select className='form-control' ref={this.selectRef} />
        </div>

        <div className='col-md-8'>
          <Input
            name={this.props.key}
            defaultValue={this.props.defaultValue}
            onChange={this.props.onChange}
            onKeyPress={this.props.onKeyPress}
            invalid={this.props.invalid}
            innerRef={this.inputRef}
            className={this.state.hinted ? 'form-control--hinted' : null}
          />
        </div>
      </div>
    )
  }
}

export default UrlInput

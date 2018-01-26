import React, { Component } from 'react'
import { connect } from 'react-redux'
import styled from 'styled-components'

import {
  filtersSelector,
  setFilter,
} from 'ducks/filters'

const Wrap = styled.div`
`

class FileFilter extends Component {
  onNameChange = (e) => {
    this.props.dispatch(setFilter('name', e.target.value))
  }

  render() {
    const { filters } = this.props

    return (
      <Wrap>
        <input
          className='form-control'
          value={filters.name}
          onChange={this.onNameChange}
        />
      </Wrap>
    )
  }
}

const mapStateToProps = (state) => ({
  filters: filtersSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileFilter)

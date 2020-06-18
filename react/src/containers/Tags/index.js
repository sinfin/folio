import React from 'react'
import { connect } from 'react-redux'
import { without } from 'lodash'

import {
  makeFiltersSelector,
  setFilter
} from 'ducks/filters'

import Tag from './styled/Tag'

class Tags extends React.Component {
  onTagClick (tag) {
    let tags

    if (this.props.filters.tags.indexOf(tag) === -1) {
      tags = [...this.props.filters.tags, tag]
    } else {
      tags = without(this.props.filters.tags, tag)
    }

    this.props.dispatch(setFilter(this.props.fileType, this.props.filesUrl, 'tags', tags))
  }

  render () {
    return (
      <div className='small mx-n1 d-flex flex-wrap m-n1'>
        {(this.props.file.attributes.tags || []).map((tag) => (
          <Tag
            key={tag}
            className='btn btn-sm btn-link p-0 m-1'
            onClick={() => { this.onTagClick(tag) }}
          >
            {tag}
          </Tag>
        ))}
      </div>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filters: makeFiltersSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Tags)

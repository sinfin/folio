import React from 'react'
import { connect } from 'react-redux'
import { without } from 'lodash'

import { openModal } from 'ducks/modal'
import {
  makeFiltersSelector,
  setFilter
} from 'ducks/filters'

import TagsWrap from './styled/TagsWrap'
import Tag from './styled/Tag'

class Tags extends React.Component {
  onEditClick = (e) => {
    e.stopPropagation()
    this.props.dispatch(openModal(this.props.file))
  }

  onTagClick (tag) {
    let tags

    if (this.props.filters.tags.indexOf(tag) === -1) {
      tags = [...this.props.filters.tags, tag]
    } else {
      tags = without(this.props.filters.tags, tag)
    }

    this.props.dispatch(setFilter(this.props.filesKey, 'tags', tags))
  }

  render () {
    let tags = []
    if (this.props.file.attributes && this.props.file.tags) {
      tags = this.props.file.tags
    }

    return (
      <TagsWrap className='small mx-n2'>
        {tags.map((tag) => (
          <Tag
            key={tag}
            className='btn btn-sm btn-link'
            onClick={() => { this.onTagClick(tag) }}
          >
            {tag}
          </Tag>
        ))}
        <Tag className='btn btn-sm btn-link' onClick={this.onEditClick} >
          <span className='mi'>edit</span>
        </Tag>
      </TagsWrap>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filters: makeFiltersSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(Tags)

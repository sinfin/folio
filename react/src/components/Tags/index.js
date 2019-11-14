import React from 'react'

import TagsWrap from './styled/TagsWrap'
import { ModalContext } from 'containers/Modal'

class Tags extends React.Component {
  static contextType = ModalContext

  onClick = (e) => {
    e.stopPropagation()
    this.context(this.props.file)
  }

  render () {
    const tags = this.props.file.attributes.tags
    const hasTags = tags && tags.length > 0

    return (
      <TagsWrap onClick={this.onClick}>
        {hasTags ? (
          tags.map((tag) => (
            <span key={tag} className='badge badge-secondary'>{tag}</span>
          ))
        ) : (
          <span className='badge badge-success'>+</span>
        )}
      </TagsWrap>
    )
  }
}

export default Tags

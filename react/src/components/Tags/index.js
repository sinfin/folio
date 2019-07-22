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
    return (
      <TagsWrap onClick={this.onClick}>
        {this.props.file.attributes.tags.map((tag) => (
          <span key={tag} className='badge badge-secondary'>{tag}</span>
        ))}

        {this.props.file.attributes.tags.length === 0 && (
          <span className='badge badge-success'>+</span>
        )}
      </TagsWrap>
    )
  }
}

export default Tags

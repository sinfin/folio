import React from 'react'

import TagsWrap from './styled/TagsWrap';
import { ModalContext } from 'containers/Modal';

class Tags extends React.Component {
  static contextType = ModalContext

  onClick = (e) => {
    e.stopPropagation()
    this.context(this.props.file)
  }

  render () {
    const { file, disabled } = this.props

    return (
      <TagsWrap onClick={this.onClick}>
        {file.tags.map((tag) => (
          <span key={tag} className='badge badge-secondary'>{tag}</span>
        ))}
      </TagsWrap>
    )
  }
}

export default Tags

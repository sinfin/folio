import React from 'react'

import TagsWrap from './styled/TagsWrap';
import { ModalContext } from 'containers/Modal';

class Tags extends React.Component {
  static contextType = ModalContext

  render () {
    const { file } = this.props

    return (
      <TagsWrap onClick={() => this.context(file)}>
        {file.tags.map((tag) => (
          <span key={tag} className='badge badge-secondary'>{tag}</span>
        ))}
      </TagsWrap>
    )
  }
}

export default Tags

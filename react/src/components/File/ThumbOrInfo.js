import React from 'react'
import styled from 'styled-components'
import LazyLoad from 'react-lazyload'

import truncate from 'utils/truncate';

const Wrap = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 0;

  strong {
    max-width: 100%;
  }

  i {
    margin-bottom: 10px;
    font-size: 30px;
  }
`

function ThumbOrInfo ({ file, singleSelect }) {
  if (file.thumb) {
    return (
      <LazyLoad height={150} once overflow={singleSelect}>
        <img src={file.thumb} alt={file.file_name} />
      </LazyLoad>
    )
  }

  return (
    <Wrap>
      <i className='fa fa-file-o' />

      <strong>{truncate(file.file_name)}</strong>
    </Wrap>
  )
}

export default ThumbOrInfo

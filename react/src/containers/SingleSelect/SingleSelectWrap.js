import styled from 'styled-components'

import SingleSelectScroll from './SingleSelectScroll'

const SingleSelectWrap = styled.div`
  display: flex;
  flex-direction: column;
  height: 100%;

  > div {
    flex: 0 0 auto;
  }

  > ${SingleSelectScroll} {
    flex: 1 1 100%;
  }
`

export default SingleSelectWrap

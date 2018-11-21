import styled from 'styled-components'

const SingleSelectScroll = styled.div`
  overflow-y: auto;
  position: relative;
  z-index: 1;

  .redactor-modal-tab & {
    margin: 0 -15px;
  }
`

export default SingleSelectScroll

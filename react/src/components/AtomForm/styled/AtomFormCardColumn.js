import styled from 'styled-components'

export default styled.div`
  flex: ${(props) => props.dontGrow ? '0' : '1'} 1 auto;
  padding: 0 12px;
`

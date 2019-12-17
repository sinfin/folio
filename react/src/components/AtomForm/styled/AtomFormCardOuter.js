import styled from 'styled-components'

export default styled.div`
  z-index: ${(props) => props.focused ? '2' : '1'};
  position: relative;
`

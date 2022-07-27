import styled from 'styled-components'

export default styled.div`
  z-index: ${(props) => props.above ? 2 : 1};
  position: relative;
  flex: ${(props) => props.narrow ? '0 0 180px' : '1 1 auto'};
  padding: ${(props) => props.pad ? '0 7.5px' : '0'};
`

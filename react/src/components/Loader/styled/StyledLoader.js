import styled from 'styled-components'

export default styled.div`
  ${(props) => props.standalone ? `
    position: relative;
    height: ${typeof props.standalone === 'number' ? `${props.standalone}px` : '50vh'};
  ` : ''}
`

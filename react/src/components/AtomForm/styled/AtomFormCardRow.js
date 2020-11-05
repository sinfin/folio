import styled from 'styled-components'

export default styled.div`
  display: flex;
  position: relative;
  z-index: 2;

  & & {
    display: block;
    flex: 1 1 auto;
  }
`

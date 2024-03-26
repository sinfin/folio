import styled from 'styled-components'

export default styled.div`
  display: none;

  @media screen and (min-width: 780px) {
    display: block;
    position: absolute;
    top: 50%;
    right: 0;
    transform: translate(0, -50%);
  }
`

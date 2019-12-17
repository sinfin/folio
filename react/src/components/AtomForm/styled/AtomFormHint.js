import styled from 'styled-components'

export default styled.div`
  color: $black;
  position: relative;
  padding-left: 30px;

  ${(props) => props.molecule ? 'margin: 1rem 0;' : 'margin: 3rem 0 0;'}

  .mi {
    position: absolute;
    top: 0;
    left: 0;
    font-size: 22px;
  }
`

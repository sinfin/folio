import styled from 'styled-components'

export default styled.div`
  height: 15px;
  position: relative;
  margin: 0.5rem 0;
  cursor: pointer;

  &::after {
    content: "";
    display: block;
    position: absolute;
    top: 50%;
    left: 25px;
    right: 0;
    opacity: ${(props) => props.checked ? 1 : 0.3};
    border-top: 1px dashed #7bb2a9;
  }

  &:hover::after {
    opacity: 1;
  }

  input {
    position: absolute;
    top: 50%;
    left: 0;
    transform: translate(0, -50%);
    margin: 0;
  }
`

import styled from 'styled-components';

export default styled.button`
  opacity: ${(props) => props.active ? 1 : 0.5};
`

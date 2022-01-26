import styled from 'styled-components'

export default styled.div`
  align-items: center;
  justify-content: end;
  flex-wrap: wrap;

  .card-body > &:first-child,
  .f-c-r-dropzone > &:first-child {
    margin-bottom: 1rem;
  }

  .card-body > &:last-child,
  .f-c-r-dropzone > &:last-child {
    margin-top: 1rem;
    ${(props) => props.single ? 'display: none;' : ''}
  }
`

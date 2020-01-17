import styled from 'styled-components'

export default styled.div`
  align-items: center;
  justify-content: end;
  flex-wrap: wrap;
  margin-top: -15px;
  padding-top: 0.5rem;
  padding-bottom: 0.5rem;

  .card-body > &:last-child {
    margin-top: 15px;
    margin-bottom: -15px;
    ${(props) => props.single ? 'display: none;' : ''}
  }
`

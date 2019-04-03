import styled from 'styled-components'

export default styled.div`
  white-space: normal;
  min-width: 250px;

  ${(props) => props.onClick ? 'cursor: zoom-in;' : null}

  .table & {
    text-align: right;
  }

  .badge {
    margin: 0.1rem;
  }
`

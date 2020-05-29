import styled from 'styled-components'

export default styled.div`
  display: flex;
  align-items: center;
  width: 400px;
  max-width: 75vw;
  padding: 10px 10px 10px 20px;
  height: 100%;

  .f-c-index-actions {
    padding-left: 30px;
    margin-left: auto;
  }

  ${(props) => props.invalid ? 'background: rgba(241, 101, 93, 0.15);' : ''}
`

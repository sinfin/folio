import styled from 'styled-components'

const Wrap = styled.div`
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  margin: -7.5px -15px;

  .redactor-modal-tab & {
    padding-bottom: 30px;
  }

  .form-group {
    margin: 7.5px;
  }

  .form-group--react-select {
    &, > div {
      min-width: 250px;
    }
  }

  .form-group--reset {
    margin-left: auto;

    + .btn-group {
      margin-left: 0;
    }
  }

  @media screen and (max-width: 576px) {
    flex-direction: column;
    align-items: stretch;
  }
`

export default Wrap

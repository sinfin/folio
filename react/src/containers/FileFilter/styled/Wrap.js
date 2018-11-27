import styled from 'styled-components'

const Wrap = styled.div`
  z-index: 2;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  margin: -7.5px -15px;

  .modal-body & {
    margin: -0.5rem;
  }

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

    + .folio-console-react-display-controls {
      margin-left: 0;
    }
  }

  @media screen and (max-width: 576px) {
    flex-direction: column;
    align-items: stretch;

    .form-group--reset {
      margin-left: auto;
      margin-right: auto;
    }

    .folio-console-react-display-controls,
    .form-group--reset + .folio-console-react-display-controls {
      margin-left: auto;
      margin-right: auto;
    }
  }
`

export default Wrap

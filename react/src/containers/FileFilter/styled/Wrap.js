import styled from 'styled-components'

const Wrap = styled.div`
  z-index: 2;

  .form-control--select:invalid:not(:focus) {
    color: #c1c4c9;
  }

  .row {
    margin-left: -5px;
    margin-right: -5px;
  }

  .col-12 {
    padding-left: 5px;
    padding-right: 5px;
  }

  .folio-console-modal__scroll-fixed & {
    margin-right: 30px;
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

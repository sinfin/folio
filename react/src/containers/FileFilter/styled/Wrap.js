import styled from 'styled-components'

const Wrap = styled.div`
  position: relative;
  z-index: 2;

  .redactor-modal-tab & {
    padding-bottom: 30px;
  }

  .form-group {
    margin-right: 15px;
  }

  .form-group--react-select {
    flex: 0 0 250px;

    > div {
      width: 250px;
    }
  }

  .form-group--reset {
    margin-left: auto;

    + .btn-group {
      margin-left: 0;
    }
  }
`

export default Wrap

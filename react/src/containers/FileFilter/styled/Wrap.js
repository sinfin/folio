import styled from 'styled-components'

const Wrap = styled.div`
  position: relative;
  z-index: 2;

  .redactor-modal-tab & {
    padding-bottom: 30px;
  }

  .form-group {
    margin-right: 30px;
  }

  .form-group--react-select {
    flex: 0 0 250px;

    > div {
      width: 250px;
    }
  }
`

export default Wrap

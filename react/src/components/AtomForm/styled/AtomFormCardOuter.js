import styled from 'styled-components'

export default styled.div`
  z-index: ${(props) => props.focused ? '2' : '1'};
  position: relative;

  .alert-danger > :last-child {
    margin-bottom: 0;
  }

  .folio-loader {
    z-index: 1000;
  }

  ${(props) => props.asMolecule ? `
    padding-right: 3rem;
    position: relative;
    min-height: 103px;
    margin-bottom: 1rem;

    & > .f-c-nested-model-controls {
      position: absolute;
      top: 0;
      right: 0;
      transition: .15s all;
      opacity: 0;
    }

    &:hover > .f-c-nested-model-controls {
      opacity: 1;
    }
  ` : ''}
`

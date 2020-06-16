import styled from 'styled-components'

export default styled.div`
  position: relative;
  flex: 1 1 auto;
  display: flex;
  flex-direction: column;
  height: 100%;

  .folio-loader {
    top: -15px;
    left: -15px;
    width: calc(100% + 30px);
    height: calc(100% + 30px);
    z-index: 2;
  }

  .card-outer {
    padding-right: 3rem;
    position: relative;
    min-height: 103px;
  }

  .card-outer > .f-c-nested-model-controls {
    position: absolute;
    top: 0;
    right: 0;
    transition: .15s all;
    opacity: 0;
  }

  .card-outer:hover > .f-c-nested-model-controls {
    opacity: 1;
  }

  .z-index-1 {
    z-index: 1;
  }

  .z-index-2 {
    z-index: 2;
  }
`

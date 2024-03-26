import styled from 'styled-components'

export default styled.div`
  position: relative;
  display: flex;
  align-items: center;
  gap: 1.5rem;
  flex-wrap: wrap;
  min-height: 18px;

  .f-c-pagination {
    margin: 0;
  }

  @media screen and (max-width: 779px) {
    display: block;

    .f-c-pagination__nav {
      margin-left: auto;
    }
  }

  @media screen and (min-width: 780px) {
    padding: 0 215px;
    justify-content: center;
    ${(props) => props.single ? '' : 'min-height: 36px;'}

    .f-c-pagination__info {
      position: absolute;
      top: 50%;
      left: 0;
      transform: translate(0, -50%);
    }
  }
`

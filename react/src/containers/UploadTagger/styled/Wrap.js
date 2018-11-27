import styled from 'styled-components'

export default styled.div`
  display: flex;
  align-items: center;

  .react-select-container {
    flex: 1 1 auto;
    margin-left: 15px;
  }

  form & {
    margin-top: 0;
  }

  label {
    margin-bottom: 0;
  }

  .btn {
    flex: 0 0 auto;
    margin-left: 15px;
  }

  @media screen and (max-width: 610px) {
    padding-top: 35px;
    position: relative;

    label {
      position: absolute;
      top: 7.5px;
      left: 15px;
    }

    .react-select-container {
      margin-left: 0;
    }
  }

  @media screen and (max-width: 374px) {
    .react-select-container {
      flex: 0 0 100%;
    }

    label {
      text-align: center;
      width: 100%;
    }

    .btn {
      margin: 7.5px auto 0;
    }
  }
`

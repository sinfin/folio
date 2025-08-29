import * as React from "react"

export const TableMergeCells = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className={className}
        {...props}
      >
        <path
          d="M5 10H3V4H11V6H5V10ZM19 18H13V20H21V14H19V18ZM5 18V14H3V20H11V18H5ZM21 4H13V6H19V10H21V4ZM8 13V15L11 12L8 9V11H3V13H8ZM16 11V9L13 12L16 15V13H21V11H16Z"
          fill="currentColor"
        />
      </svg>
    )
  }
)

TableMergeCells.displayName = "TableMergeCells"

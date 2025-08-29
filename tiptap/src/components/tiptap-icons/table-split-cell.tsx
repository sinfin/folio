import * as React from "react"

export const TableSplitCell = React.memo(
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
        <path d="M19 14H21V20H3V14H5V18H19V14ZM3 4V10H5V6H19V10H21V4H3ZM11 11V13H8V15L5 12L8 9V11H11ZM16 11V9L19 12L16 15V13H13V11H16Z" fill="currentColor"/>
      </svg>
    )
  }
)

TableSplitCell.displayName = "TableSplitCell"

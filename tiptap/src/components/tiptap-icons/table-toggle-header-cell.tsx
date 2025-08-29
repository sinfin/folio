import * as React from "react"

export const TableToggleHeaderCell = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="24"
        height="24"
        className={className}
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        {...props}
      >
        <rect x="6" y="7" width="4" height="3" fill="currentColor" />
        <path
          d="M19 4C20.1046 4 21 4.89543 21 6V18C21 19.0357 20.2128 19.887 19.2041 19.9893L19 20H5L4.7959 19.9893C3.78722 19.887 3 19.0357 3 18V6C3 4.89543 3.89543 4 5 4H19ZM5 18H11V13H5V18ZM13 18H19V13H13V18ZM5 11H11V6H5V11ZM13 11H19V6H13V11Z"
          fill="currentColor"
        />
      </svg>
    )
  }
)

TableToggleHeaderCell.displayName = "TableToggleHeaderCell"

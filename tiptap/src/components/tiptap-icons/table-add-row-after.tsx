import * as React from "react"

export const TableAddRowAfter = React.memo(
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
        <path d="M22 10C22 10.5304 21.7893 11.0391 21.4142 11.4142C21.0391 11.7893 20.5304 12 20 12H4C3.46957 12 2.96086 11.7893 2.58579 11.4142C2.21071 11.0391 2 10.5304 2 10V3H4V5H8V3H10V5H14V3H16V5H20V3H22V10ZM4 10H8V7H4V10ZM10 10H14V7H10V10ZM20 10V7H16V10H20ZM11 14H13V17H16V19H13V22H11V19H8V17H11V14Z" fill="currentColor"/>
      </svg>
    )
  }
)

TableAddRowAfter.displayName = "TableAddRowAfter"

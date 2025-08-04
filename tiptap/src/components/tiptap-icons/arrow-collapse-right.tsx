import * as React from "react"

export const ArrowCollapseRight = React.memo(
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
        <path d="M12.08 4.08L20 12L12.08 19.92L10.67 18.5L16.17 13H2V11H16.17L10.67 5.5L12.08 4.08ZM20 12V22H22V2H20V12Z" fill="currentColor"/>
      </svg>
    )
  }
)

ArrowCollapseRight.displayName = "ArrowCollapseRight"

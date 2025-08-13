import * as React from "react"

export const SmartphoneIcon = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="16"
        height="16"
        className={className}
        viewBox="0 0 16 16"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        {...props}
      >
        <path fillRule="evenodd" clipRule="evenodd" d="M4.66669 2.00033C4.2985 2.00033 4.00002 2.2988 4.00002 2.66699V13.3337C4.00002 13.7018 4.2985 14.0003 4.66669 14.0003H11.3334C11.7015 14.0003 12 13.7018 12 13.3337V2.66699C12 2.2988 11.7015 2.00033 11.3334 2.00033H4.66669ZM2.66669 2.66699C2.66669 1.56242 3.56212 0.666992 4.66669 0.666992H11.3334C12.4379 0.666992 13.3334 1.56242 13.3334 2.66699V13.3337C13.3334 14.4382 12.4379 15.3337 11.3334 15.3337H4.66669C3.56212 15.3337 2.66669 14.4382 2.66669 13.3337V2.66699Z" fill="currentColor"/>
        <path fillRule="evenodd" clipRule="evenodd" d="M7.33331 11.9997C7.33331 11.6315 7.63179 11.333 7.99998 11.333H8.00665C8.37484 11.333 8.67331 11.6315 8.67331 11.9997C8.67331 12.3679 8.37484 12.6663 8.00665 12.6663H7.99998C7.63179 12.6663 7.33331 12.3679 7.33331 11.9997Z" fill="currentColor"/>
      </svg>
    )
  }
)

SmartphoneIcon.displayName = "SmartphoneIcon"

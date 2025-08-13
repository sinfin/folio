import * as React from "react"

export const MonitorIcon = React.memo(
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
        <path fillRule="evenodd" clipRule="evenodd" d="M2.66669 2.66634C2.2985 2.66634 2.00002 2.96482 2.00002 3.33301V9.99967C2.00002 10.3679 2.2985 10.6663 2.66669 10.6663H13.3334C13.7015 10.6663 14 10.3679 14 9.99967V3.33301C14 2.96482 13.7015 2.66634 13.3334 2.66634H2.66669ZM0.666687 3.33301C0.666687 2.22844 1.56212 1.33301 2.66669 1.33301H13.3334C14.4379 1.33301 15.3334 2.22844 15.3334 3.33301V9.99967C15.3334 11.1042 14.4379 11.9997 13.3334 11.9997H2.66669C1.56212 11.9997 0.666687 11.1042 0.666687 9.99967V3.33301Z" fill="currentColor"/>
        <path fillRule="evenodd" clipRule="evenodd" d="M4.66669 13.9997C4.66669 13.6315 4.96516 13.333 5.33335 13.333H10.6667C11.0349 13.333 11.3334 13.6315 11.3334 13.9997C11.3334 14.3679 11.0349 14.6663 10.6667 14.6663H5.33335C4.96516 14.6663 4.66669 14.3679 4.66669 13.9997Z" fill="currentColor"/>
        <path fillRule="evenodd" clipRule="evenodd" d="M7.99998 10.667C8.36817 10.667 8.66665 10.9655 8.66665 11.3337V14.0003C8.66665 14.3685 8.36817 14.667 7.99998 14.667C7.63179 14.667 7.33331 14.3685 7.33331 14.0003V11.3337C7.33331 10.9655 7.63179 10.667 7.99998 10.667Z" fill="currentColor"/>
      </svg>
    )
  }
)

MonitorIcon.displayName = "MonitorIcon"

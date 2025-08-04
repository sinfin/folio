import * as React from "react"

export const PencilBoxIcon = React.memo(
  ({ className, ...props }: React.SVGProps<SVGSVGElement>) => {
    return (
      <svg
        width="16"
        height="16"
        viewBox="0 0 16 16"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className={className}
        {...props}
      >
        <path d="M12.6667 2C13.0203 2 13.3594 2.14048 13.6095 2.39052C13.8595 2.64057 14 2.97971 14 3.33333V12.6667C14 13.4067 13.4 14 12.6667 14H3.33333C2.97971 14 2.64057 13.8595 2.39052 13.6095C2.14048 13.3594 2 13.0203 2 12.6667V3.33333C2 2.97971 2.14048 2.64057 2.39052 2.39052C2.64057 2.14048 2.97971 2 3.33333 2H12.6667ZM11.1333 6.23333C11.28 6.09333 11.28 5.86 11.1333 5.72L10.28 4.86667C10.14 4.72 9.90667 4.72 9.76667 4.86667L9.1 5.53333L10.4667 6.9L11.1333 6.23333ZM4.66667 9.96V11.3333H6.04L10.08 7.29333L8.70667 5.92L4.66667 9.96Z" fill="currentColor"/>
      </svg>
    )
  }
)

PencilBoxIcon.displayName = "PencilBoxIcon"

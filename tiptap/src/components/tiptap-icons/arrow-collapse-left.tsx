import * as React from "react";

export const ArrowCollapseLeft = React.memo(
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
        <path
          d="M11.92 19.92L4 12L11.92 4.08L13.33 5.5L7.83 11H22V13H7.83L13.34 18.5L11.92 19.92ZM4 12V2H2V22H4V12Z"
          fill="currentColor"
        />
      </svg>
    );
  },
);

ArrowCollapseLeft.displayName = "ArrowCollapseLeft";

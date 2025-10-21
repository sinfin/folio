import * as React from "react";

export const TableAddRowBefore = React.memo(
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
          d="M22 14C22 13.4696 21.7893 12.9609 21.4142 12.5858C21.0391 12.2107 20.5304 12 20 12H4C3.46957 12 2.96086 12.2107 2.58579 12.5858C2.21071 12.9609 2 13.4696 2 14V21H4V19H8V21H10V19H14V21H16V19H20V21H22V14ZM4 14H8V17H4V14ZM10 14H14V17H10V14ZM20 14V17H16V14H20ZM11 10H13V7H16V5H13V2H11V5H8V7H11V10Z"
          fill="currentColor"
        />
      </svg>
    );
  },
);

TableAddRowBefore.displayName = "TableAddRowBefore";

import * as React from "react";

export const Button = React.forwardRef<HTMLButtonElement, React.ButtonHTMLAttributes<HTMLButtonElement>>(
  ({ className, ...props }, ref) => {
    return <button ref={ref} className={`bg-blue-600 text-white px-4 py-2 rounded ${className}`} {...props} />;
  }
);
Button.displayName = "Button";


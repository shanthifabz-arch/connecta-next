import * as React from "react";

export const Label = React.forwardRef<
  HTMLLabelElement,
  React.LabelHTMLAttributes<HTMLLabelElement>
>(({ className, ...props }, ref) => {
  return <label ref={ref} className={`block mb-1 font-medium ${className}`} {...props} />;
});
Label.displayName = "Label";


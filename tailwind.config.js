/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",       // if you still have any Pages Router files
    "./components/**/*.{js,ts,jsx,tsx,mdx}",  // if you keep components at project root
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};

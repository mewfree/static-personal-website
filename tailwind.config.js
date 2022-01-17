module.exports = {
  content: ["./src/**/*.html"],
  darkMode: "class",
  theme: {
    extend: {
      typography: {
        DEFAULT: {
          css: {
            pre: false,
            code: false,
            "pre code": false,
            "code::before": false,
            "code::after": false,
            h1: {
              marginBottom: "0.5rem",
            },
            a: {
              textDecoration: "none",
            },
            "a:hover": {
              textDecoration: "underline",
            },
          },
        },
      },
    },
  },
  plugins: [
      require("@tailwindcss/typography"),
  ],
}

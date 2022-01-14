module.exports = {
  content: ["./src/**/*.html"],
  theme: {
    extend: {
      typography: (theme) => ({
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
        // dark: {
        //   css: {
        //     color: "white",
        //     "h1,h2,h3,h4,h5,h6": {
        //       color: "white",
        //     },
        //     strong: {
        //       color: "white",
        //     },
        //     a: {
        //       color: theme("colors.indigo.400"),
        //     },
        //   },
        // },
      }),
    },
  },
  plugins: [
      require("@tailwindcss/typography"),
  ],
}

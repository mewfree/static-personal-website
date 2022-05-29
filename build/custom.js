function loadCss(theme) {
  let file = document.createElement("link");
  file.setAttribute("rel", "stylesheet");
  file.setAttribute("href", `/highlight.${theme}.css`);
  document.getElementsByTagName("head")[0].appendChild(file);
}

if (
  localStorage.theme === "dark" ||
  (!("theme" in localStorage) &&
    window.matchMedia("(prefers-color-scheme: dark)").matches)
) {
  document.documentElement.classList.add("dark");
  document.getElementById("theme").innerText = "🌞️";
  loadCss("dark");
} else {
  document.documentElement.classList.remove("dark");
  document.getElementById("theme").innerText = "🌝";
  loadCss("light");
}

function toggleTheme() {
  if (
    localStorage.theme === "dark" ||
    (!("theme" in localStorage) &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    document.documentElement.classList.remove("dark");
    document.getElementById("theme").innerText = "🌝";
    localStorage.theme = "light";
    loadCss("light");
  } else {
    document.documentElement.classList.add("dark");
    document.getElementById("theme").innerText = "🌞️";
    localStorage.theme = "dark";
    loadCss("dark");
  }
}

document.addEventListener("DOMContentLoaded", (event) => {
  document.querySelectorAll("h2, h3, h4, h5, h6").forEach((el) => {
    const link = document.createElement("a");
    link.setAttribute("href", "#" + el.id);
    link.classList.add("header-anchor");
    el.prepend(link);
  });

  document.querySelectorAll("pre code").forEach((el) => {
    el.classList.remove("sourceCode");
    if (el.classList.length > 0) {
      el.classList.replace(el.classList[0], "language-" + el.classList[0]);
    }
    hljs.highlightElement(el);
  });

  renderMathInElement(document.body, {
    delimiters: [
      { left: "$$", right: "$$", display: true },
      { left: "$", right: "$", display: false },
      { left: "\\(", right: "\\)", display: false },
      { left: "\\[", right: "\\]", display: true },
    ],
    throwOnError: false,
  });
});

module.exports = {
  root: true,
  env: {
    es2022: true,
    node: true,
    browser: true
  },
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint"],
  extends: ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  ignorePatterns: [
    "dist/",
    "coverage/",
    ".serverless/",
    "node_modules/",
    "frontend/src/generated/"
  ],
  rules: {
    "@typescript-eslint/no-explicit-any": "off"
  }
};

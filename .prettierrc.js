module.exports = {
  overrides: [
    {
      files: "*.sol",
      rules: {
        "unit-case": null,
      },
      options: {
        bracketSpacing: false,
        printWidth: 80,
        tabWidth: 4,
        useTabs: false,
        singleQuote: false,
        explicitTypes: "always",
      },
    },
    {
      files: "*.js",
      options: {
        printWidth: 80,
        semi: true,
        tabWidth: 2,
        singleQuote: false,
        trailingComma: "es5",
      },
    },
  ],
};

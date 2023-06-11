local json_schemas = {
  {
    description = "TypeScript compiler configuration file",
    fileMatch = { "tsconfig.json", "tsconfig.*.json" },
    url = "https://json.schemastore.org/tsconfig.json"
  }, {
  description = "Babel configuration",
  fileMatch = { ".babelrc.json", ".babelrc", "babel.config.json" },
  url = "https://json.schemastore.org/babelrc.json"
}, {
  description = "ESLint config",
  fileMatch = { ".eslintrc.json", ".eslintrc" },
  url = "https://json.schemastore.org/eslintrc.json"
}, {
  description = "Prettier config",
  fileMatch = { ".prettierrc", ".prettierrc.json", "prettier.config.json" },
  url = "https://json.schemastore.org/prettierrc"
},
  {
    description = "Json schema for properties json file for a GitHub Workflow template",
    fileMatch = { ".github/workflow-templates/**.properties.json" },
    url = "https://json.schemastore.org/github-workflow-template-properties.json"
  }, {
  description = "NPM configuration file",
  fileMatch = { "package.json" },
  url = "https://json.schemastore.org/package.json"
}
}


local opts = {
  settings = { json = { schemas = json_schemas } }
}

return opts

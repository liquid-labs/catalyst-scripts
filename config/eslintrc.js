const pkg = require(process.cwd() + '/package.json');

const eslintConfig = {
  "parser": "@babel/eslint-parser",
  "parserOptions": {
    "sourceType": "module",
    "requireConfigFile" : "false",
    "babelOptions": {
      "configFile": __dirname + "/babel.config.js"
    }
  },
  "extends": [
    "standard",
    "eslint:recommended"
  ],
  "env": {
    "es6": true
  },
  "plugins": [],
  "rules": {
    "brace-style": [2, "stroustrup", { "allowSingleLine": true }],
    "curly": [2, "multi-line"],
    "import/export": 1,
    "indent": [2, 2, {
      "FunctionDeclaration": { "body": 1, "parameters": 2 },
      "ignoredNodes": ["JSXElement", "JSXElement > *", "JSXAttribute", "JSXIdentifier", "JSXNamespacedName", "JSXMemberExpression", "JSXSpreadAttribute", "JSXExpressionContainer", "JSXOpeningElement", "JSXClosingElement", "JSXText", "JSXEmptyExpression", "JSXSpreadChild"]
    }],
    "key-spacing": [2, {
      "singleLine": {
        "beforeColon": true,
        "afterColon": true,
        "mode": "strict"
      },
      "multiLine": {
        "beforeColon": true,
        "afterColon": true,
        "align": "colon"
      }
    }],
    "operator-linebreak": [2, "before", { "overrides": { "=": "after" } }],
    "prefer-const": 2,
    "prefer-spread": 2,
    "space-before-function-paren": [2, "never"],

    "array-callback-return": 2,
    "guard-for-in": 2,
    "no-caller": 2,
    "no-extra-bind": 2,
    "no-multi-spaces": 2,
    "no-new-wrappers": 2,
    "no-throw-literal": 2,
    "no-unexpected-multiline": 2,
    "no-with": 2,
    "yoda": 2
  }
};

if (pkg.liq && pkg.liq.packageType && /\|react(\|$)/.test(liq.packageType)) {
  eslintConfig.extends.push("standard-react");
  eslintConfig.plugins.push("react");
  Object.assign(eslintConfig.rules, {
    "react/jsx-boolean-value" : [2, "never"],
    "react/jsx-indent-props": [2, 4]
  });
}

module.exports = eslintConfig;

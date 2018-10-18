## Liquid Labs Style

Liquid Labs Style extends standard style with:
* use Stroustrup brace style (see [Brace style](#brace-style))
* require curly braces unless single line (`"curly": [2, "multi-line"]`; in the
  eslint docs, this is listed as a 'best pratice' but it seems more like a style
  rule to us)
* use 'aligned' (see [Key spacing](#key-spacing))
* break lines before operators (see [Operator line breaks](#operator-line-breaks))
* use `const` when variables are not changed (`"prefer-const": 2`),
* use the spread operator instead of `Object.apply()`; (`"prefer-spread": 2`),
* use bare boolean parameters embedded JSX (`"react/jsx-boolean-value": [2, "never"]`),
* no spaces before function parens (`"space-before-function-paren": [2, "never"]`)

### Indentation

We use a basic indentation of 2 spaces with and a hanging indent declaration
parameters and JSX props.
E.g.:
```javascript
function foo(bar
    baz) {
  bodyFunc();
}
```
```HTML
<Foo bar={baz}
    bing="I'm hanging">
  And I'm the Body.
</Foo>
```
The `ignoredNodes` lets JSX rules take care of the JSX indentation. The '2' in
`parameters` and `jsx-indent-props` are how many units of the indention to use
in that context, the 2 therefore establishes the extra, hanging indention,
whereas 1 would align.

Rules:
* `"indent": [2, 2, {
    "FunctionDeclaration": { "body": 1, "parameters": 2 },
    "ignoredNodes": ["JSXElement", "JSXElement > *", "JSXAttribute", "JSXIdentifier",
      "JSXNamespacedName", "JSXMemberExpression", "JSXSpreadAttribute", "JSXExpressionContainer",
      "JSXOpeningElement", "JSXClosingElement", "JSXText", "JSXEmptyExpression", "JSXSpreadChild"]
  }]`
* `"react/jsx-indent-props": [2, 2]`

For reference: [eslint indent rule](https://eslint.org/docs/rules/indent), [eslint config showing ignored JSX nodes](https://github.com/airbnb/javascript/blob/e9fff7adbf6dd4e3723c12849c407aafd429cf0f/packages/eslint-config-airbnb-base/rules/style.js#L141), [JSX AST](https://github.com/facebook/jsx/blob/master/AST.md)

### Brace style

We've seen people quit over brace style (well, more like the straw that broke
camel's back). Honestly, this is almost pure personal preference and we grew up
with Stroustrup. I like it's more compact than '1tbs', and scans better than
'Allman'.

Our rule is: `"brace-style": [2, "stroustrup", { "allowSingleLine": true }],`

### Key spacing

Aligned-key spacing looks cool and, IMO, makes code easier to scan. It's a pain
to do by hand. However, since eslint can format it automatically, we turn it on.
We also require space before and after the colon as this is symmetric with
the standard operator rules. Single-line definitions are allowed.

E.g.:
```javascript
{
 aKey       : value,
 aLongKey   : valueB,
 anotherKey : valueC,
}
```
 Our rule is:
 ```json
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
 }]
 ```

### Operator line breaks

After seeing the 'before' rule in action, we found it to be more readable. The
operator adheres more tightly to what follows. E.g., if we were reading "I like
dogs and cats", "and cats" forms a more natural unit than "dogs and". Dogs and
what? Cats. The same is true for code.

The one exception is the `=` operator, which is logically neutral, but adheres
to the left. E.g., in "dogs equals canines", "dogs equals" is the more natural
break.

Our rule is:
```json
"operator-linebreak": [2, "before", { "overrides": { "=": "after" } }],
```

### Open Questions

Dangling commas? Logically, they make sense, and everything looks fine in Go
(where they are required in multi-line situations). But I'm just not there yet.

## Best practices checks

We will probably add more as time goes on, but are trying to start out
conservative. These mainly follow [Google style](https://github.com/google/eslint-config-google/blob/master/index.js),
plus a few others we threw in. We also leave out `no-extend-native` for the
moment as we have not encountered a problem with it and it has been useful in
the past (though with modern transpilers, maybe we should revisit that).

* `"array-callback-return": 2` Why not? A common mistake.
* `"no-caller": 2`
* `"no-extra-bind": 2`
* `"no-multi-spaces": 2`
* `"no-new-wrappers": 2`
* `"no-throw-literal": 2`
* `"no-unexpected-multiline": 2`
* `"no-with": 2`
* `"yoda": 2` Keep it regular.

### Considered and rejected

`"no-invalid-this": 2`: There is a valid case for an "invalid" this in react.
Rather that creating a function and binding, you can use `this` in an arrow
function to avoid the need to `bind` functions (and we do), [as discussed here](https://medium.com/@jacobworrel/babels-transform-class-properties-plugin-how-it-works-and-what-it-means-for-your-react-apps-6983539ffc22).

## Reference

* [Javascript standard eslint rules](https://github.com/standard/eslint-config-standard)
* [Eslint rules list](https://eslint.org/docs/rules/)
* [eslint-config-google](https://github.com/google/eslint-config-google)

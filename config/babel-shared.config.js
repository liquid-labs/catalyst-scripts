exports.babelPresets = [
  '@babel/preset-env',
  '@babel/preset-react'
];

exports.rollupBabelPresets = [
  [ '@babel/preset-env', { 'modules': false } ],
  '@babel/preset-react'
];

// NOTE: We've tried a couple times to add 'private methods'. The problem comes in that classic conventions like
// 'this[fieldName]' fail (or at least might, never fully debugged). Dynamic field access and just general complication
// mean we should avoid. Besides, with the use of modules, there's an easy solution: create a function that's not
// exported outside the class.
// NOTE: We tried 'throw expressions', but the resulting code did not seem logically consistent with the source code.
// This certainly could have been user error, but simpler to just avoid it for now.
exports.babelPlugins = [
  '@babel/plugin-proposal-class-properties',
  '@babel/plugin-proposal-optional-chaining',
  '@babel/plugin-proposal-throw-expressions',
  [ '@babel/plugin-transform-runtime',
    { corejs: false, helpers: true, regenerator: true, useESModules: false }
  ]
];

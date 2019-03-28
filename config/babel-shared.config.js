exports.babelPresets = [
  '@babel/preset-env',
  '@babel/preset-react'
];

exports.rollupBabelPresets = [
  [ '@babel/preset-env', { 'modules': false } ],
  '@babel/preset-react'
];

exports.babelPlugins = [
  '@babel/plugin-proposal-class-properties',
  [ '@babel/plugin-transform-runtime',
    { corejs: false, helpers: true, regenerator: true, useESModules: false }
  ]
];

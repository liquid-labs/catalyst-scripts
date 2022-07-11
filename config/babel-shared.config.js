const pkglib = require('./pkglib.js');

const babelPresets = []
if (pkglib.target.isNodeish) { // then lets drop some reasonable targets
  // At one point, we thought we had to turn modules off in order to make it concatonate rather than import all the
  // scripts. But, that may have been a red herring. We had modules off for so long, I do wonder whether that was
  // necossary for a specific project or something. Or maybe we were just always confused about the affect. Maybe React
  // projects?
  // TODO: make the node version configurable configurable; or at least a var.
  // TODO: add support/consideraton for other engines
  babelPresets.push([ '@babel/preset-env', { /* modules : false, */ targets : "node 14.0" } ])
  // TODO: we should setup the output files here.
}
// and let multiple types be specified, then we'll create correctly packaged scripts for each.
if (pkglib.target.isReactish) {
  babelPresets.push('@babel/preset-env')
  babelPresets.push('@babel/preset-react')
}


// NOTE: We've tried a couple times to add 'private methods'. The problem comes in that classic conventions like
// 'this[fieldName]' fail (or at least might, never fully debugged). Dynamic field access and just general complication
// mean we should avoid. Besides, with the use of modules, there's an easy solution: create a function that's not
// exported outside the class.
// NOTE: We tried 'throw expressions', but the resulting code did not seem logically consistent with the source code.
// This certainly could have been user error, but simpler to just avoid it for now.
const babelPlugins = [
  '@babel/plugin-proposal-class-properties',
  '@babel/plugin-proposal-optional-chaining',
  '@babel/plugin-proposal-throw-expressions',
  [ '@babel/plugin-transform-runtime',
    { corejs: false, helpers: true, regenerator: true, useESModules: false }
  ],
  '@babel/plugin-syntax-import-assertions',
  'inline-json-import'
];


exports.babelPresets = babelPresets;
exports.babelPlugins = babelPlugins;

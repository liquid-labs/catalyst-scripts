import babel from 'rollup-plugin-babel'
import commonjs from 'rollup-plugin-commonjs'
import excludeDependenciesFromBundle from 'rollup-plugin-exclude-dependencies-from-bundle'
import nodeExternals from 'rollup-plugin-node-externals'
import postcss from 'rollup-plugin-postcss'
import resolve from 'rollup-plugin-node-resolve'
import url from 'rollup-plugin-url'

const babelConfig = require('./babel-shared.config.js')

const rollupBabelPresets = babelConfig.rollupBabelPresets
const babelPlugins = babelConfig.babelPlugins

const pkglib = require('./pkglib.js')

const jsInput = process.env.JS_BUILD_TARGET || 'js/index.js' // default

const sourcemap = process.env.JS_SOURCEMAP || 'inline'

console.error('process.env.JS_OUT', process.env.JS_OUT)

const determineOutput = function() {
  const output = []

  let file = process.env.JS_OUT
  const format = pkglib.packageJson.type === 'module' ? 'es' : 'cjs'

  if (file !== undefined) {
    output.push({ file, format, sourcemap })
  }
  else {
    if (pkglib.packageJson.main !== undefined) {
      output.push({
        file: pkglib.packageJson.main,
        format,
        sourcemap
      })
    }
    if (pkglib.packageJson.module !== undefined) {
      output.push({
        file: pkglib.packageJson.module,
        format: 'es',
        sourcemap
      })
    }
  }

  return output
}

const commonjsConfig = {
  include: [ 'node_modules/**' ]
}
if (pkglib.target.rollupConfig) {
  Object.assign(commonjsConfig, pkglib.target.rollupConfig.commonjsConfig)
}

const rollupConfig = {
  input: jsInput,
  output: determineOutput(),
  watch: {
    clearScreen: false
  },
  plugins: [
    excludeDependenciesFromBundle({ peerDependencies: true, dependencies: true }),
    postcss({
      modules: true
    }),
    url(),
    babel({
      exclude: 'node_modules/**',
      runtimeHelpers: true,
      // '"modules": false' necessary for our React apps to work with the
      // distributed library.
      // TODO: does rollup handle the modules in this case?
      presets: rollupBabelPresets,
      plugins: babelPlugins
    }),
    resolve({ extensions: [ '.js', '.jsx' ], preferBuiltins: true }),
    commonjs(commonjsConfig)
    // TODO: move this to ancillary docs.
    /*Attempted to create a 'yalc-push plugin', but there is just not
      'everything done' hook. The hooks are based on bundles and since we make
      multiple bundles, we tried to get clever, but it's to complicated. Also,
      'writeBundle' hook simply never fired for whatever reason.
      {
      name: 'yalc-push',
      generateBundle: function () {
        shelljs.exec(`COUNT=0 \
          && for i in $(du -s ${distDir}* | awk '{print $1}'); do \
               COUNT=$(($COUNT + 1)); \
               test $i -ne 0 || break; \
             done \
          && test $COUNT -eq 4 \
          && yalc push`);
      }
    }*/
  ],
  onwarn: function (warning) {
    // https://docs.google.com/document/d/1f4iB4H4JGZ5LbqY-IX_2FXD47aq7ZouJYhjsnzrlUVg/edit#heading=h.g37mglv4gne6
    if (warning.code === 'THIS_IS_UNDEFINED') return;
    console.error(warning.message);
  }
}

if (pkglib.target.isNodeish) {
  rollupConfig.plugins.splice(0, 0, nodeExternals())
}

export default rollupConfig

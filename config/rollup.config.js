// Let's rollup work with babel.
import babel from 'rollup-plugin-babel'
import commonjs from 'rollup-plugin-commonjs'
// Add support for imported JSON files which otherwise cause silent, strange errors.
import json from '@rollup/plugin-json'
// Adds license information to the rolled up output file.
import license from 'rollup-plugin-license'
// Teaches rollup to treat `import * as fs from 'fs'` and similar as known externals. This license is conditionally
// included depending on the declared package type.
import nodeExternals from 'rollup-plugin-node-externals'
import postcss from 'rollup-plugin-postcss'
import resolve from '@rollup/plugin-node-resolve'
import url from 'rollup-plugin-url'

const babelConfig = require('./babel-shared.config.js')

const babelPresets = babelConfig.babelPresets
const babelPlugins = babelConfig.babelPlugins

const pkglib = require('./pkglib.js')

const jsInput = process.env.JS_BUILD_TARGET || 'js/index.js' // default
const sourcemap = process.env.JS_SOURCEMAP || 'inline'
let format = process.env.JS_FORMAT || null // TBD via packageJson

const determineOutput = function() {
  const output = []

  let file = process.env.JS_OUT
  if (format === null) {
    format = pkglib.packageJson.type === 'module' ? 'es' : 'cjs'
  }

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
  if (pkglib.target.isNodeish) {
    for (const entry of output) {
      entry.generatedCode = "es2015"
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
    // TODO: I think it would be cleaner to add this back in and then verify that's compatible with the 'node-
    // externals'. The problem with using the nodeExternals is not all our projects are noed projects.
    // excludeDependenciesFromBundle({ peerDependencies: true/*, dependencies: true*/ }),
    postcss({
      modules: true // whey?
    }),
    json(),
    url(),
    // Use babel for transpiling.
    babel({
      exclude: 'node_modules/**',
      runtimeHelpers: true,
      // '"modules": false' necessary for our React apps to work with the
      // distributed library. <- this might be an erroneous conclusion; test without
      // TODO: does rollup handle the modules in this case?
      presets: babelPresets,
      plugins: babelPlugins
    }),
    // The default extensions include the ones we really need, as well as others that are probably useful for
    // compatability.
    resolve({ /*extensions: [ '.js', '.jsx', 'json' ],*/ preferBuiltins: true }), // I mean, why not? Seriously... why
    // not prefer built-ins by default?
    commonjs(commonjsConfig) // Do we need this? 
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
  // This will bundle imports from 'devDependencies', but not 'deps'. You'd think this would be handled at a higher ////
  // level... but not really. The core 'external' config lets you specify specific packages, but you can can only
  // exclude packages by naming them. Which would be fine, but this method kills two birds with one stone... but maybe
  // I'm missing something. The rolup docs (as of 2022-02-27) do say that "devDependencies" is ignored., which breaks
  // everything. Right? Ugh.
  rollupConfig.plugins.splice(0, 0, nodeExternals({ devDeps: false, deps: true }))
}

if (pkglib.target.licenseText) {
  rollupConfig.plugins.splice(0, 0, license({
    banner: {
      commentStyle: 'ignored', // tells minifiers to leave it
      content: {
        file: pkglib.target.licenseText
      }
    }
  }))
}

export default rollupConfig

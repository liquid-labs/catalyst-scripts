import babel from 'rollup-plugin-babel'
import commonjs from 'rollup-plugin-commonjs'
import external from 'rollup-plugin-peer-deps-external'
import postcss from 'rollup-plugin-postcss'
import resolve from 'rollup-plugin-node-resolve'
import url from 'rollup-plugin-url'
import shell from 'shelljs'

const pkg = require(process.cwd() + '/package.json')

const commonjsConfig = {
  include: [ 'node_modules/**' ]
}
if (pkg.catalyst && pkg.catalyst.rollupConfig) {
  Object.assign(commonjsConfig, pkg.catalyst.rollupConfig.commonjsConfig)
}

export default {
  input: 'js/index.js',
  output: [
    {
      file: pkg.main,
      format: 'cjs',
      sourcemap: true
    },
    {
      file: pkg.module,
      format: 'es',
      sourcemap: true
    }
  ],
  watch: {
    clearScreen: false
  },
  plugins: [
    external(),
    postcss({
      modules: true
    }),
    url(),
    babel({
      exclude: 'node_modules/**',
      // '"modules": false' necessary for our React apps to work with the
      // distributed library.
      // TODO: does rollup handle the modules in this case?
      presets: [ ['@babel/preset-env', { "modules": false } ], '@babel/preset-react' ],
      plugins: [ "@babel/plugin-proposal-class-properties" ]
    }),
    resolve({ extensions: [ '.js', '.jsx' ]}),
    commonjs(commonjsConfig)
    // TODO: move this to ancillary docs.
    /*Attempted to create a 'yalc-push plugin', but there is just not
      'everything done' hook. The hooks are based on bundles and since we make
      multiple bundles, we tried to get clever, but it's to complicated. Also,
      'writeBundle' hook simply never fired for whatever reason.
      {
      name: 'yalc-push',
      generateBundle: function () {
        shell.exec(`COUNT=0 \
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

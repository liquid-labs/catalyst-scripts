import babel from 'rollup-plugin-babel'
import commonjs from 'rollup-plugin-commonjs'
import external from 'rollup-plugin-peer-deps-external'
import postcss from 'rollup-plugin-postcss'
import resolve from 'rollup-plugin-node-resolve'
import url from 'rollup-plugin-url'

let pkg = require(process.cwd() + '/package.json')

export default {
  input: 'src/index.js',
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
  plugins: [
    external(),
    postcss({
      modules: true
    }),
    url(),
    babel({
      exclude: 'node_modules/**',
      presets: [ '@babel/preset-env', '@babel/preset-react' ],
      plugins: [ "@babel/plugin-proposal-class-properties" ]
    }),
    resolve({ extensions: [ '.js', '.jsx' ]}),
    commonjs()
  ],
  onwarn: function (warning) {
    // https://docs.google.com/document/d/1f4iB4H4JGZ5LbqY-IX_2FXD47aq7ZouJYhjsnzrlUVg/edit#heading=h.g37mglv4gne6
    if (warning.code === 'THIS_IS_UNDEFINED') return;
    console.error(warning.message);
  }
}

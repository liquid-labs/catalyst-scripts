const { babelPresets, babelPlugins } = require('./babel-shared.config.js');

module.exports = function (api) {
  api.cache.invalidate(() => process.env.NODE_ENV === "production");

  return {
    presets: babelPresets,
    plugins: babelPlugins
  };
}

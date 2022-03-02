const { babelPresets, babelPlugins } = require('./babel-shared.config.js');

module.exports = function (api) {
  api.cache.invalidate(() => process.env.NODE_ENV === "production");

  return {
    assumptions: {
      privateFieldsAsProperties: true,
      setPublicClassFields: true
    },
    presets: babelPresets,
    plugins: babelPlugins
  };
}

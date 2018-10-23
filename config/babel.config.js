module.exports = function (api) {
  api.cache.invalidate(() => process.env.NODE_ENV === "production");

  const presets = [ '@babel/preset-env', '@babel/preset-react' ];
  const plugins = [ "@babel/plugin-proposal-class-properties" ];

  return {
    presets,
    plugins
  };
}

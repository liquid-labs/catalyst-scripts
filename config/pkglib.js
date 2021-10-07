const pkg = require(process.cwd() + '/package.json');

module.exports = {
  packageJson : pkg,
  target : {
    // support older catalyst data, but prefer liq
    rollupConfig: (pkg.liq && pkg.liq.rollupConfig) || (pkg.catalyst && pkg.catalyst.rollupConfig),
    isReactish : pkg.liq && pkg.liq.packageType && /(^|\|)react(\||$)/.test(pkg.liq.packageType),
    isNodeish : pkg.liq && pkg.liq.packageType && /(^|\|)node(\||$)/.test(pkg.liq.packageType),
    licenseText : pkg.liq && pkg.liq.licenseText
  }
}

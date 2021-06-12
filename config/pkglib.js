const pkg = require(process.cwd() + '/package.json');

module.exports = {
  packageJson : pkg,
  isTargetReactish : pkg.liq && pkg.liq.packageType && /\|react(\|$)/.test(liq.packageType)
}

# Babel Transforms & Polyfills

This document is tentative and should be understood as a starting point for
[further analysis](https://github.com/Liquid-Labs/catalyst-scripts/issues/9).

## Scope & audience

This document discusses the use and configuration of transforms and polyfills in
the Catalyst Scripts Babel configuration. It is aimed primarily at Catalyst
Script maintainers and also web developers.

The aim is to unpack the often terse technical definitions in the Babel
documents to provide background on the Catalyst Scripts approach, as well as a
basis for future discussion and iterative change as the configuration and
options available change over time. To this end, the
[Terms and overview](#terms-and-overview) section provides general background.
[Configuring shims](#configuring-shims) discusses our current approach and
analysis of the options available.

## Terms and overview

Babel's entire function is to transpile modern JavaScript into older, better
supported versions of the language. Polyfills and transforms are a piece of this
larger function and the nature of the tool itself is not critical.

The important point is that Babel does not provide browser _or_ language
normalization out of the box. E.g., Babel will transpile ES6 JavaScript syntax
into "vanilla" JS syntax, but functions (even those specified by the language)
are not supported out of the box, so the transpiled code will compile and run on
any target environment, but fail with a "method not found" error (see [A
critique of the Babel shim approach](#a-critique-of-the-babel-shim-approach)).

A polyfill is a term of art denoting a piece of code used to "fill in" missing
API in a web browser. Before "polyfill" was popularized, the somewhat clearer
and less jargony term "shim" was used to denote the same thing. So, we will use
the term 'shim' for the general idea and 'polyfill' to refer to specific
libraries and such which themselves use the term.

"Transforms", in this context, perform essentially the same function of allowing
developers to use modern and consistent API calls without regard to the
differences between various browser environments. The distinction being somewhat
that where a polyfill is specifically a "bit of code", a transform is more of a
process; a process that often involves adding polyfills.

## Configuring shims

Our current implementation uses the `transform-runtime` plugin as this is
compatible with Rollup and [the recommended configuration](https://github.com/rollup/rollup-plugin-babel#external-dependencies). `@babel/runtime` is included as a dependency of
the `catalyst-scripts` package so that it is transparently available to packages
which require it.

This is based on analysis and testing with four different approaches:

1) Import the shim code explicitly.
2) Use Babel 'polyfill' plugin.
3) Use Babel 'transform runtime' plugin.
4) Use Babel `env` preset `useBuiltIns`.

This analysis is based on some testing and research, but by no means definitive.

### Importing shims

This introduces additional dependencies in the code. The bigger problem, though,
is that this breaks the goal of adopting a single standard for code and requires
manual analysis of each code base by developers. We'd like to use Babel to
generate "run anywhere code", with dynamic inclusion of any shims.

### Babel polyfill plugin

`plugin-polyfill` appears to have been a common option in the past. However,
most of the chatter now-a-days seems focused on the `transform-runtime` plugin
or `useBuiltIns` option (of the `env` preset). There appear to be some technical
differences between the polyfill and transform approach, but they are similar
and the transform approach appears better supported.

### Babel transform runtime plugin

The `transform-runtime` plugin (seemingly) performs much the same function as
the polyfill plugin, but appears better supported and is, for instance, _the_
solution mentioned in the [Rollup-Babel plugin docs](https://github.com/rollup/rollup-plugin-babel).

### Preset `env` `useBuiltIns='usage'`

This is by far the simplest solution in terms of configuration and dependencies.
The better name would be 'useCoreJSPolyfills' and the behavior is to import
the necessary corejs shims as needed.

The 'entry' requires the user to add or configure the `@babel/polyfill` module
be required at the top of the app, which is then transformed into the individual
imports needed. The 'usage' configuration imports as needed, referencing the
global import and requires no additional configuration or dependencies.

The `useBuiltIns` options is by the simplest, but currently leads to
larger code bundles. Our own, perhaps naive, testing showed significant increase
in packed libraries. Further analysis is required, but based on issues and
very light analysis, it seems that the multiple imports do not get reconciled
by Rollup, even when configured to do so. As support for this currently
"experimental" feature improves, we may want to revisit it.






## Appendix : A critique of the Babel shim approach

The distinction between "syntax" and "functions", where the first is supported
out of the box, but the second must be configured seems a bit arbitrary in
practice. Consider the modern code: `const a = await f()`. Here, `await` is a
feature of ES6 syntax which performs the function of "waiting on a Promise to
complete and returning the positive result or raising on error on failure".

There is effectively no way of transpiling `await` syntax without also
introducing code shims of some sort. In other words, there is no syntax mapping
that doesn't require a shim or polyfill of some sort.

This creates a situation where Babel happily transpiles input code without error
or complaint, except the resulting code isn't really transpiled in any
meaningful sense since it cannot run on the target system without also
configuring additional shimming mechanisms. In other words, Babel doesn't
actually transpile ES6 to vanilla JavaScript out of the box.

That Babel makes an internal distinction between "transpiling syntax" and
"shimming functions" is entirely understandable. And from a historical
perspective, the current state of affairs makes sense. E.g., I suspect that in
the early days, transpiling was (mostly) sufficient and, of course, the initial
and primary focus. Then there naturally plugins to do "other stuff" with the
code. So, when the need for shimming was addressed, it was implemented as
plugins rather than the core code set.

But really, a working shim configuration should be merged to native, or at least
integrated as part of the standard presets. This would preserve the ability to
choose alternate plugins while making Babel actually do what users expect it to
do without a lot of additional research and heartache.

Although not quite the "out of the box" solution we'd like, the
[`useBuiltIns`](https://babeljs.io/docs/en/babel-preset-env#usebuiltins)
configuration option introduced in Babel 7 [`env` preset](https://babeljs.io/docs/en/babel-preset-env)
comes close, but fails to interact well with Rollup (at least) and so results in
non-optimal code.

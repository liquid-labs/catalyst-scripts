# Babel Transforms & Polyfills

## Scope & audience

This document discusses the use and configuration of transforms and polyfills in
the Catalyst Scripts Babel configuration. It is aimed primarily at Catalyst
Script maintainers and also web developers.

The aim is to unpack the often terse technical definitions in the Babel
documents to provide background on the Catalyst Scripts approach, as well as a
basis for future discussion and iterative change as the configuration and
options available change over time. To this end, the
[Terms and overview](#terms-and-overview) section provides general background.
[Configuring shims in Babel](#configuring-shims-in-babel) discusses the options
available in Babel, and
[Shimming for Catalyst projects](#shimming-for-catalyst-projects) discusses the
method and reasoning behind our particular approach.

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

## Configuring shims in Babel

There are currently four known approaches to shimming:

1) Import the shim code explicitly.
2) Use Babel 'polyfill' plugin.
3) Use Babel 'transform runtime' plugin.
4) Use Babel `env` preset `useBuiltIns`.

Our current implementation uses the `transform-runtime` plugin as this is
compatible with Rollup and the recommended configuration. This does mean that
libraries need to include `@babel/runtime` as a dependency so that the necessary
shims included in the transpiled code and/or code bundle.

The `useBuiltIns` options is by the simplest, but currently leads to
larger code bundles. Our own, perhaps naive, testing showed significant increase
in packed libraries. Further analysis is required, but based on issues and
very light analysis, it seems that the multiple imports do not get reconciled
by Rollup, even when configured to do so. As support for this currently
"experimental" feature improves, we may want to revisit it.

The following analysis is based on some testing and research, but by no means
definitive.

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

`plugin-polyfills` or `plugin-transform-runtime` plugins, which had slightly
different behavior, configuration, and dependency requirements but which
performed the same essential function. If you search around the web (in March
2019 at least), you'll find a lot of discussion on how to handle polyfills and
these solutions discussed at length. In particular, this is (most?) often in the
context of the `regeneratorRuntime` problem encountered when using ES6 `await`
syntax.

Babel 7 went a long way towards simplifying things by rolling much of the
functionality into the standard `env` preset and greatly simplifying
configuration (to a single parameter) and dependencies (none other than
`@babel/preset-env`).

Well, easy that is if using the `usage` option of `useBuiltIns`, with the only
caveat being that the `usage` option is noted as 'experimental' asa of
March 2019 / Babel 7.4. It's use is widely adopted and we have had no issues
with it beyond configuration confusion due to all the prior ink on the other
methods and Babel's own rather terse and mechanistic description of how all this
works.

## Shimming for Catalyst projects

In both direct Babel translation (used in testing and application packing) and
as part of the Rollup-Babel configuration (used in library packing), we utilize
the `useBuiltIns: 'usage'` option in the `env` preset. This is certainly the
simplest from both a configuration and requirements perspective, and seems to be
where Babel is headed in terms of the "best practice" approach.

Because the Babel (and Rollup) documentation don't really address the practical
effects or (AFAIK) discuss shimming from an overview perspective, it's unclear
whether this leaves something to be desired as far as code compactness. In
particular, the polyfill and runtime transform plugins [seem to have had
different implications in terms of code size](https://stackoverflow.com/questions/31781756/is-there-any-practical-difference-between-using-babel-runtime-and-the-babel-poly), but no recent comparison between
the different approaches is known to us.

Furthermore, the [Rollup discussion on 'external dependencies'](https://github.com/rollup/rollup-plugin-babel#external-dependencies) and Babel configuration doesn't even mention the `env` preset
`useBuiltIns` option (as of March 2019).

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

To be fair, since version 7, Babel come quite close to the ideal with the
[`useBuiltIns`](https://babeljs.io/docs/en/babel-preset-env#usebuiltins)
configuration option in the
[`env` preset](https://babeljs.io/docs/en/babel-preset-env). Under the covers,
the
[`plugin-transform-runtime`](https://babeljs.io/docs/en/babel-plugin-transform-runtime)
is included in the preset and it's `useBuiltIns` options hoisted to the preset
configuration. Really, if `usage` were just made the default, all would be well.
Hopefully, this is the direction things are headed.

In particular, in the Babel 7 migration docs, it talks [about configuration
changes necessary to use the `plugin-runtime-transform`](https://babeljs.io/docs/en/v7-migration#babel-runtime-babel-plugin-transform-runtime) without ever mentioning that the `useBuiltIns: 'usage'`
option is available to accomplish (much?) the same task.

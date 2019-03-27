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
supported versions of the language. Polyfills and transforms are simply a tool
used to accomplish this larger function and the nature of the tool itself is not
critical.

The important point is that Babel does not provide "browser API normalization"
out of the box. In other words, Babel will transpile ES6 JavaScript syntax into
"vanilla" JS syntax, but functions (even those specified by the language) not
supported "as is",  leaving us in a situation where the transpiled code will
compile and run on any target environment, but fail with a "method not found"
error (see [A critique of the Babel shim approach](#a-critique-of-the-babel-shim-approach))

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

Babel provides two methods for shimming code

## Shimming for Catalyst projects

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

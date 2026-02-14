# snippet-ls-hs

An LSP server that provides code snippet completions. Ported to Haskell from my initial TypeScript implementation.

This project isn't designed for a broad audience or general purpose distribution. It is public simply to make it easy to install and use across multiple machines (read: work laptop) without extra friction.

> **WIP:** Snippets are currently hardcoded. `SNIPPETS_PATH` is not yet wired up.

## Install

```bash
devenv shell
cabal build
cabal install
```

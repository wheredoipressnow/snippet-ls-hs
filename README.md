# snippet-ls-hs

An LSP server that provides code snippet completions. Ported to Haskell from my initial TypeScript implementation.

This project isn't designed for a broad audience or general purpose distribution. It is public simply to make it easy to install and use across multiple machines (read: work laptop) without extra friction.

## Install

```bash
devenv shell
cabal build
cabal install
```

## Usage

```bash
snippet-ls-hs /path/to/snippets
```

Snippet files are JSON arrays placed in the snippets directory (see `snippets/elixir.json` for my Elixir snippets).

## Helix Configuration

Add the language server in the `language.toml`:

```toml
[language-server.snippet-ls]
command = "<path to snippet-ls-hs executable>"
args = ["<path to snippets>"]

[[language]]
name = "elixir"
language-servers = ["elixir-ls", "snippet-ls"]
```

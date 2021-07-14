# Hello Gleam: Library

A Gleam project trying to emulate different systems interacting.

## Quick start

```sh
# Run the Erlang REPL
rebar3 shell
> hellogleam:main().
```

## Actors

### The Library

The library has a collection of books organised by categories, and you can order or return from it.

### Clients

Clients have a preference in book types, and will try to order a book in said category (for now they have no memory of what they have read).

# bitcoind

Implementation of the bitcoind daemon in [Elixir](http://elixir-lang.org/).

For now only a simple command line tool exists. You need to have Elixir 1.0.2
installed. In order to compile the CLI tool, run:

    $ mix escript.build

Which should compile a `bitcoind` exectutable.

Run `./bitcoind --help` to see what you can do.

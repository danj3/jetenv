# Jetenv

Full Application configuration from only the environment by using
a predictable and direct name translation into config node plus
type specification and bundled/armored encoding for complex types.

## Background

Given that Application configuration is a tree data structure comprised of 
Keyword lists, addressing any point in the KW hierarchy can be expressed as
a path. If the implied root of the structure is the application controller
and the next nodes are the applications (otp_app atoms), then a path can
be built to locate/set configuration at any point.

## Environment Design limits

The POSIX standards place limits on variable names, but none on values.
Modern systems provide an ARG_MAX of about 4MiB, so considerable data
space is available.

POSIX programs use upper case variable names, lower case is reserved for
applications. The only special character is the underscore `_`.

## Variable name construction

* Path segments are separated by a double underscore `__`
* Variables use a common prefix (default is `je`), allows automatic configuration
* A required type suffix allows automatic interpolation

Example:

```
je__my_app__some_thing__S="A string value"

```

## Types supported

See `Jetenv`

## Generator

Included is a mix task, `mix jetenv.generate` that can emit documents that
can be used to perform environment set up for:

* docker api
* javascript (ts/CDK)
* shell

See `mix help jetenv.generate`

To see an example, run `mix jetenv.generate elixir`.

### Generation Limitations

A docker `--env-file` is not directly supported because that format
doesn't support multi-line values. The format is neither shell nor
json. It has no escaping mechanism.

For deployment into any orchestration, this is not usually a problem. For
local docker development it is a hassle. One option it to generate a shell format
file and source it within the container prior to starting elixir. The other
approach is to use the Docker API (which is JSON) to create and then start
a container.

## Use

In your config/runtime.exs add:

```
Jetenv.load_env()
```

This will load from the environment using the default prefix `je`.

## Loaded applications

The `Jetenv.load_env()/0` function will filter available configuration
to include only loaded applications. Use `Jetenv.load_all_env()/0`
to bypass that filter. If Application does not know about
an otp_app in that case, you will see a warning:

```
You have configured application :app in your configuration file,
but the application is not available.

This usually means one of:

  1. You have not added the application as a dependency in a mix.exs file.

  2. You are configuring an application that does not really exist.

Please ensure :app exists or remove the configuration.
```

This message is harmless.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jetenv` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jetenv, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/jetenv>.


# Jetenv

Complete application configuration from the system environment with
an intuitive schema that includes type casting while minimizing
`runtime.exs` to only two lines.

## Comparison for Repo configuration

A brief example, more details in below sections, to illustrate
how Jetenv works by comparing it to the conventional runtime
configuration method.

### Conventional approach
A representative [`runtime.exs`](`m:Mix#module-runtime-configuration`)
fragment to configure a Repo from the environment:

```
config :example, Example.Repo, [
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  hostname: System.get_env("DB_HOSTNAME"),
  database: System.get_env("DB_DATABASE"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer()
]
```

An `env.sh` file that would supply these values:
```
set -a
DB_USERNAME="postgres"
DB_PASSWORD="postgres"
DB_HOSTNAME="localhost"
DB_DATABASE="example_dev"
DB_PORT="5432"
set +a
```

### Jetenv approach

The Jetenv alternative skips the `runtime.exs` coding/mapping entirely and
replaces it with a single line:
```
Jetenv.load_env()
```

Now the equivalent `env.sh`, looks like:
```
set -a
je__example__Elixir_Example_Repo__database__S="example_dev"
je__example__Elixir_Example_Repo__hostname__S="localhost"
je__example__Elixir_Example_Repo__password__S="postgres"
je__example__Elixir_Example_Repo__username__S="postgres"
je__example__Elixir_Example_Repo__port__I="5432"
set +a
```

### Key improvements

Observe that:
* The configuration is stated one less time
* The Jetenv structured environment provides direct name translation, the name tells exactly what is being configured
* No ad-hoc names have to be created and managed over time
* The `runtime.exs` does not obscure the mapping of the external environment to the Application environment
* Type conversion is driven by the input name
* Any config node can be configured without code changes

With ad-hoc names in the conventional approach, adding a second Repo 
would involve having to invent another set of ad-hoc names that
are different than the `DB_` names, leading to more knowledge embedded in `runtime.exs`, possibly
having to rename things (breaking changes), and neither may be quite precise or fully descriptive.
Avoiding this problem by using the real name being configured in the Jetenv approach
removes the need to invent names, is forward compatible, and always descriptive.

By not having to code translations in `runtime.exs` also means anything and everything
can be configured via the environment. This can be crucial in production and debugging
scenarios.

### Validation illusion
The conventional method might seem safer, providing an opportunity to check types, formats and
inputs. However, the validation task is much more complex and best not left to ad-hoc code in
`runtime.exs`. There are also other ways for config to be merged into the application controller.
For true declarative validation, look at incorporating `m:NimbleOptions` into Application start up.


# Design Background

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
* Names use a common prefix (default is `je`), allows automatic discovery and configuration
* A required type suffix allows automatic interpolation

Example:

```
je__my_app__some_thing__S="A string value"

```

This is equivalent to
```
config :my_app, :some_thing, "A string value"
```

## Types supported

See `m:Jetenv`

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

Jetenv is [available in Hex](https://hex.pm/packages/jetenv).
The package can be installed
by adding `jetenv` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jetenv, "~> 0.1.1"}
  ]
end
```


Documentation can be found at <https://hexdocs.pm/jetenv>.


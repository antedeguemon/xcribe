![Hex.pm](https://img.shields.io/hexpm/v/xcribe?style=flat-square)
![Hex.pm](https://img.shields.io/hexpm/l/xcribe?style=flat-square)
![Hex.pm](https://img.shields.io/hexpm/dt/xcribe?style=flat-square)

# XCribe

XCribe is a doc generator for Rest APIs built with Phoenix.
The documentation is generated by the test specs.

Currently both Blueprint and Swagger (OpenAPI Spec 3.0) syntax is supported. In the future other formats will
be added.

## Installation

Add XCribe to your application

mix.exs

```elixir
def deps do
  [
    {:xcribe, "~> 0.5.0"}
  ]
end
```

Update deps

```sh
mix deps.get
```

XCribe requires that you create an "Information Module". This module define
the custom information about your API documentation.

Create a module that uses `Xcribe.Information`

```elixir
defmodule YourAppWeb.Support.DocInformation do
  use Xcribe.Information

  xcribe_info do
    name "Your awesome API"
    description "The best API on the world"
    host("http://your-api.us")
  end
end
```

Add a new configuration with the created module

config/test.exs

```elixir
  config :xcribe, :information_source, YourAppWeb.Support.DocInformation
  config :xcribe, :doc_format, :api_blueprint # or :swagger
```

Next, in your `test/test_helper.exs` you should configure ExUnit to use XCribe
formatter. You would probably like to keep the default ExUnit.CLIFormatter as
well.

test/test_helper.exs

```elixir
 ExUnit.start(formatters: [ExUnit.CLIFormatter, Xcribe.Formatter])
```

## Usage

XCribe generates documentation from `Plug.Conn` struct used on your tests. To
document a route you need pass the `conn` struct to macro `document`.

First import the module `Xcribe.Helpers.Document` on your `/test/support/conn_case.ex`,
that way you will have the `document` macro available on your test specs.

/test/support/conn_case.ex

```elixir
defmodule YourAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do

     ...

      # import Xcribe macro
      import Xcribe.Helpers.Document

     ...

    end
  end
end
```

Now in your tests you should call the macro `document` with the conn struct

```elixir
test "get posts", %{conn: conn} do

  response =
    conn
    |> get("/posts")
    |> document()
    |> json_response(200)

  assert response == []
end
```

you can specify a custom request name by passing an argument `as: "description"`
to the macro

```elixir
test "get posts", %{conn: conn} do

  response =
    conn
    |> get("/posts")
    |> document(as: "index request")
    |> json_response(200)

  assert response == []
end
```

To generate the doc file run `mix test` with an env var `XCRIBE_ENV=true`

```sh
XCRIBE_ENV=true mix test
```

A file `api_doc.apib` will be created with the documentation if ApiBlueprint is configured. If Swagger format is chosen, then `openapi.json` file will be created.

### Rendering HTML

The output file is write in Blueprint sintax. To render to HTML you can use the
tools listed at [APIBLUEPRINT.ORG](https://apiblueprint.org/tools.html#renderers)

If Swagger format is configured, [Swagger UI](https://swagger.io/tools/swagger-ui/download/) can be used to display Swagger documentation.

## Configure

You can add this configurations to your `config/test.ex`

-   information_source: the module with doc information
-   output: a custom name to the output file
-   format: ApiBlueprint or Swagger formats
-   env_var: a custom name to the env to active XCribe.Formatter
-   json_library: The library to be used for json decode/encode. See `Xcribe.JSON`

Example

```elixir
config :xcribe, [
  information_source: YourAppWeb.Information,
  output: "API-DOCUMENTATION.apib",
  format: :swagger # or :api_blueprint,
  env_var: "DOC_API",
  json_library: Jason
]
```

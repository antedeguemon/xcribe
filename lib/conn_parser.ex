defmodule Xcribe.ConnParser do
  alias Xcribe.{Config, Request}

  def execute(conn, description \\ "sample request") do
    conn
    |> identify_route()
    |> parse_conn(conn, description)
  end

  defp parse_conn({:error, _} = error, _conn, _description), do: error

  defp parse_conn(route, conn, description) do
    path = format_path(route.route, Map.keys(conn.path_params))
    namespaces = fetch_namespaces()

    %Request{
      action: route |> router_options() |> Atom.to_string(),
      header_params: conn.req_headers,
      controller: controller_module(route),
      description: description,
      params: conn.params,
      path: path,
      path_params: conn.path_params,
      query_params: conn.query_params,
      request_body: conn.body_params,
      resource: resource_name(path, namespaces),
      resource_group: resource_group(route),
      resp_body: conn.resp_body,
      resp_headers: conn.resp_headers,
      status_code: conn.status,
      verb: String.downcase(conn.method)
    }
  end

  defp identify_route(%{method: method, host: host, path_info: path} = conn) do
    conn
    |> router_module
    |> apply(:__match_route__, [method, decode_uri(path), host])
    |> extract_route_info()
  end

  defp router_module(%{private: %{phoenix_router: router}}), do: router

  defp decode_uri(path_info), do: Enum.map(path_info, &URI.decode/1)

  defp extract_route_info({%{} = route_info, _, _, _}), do: route_info
  defp extract_route_info(_), do: {:error, "route not found"}

  defp router_options(%{plug_opts: opts}), do: opts
  defp router_options(%{opts: opts}), do: opts

  defp controller_module(%{plug: controller}), do: controller

  defp resource_group(%{pipe_through: [head | _rest]}), do: head

  defp resource_name(path, namespaces) do
    namespaces
    |> Enum.reduce(path, &remove_namespace/2)
    |> String.split("/")
    |> Enum.filter(&Regex.match?(~r/^\w+$/, &1))
    |> Enum.join("_")
  end

  defp remove_namespace(namespace, path), do: String.replace(path, ~r/^#{namespace}/, "")

  defp format_path(path, params), do: Enum.reduce(params, path, &transform_param/2)

  defp transform_param(param, path), do: String.replace(path, ":#{param}", "{#{param}}")

  defp fetch_namespaces, do: apply(Config.xcribe_information_source(), :namespaces, [])
end

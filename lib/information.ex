defmodule Xcribe.Information do
  defmacro __using__(_opts \\ []) do
    quote do
      import Xcribe.Information

      @before_compile Xcribe.Information
    end
  end

  defmacro xcribe_info(controller, do: information) do
    resource_desc = fetch_information(information, :description)
    actions = fetch_information(information, :actions, [])
    parameters = information |> fetch_information(:parameters, []) |> stringfy_keys()

    quote bind_quoted: [
            actions: actions,
            controller: controller,
            resource_desc: resource_desc,
            parameters: parameters
          ] do
      def resource_description(unquote(controller)), do: unquote(resource_desc)

      def resource_parameters(unquote(controller)), do: Map.new(unquote(parameters))

      actions
      |> Enum.each(fn {action, action_info} ->
        action_name = Atom.to_string(action)
        action_desc = fetch_key(action_info, :description, nil)
        action_params = action_info |> fetch_key(:parameters, []) |> stringfy_keys()

        def action_description(unquote(controller), unquote(action_name)),
          do: unquote(action_desc)

        def action_parameters(unquote(controller), unquote(action_name)),
          do: Map.new(unquote(action_params))
      end)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def resource_description(_), do: nil
      def resource_parameters(_), do: %{}
      def action_description(_, _), do: nil
      def action_parameters(_, _), do: %{}
    end
  end

  defp fetch_information({_, _, data}, key, default \\ nil) do
    data
    |> Enum.find(fn {k, _, _} -> k == key end)
    |> case do
      {_, _, [found | _t]} -> found
      _ -> default
    end
  end

  def stringfy_keys(keyword),
    do: Enum.map(keyword, fn {key, value} -> {to_string(key), value} end)

  def fetch_key(keyword, key, default) do
    case Keyword.fetch(keyword, key) do
      {:ok, value} -> value
      _ -> default
    end
  end
end

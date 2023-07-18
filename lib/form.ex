defmodule HtmlQuery.Form do
  # @related [test](test/form_test.exs)

  @moduledoc false

  @doc """
  Returns a map containing the names and values of a form's fields that a browser would send had the form been
  submitted. In addition, expands compound input names (`person[name][first]`) into nested maps
  (`%{person: %{name: %{first: "Alice"}}}`), and collects all checkbox values if the input name ends with `[]`
  (`person[favorite_colors][]`). Normally accessed via `HtmlQuery.form_data`.
  """
  def form_data(_html, _opts \\ []),
    do: nil

  @doc """
  Returns a list of all the form's input tags (in order). Should be accessed via `HtmlQuery.form_input_tags`.
  """
  def input_tags(html),
    do: HtmlQuery.all(html, "input, select, textarea") |> List.foldr([], &input_tag/2)

  # # #

  @allowed_input_tags ~w[input option select textarea]
  defp input_tag({tag, attrs, content}, acc) when tag in @allowed_input_tags do
    tag = String.to_atom(tag)
    map = Map.new(attrs)

    map =
      case {tag, content} do
        {:select, options} -> Map.put(map, "options", List.foldr(options, [], &input_tag/2))
        {_, []} -> map
        {_, other} -> Map.put(map, "@content", Enum.join(other))
      end

    [{tag, map} | acc]
  end

  # # # old

  defmodule Attrs do
    @moduledoc false

    defstruct checked?: false, name: nil, type: nil, value: nil

    def new(floki_attrs) do
      floki_attrs
      |> Enum.reduce(%__MODULE__{}, fn
        {"checked", _}, attrs -> %{attrs | checked?: true}
        {"name", name}, attrs -> %{attrs | name: name}
        {"type", type}, attrs -> %{attrs | type: type}
        {"value", value}, attrs -> %{attrs | value: value}
        _, attrs -> attrs
      end)
    end
  end

  @doc """
  Returns a map containing the form fields in `html`. See docs for `HtmlQuery.form/1`.
  """
  @spec fields(Floki.html_tree(), keyword()) :: map()
  def fields(html, _opts \\ []) do
    HtmlQuery.all(html, "input[name], select[name], textarea[name]")
    |> Enum.reduce(%{}, &field/2)
    |> expand_input_names()
    |> Moar.Map.deep_atomize_keys()
  end

  @spec field(Floki.html_node(), map()) :: map()
  defp field({element_name, attrs, contents} = _element, acc) do
    attrs = Attrs.new(attrs)

    case {element_name, attrs.type} do
      {"input", "checkbox"} ->
        if attrs.checked?,
          do: Map.update(acc, attrs.name, [attrs.value], fn existing -> List.wrap(existing) ++ [attrs.value] end),
          else: Map.put_new(acc, attrs.name, [])

      {"input", "radio"} ->
        if attrs.checked?,
          do: Map.put(acc, attrs.name, attrs.value),
          else: acc

      {"input", "submit"} ->
        acc

      {"input", _} ->
        if attrs.value,
          do: Map.put(acc, attrs.name, attrs.value),
          else: acc

      {"select", _} ->
        case HtmlQuery.find(contents, "option[selected]") do
          nil -> Map.put(acc, attrs.name, "")
          option -> Map.put(acc, attrs.name, HtmlQuery.text(option))
        end

      {"textarea", _} ->
        Map.put(acc, attrs.name, HtmlQuery.text(contents))

      {_, _} ->
        acc
    end
  end

  @spec expand_input_names(map()) :: map()
  defp expand_input_names(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      case expand_input_name(key) do
        {key1, key2} -> %{key1 => %{key2 => value}}
        key -> %{key => value}
      end
      |> Moar.Map.deep_merge(acc)
    end)
  end

  @spec expand_input_name(binary()) :: binary() | {binary(), binary()}
  defp expand_input_name(input_name) do
    case Regex.run(~r|(.*)\[(.*)\]|, input_name) do
      [_, child, ""] -> expand_input_name(child)
      [_, parent, child] -> {parent, child}
      _ -> input_name
    end
  end
end

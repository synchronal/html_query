defmodule HtmlQuery.Form do
  # @related [test](test/form_test.exs)

  @moduledoc false

  @doc """
  Returns a map containing the names and values of a form's fields that a browser would send had the form been
  submitted. In addition, expands compound input names (`person[name][first]`) into nested maps
  (`%{person: %{name: %{first: "Alice"}}}`), and collects all checkbox values if the input name ends with `[]`
  (`person[favorite_colors][]`). Normally accessed via `HtmlQuery.form_data`.
  """
  def form_data(html, _opts \\ []) do
    html
    |> input_tags()
    |> Enum.reduce(%{}, &form_datum/2)
    |> expand_composite_keys()
    |> Moar.Map.deep_atomize_keys()
  end

  @doc """
  Returns a list of all the form's input tags (in order). Should be accessed via `HtmlQuery.form_input_tags`.
  """
  def input_tags(html),
    do: HtmlQuery.all(html, "input, select, textarea") |> List.foldr([], &input_tag/2)

  # # #

  defp input_tag({tag, attrs, content}, acc) when tag in ~w[input option select textarea] do
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

  defp form_datum({tag, attrs}, acc) when tag in ~w[input option select textarea]a do
    has_name? = Moar.Term.present?(attrs["name"]) || tag == :option
    has_content? = Moar.Term.present?(attrs["@content"])
    not_disabled? = !Map.has_key?(attrs, "disabled")
    checkable? = attrs["type"] in ["checkbox", "radio"]
    checked? = Map.has_key?(attrs, "checked")
    multiple? = tag == :select && Map.has_key?(attrs, "multiple")

    case {has_name? && not_disabled?, tag} do
      {false, _} ->
        acc

      {true, :input} ->
        if !checkable? || (checkable? && checked?),
          do: Map.put(acc, attrs["name"], attrs["value"]),
          else: acc

      {true, :option} ->
        if attrs["selected"] == "selected",
          do: [attrs["value"] || attrs["@content"] | acc],
          else: acc

      {true, :select} ->
        options = Map.get(attrs, "options", []) |> List.foldr([], &form_datum/2)

        if multiple?,
          do: Map.put(acc, attrs["name"], options || []),
          else: Map.put(acc, attrs["name"], List.last(options))

      {true, :textarea} ->
        if has_content?,
          do: Map.put(acc, attrs["name"], attrs["@content"]),
          else: acc
    end
  end

  # todo: move to Moar.Map
  def expand_composite_key(key),
    do: String.split(key, ["[", "]"], trim: true)

  # todo: move to Moar.Map
  def expand_composite_keys(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      keys = Enum.map(expand_composite_key(key), &Access.key(&1, %{}))
      get_and_update_in(acc, keys, &{&1, value}) |> elem(1)
    end)
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
    |> expand_composite_keys()
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
end

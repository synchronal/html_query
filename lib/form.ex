defmodule HtmlQuery.Form do
  # @related [test](test/form_test.exs)
  @moduledoc """
  Form-handling functions. Most of the time, `HtmlQuery.form_fields/1` should be used instead of calling these
  functions directly.
  """

  def fields(html) do
    %{}
    |> form_field_values(
      html,
      "input[value][name]:not([type=radio]):not([type=checkbox])",
      :term,
      &HtmlQuery.attr(&1, "value")
    )
    |> form_field_values(html, "input[name][type=checkbox]", :list_or_term, &checked_value/1)
    |> form_field_values(html, "input[name][type=radio]", :term, &checked_value/1)
    |> form_field_values(html, "textarea[name]", :term, &HtmlQuery.text/1)
    |> form_field_values(html, "select[name]", :term, &selected_option/1)
    |> Moar.Map.deep_atomize_keys()
  end

  @spec form_field_values(
          map(),
          HtmlQuery.html(),
          HtmlQuery.Css.selector(),
          :term | :list | :list_or_term,
          (HtmlQuery.html() -> binary())
        ) :: map()
  defp form_field_values(acc, html, selector, value_type, value_fn) do
    html
    |> HtmlQuery.all(selector)
    |> Enum.reduce(acc, &form_field_value(&2, &1, value_type, value_fn))
  end

  @spec form_field_value(map(), HtmlQuery.html(), :term | :list | :list_or_term, (HtmlQuery.html() -> binary())) ::
          map()
  defp form_field_value(acc, input, value_type, value_fn) do
    value_type =
      case value_type do
        :list_or_term ->
          name = HtmlQuery.attr(input, "name") || ""
          if String.ends_with?(name, "[]"), do: :list, else: :term

        other ->
          other
      end

    value = value_fn.(input)
    value = if value_type == :list, do: List.wrap(value), else: value

    map =
      case input |> HtmlQuery.attr("name") |> unwrap_input_name() do
        {key1, key2} -> %{key1 => %{key2 => value}}
        key -> %{key => value}
      end

    update_fn =
      case value_type do
        :term -> fn _old, new -> new end
        :list -> fn old, new -> (old ++ new) |> Enum.reject(&Moar.Term.blank?/1) end
      end

    Moar.Map.deep_merge(acc, map, fn old, new -> if Moar.Term.present?(new), do: update_fn.(old, new), else: old end)
  end

  @spec checked_value(HtmlQuery.html()) :: binary()
  defp checked_value(checkbox_or_radio) do
    case HtmlQuery.attr(checkbox_or_radio, "checked") do
      nil -> nil
      _ -> HtmlQuery.attr(checkbox_or_radio, "value")
    end
  end

  @spec selected_option(HtmlQuery.html()) :: binary()
  defp selected_option(select) do
    case HtmlQuery.find(select, "option[selected]") do
      nil -> ""
      option -> HtmlQuery.attr(option, "value") || HtmlQuery.text(option)
    end
  end

  @spec unwrap_input_name(binary()) :: binary() | {binary(), binary()}
  defp unwrap_input_name(input_name) do
    case Regex.run(~r|(.*)\[(.*)\]|, input_name) do
      [_, child, ""] -> unwrap_input_name(child)
      [_, parent, child] -> {parent, child}
      _ -> input_name
    end
  end
end

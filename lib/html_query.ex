defmodule HtmlQuery do
  # @related [test](/test/html_query_test.exs)

  @moduledoc """
  Some simple HTML query functions. Delegates the hard work to [Floki](https://hex.pm/packages/floki).

  ## Data types

  All functions accept HTML in the form of a string, a Floki HTML tree, or a Floki HTML node.
  Others expect only a Floki HTML node or a Floki HTML tree. See `t:HtmlQuery.html/0`.

  Some functions take a CSS selector, which can be a string, a keyword list, or a list.
  See `t:HtmlQuery.Css.selector/0`.

  ## Main query functions

  The main query functions take an HTML string or some parsed HTML, and a selector.

  | `all/2`         | return all elements matching the selector          |
  | `find/2`        | return the first element that matches the selector |
  | `find!/2`       | return the only element that matches the selector  |

  ## Parsing functions

  | `parse/1`     | parses an HTML fragment into a [Floki HTML tree] |
  | `parse_doc/1` | parses an HTML doc into a [Floki HTML tree]      |

  ## Extraction functions

  | `attr/2`        | returns the attribute value as a string              |
  | `form_fields/1` | returns the names and values of form fields as a map |
  | `meta_tags/1`   | returns the names and values of metadata fields      |
  | `text/1`        | returns the text contents as a single string         |

  ## Utility functions

  | `inspect_html/2` | prints prettified HTML with a label |
  | `normalize/1`    | parses and re-stringifies HTML      |
  | `pretty/1`       | prettifies HTML                     |


  ## Alias

  If you use HtmlQuery a lot, you may want to alias it to the recommended shortcut "Hq":
  ```elixir
  alias HtmlQuery, as: Hq
  ```

  ## Examples

  Get the value of a selected option:

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.find(html, "select option[selected]") |> HtmlQuery.attr("value")
  "a"
  ```

  Get the text of a selected option, raising if there are more than one:

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.find!(html, "select option[selected]") |> HtmlQuery.text()
  "apples"
  ```

  Get the text of all the options:

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.all(html, "select option") |> Enum.map(&HtmlQuery.text/1)
  ["apples", "bananas"]
  ```

  Use a keyword list as the selector (see `HtmlQuery.CSS` for details on selectors):

  ```elixir
  iex> html = ~s|<div> <a href="/logout" test-role="logout-link">logout</a> </div>|
  iex> HtmlQuery.find!(html, test_role: "logout-link") |> HtmlQuery.attr("href")
  "/logout"
  ```
  """

  @module_name __MODULE__ |> Module.split() |> Enum.join(".")

  @typedoc "A string or atom representing an attribute name. If an atom, underscores are converted to dashes."
  @type attr() :: binary() | atom()

  @typedoc """
  A string, a struct that implements the `String.Chars` protocol,
  a [Floki HTML tree], or a [Floki HTML node].

  [Floki HTML tree]: https://hexdocs.pm/floki/Floki.html#t:html_tree/0
  [Floki HTML node]: https://hexdocs.pm/floki/Floki.html#t:html_node/0
  """
  @type html() :: binary() | String.Chars.t() | Floki.html_tree() | Floki.html_node()

  # # #

  @doc """
  Finds all elements in `html` that match `selector`, returning a Floki HTML tree.

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.all(html, "option")
  [
    {"option", [{"value", "a"}, {"selected", "selected"}], ["apples"]},
    {"option", [{"value", "b"}], ["bananas"]}
  ]
  ```
  """
  @spec all(html(), HtmlQuery.Css.selector()) :: Floki.html_tree()
  def all(html, selector), do: html |> parse() |> Floki.find(HtmlQuery.Css.selector(selector))

  @doc """
  Finds the first element in `html` that matches `selector`, returning a Floki HTML node.

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.find(html, "select option[selected]")
  {"option", [{"value", "a"}, {"selected", "selected"}], ["apples"]}
  ```
  """
  @spec find(html(), HtmlQuery.Css.selector()) :: Floki.html_node() | nil
  def find(html, selector), do: all(html, selector) |> List.first()

  @doc """
  Like `find/2` but raises unless exactly one element is found.
  """
  @spec find!(html(), HtmlQuery.Css.selector()) :: Floki.html_node()
  def find!(html, selector), do: all(html, selector) |> first!()

  # # #

  @doc """
  Returns the value of `attr` from the outermost element of `html`.
  If `attr` is an atom, any underscores are converted to dashes.

  ```elixir
  iex> html = ~s|<div> <a href="/logout" test-role="logout-link">logout</a> </div>|
  iex> HtmlQuery.find!(html, test_role: "logout-link") |> HtmlQuery.attr("href")
  "/logout"
  ```
  """
  @spec attr(html(), attr()) :: binary()
  def attr(nil, _attr), do: nil

  def attr(html, attr) do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.attr(&1, #{inspect(attr)}))")
    |> Floki.attribute(attr |> to_string() |> Moar.String.dasherize())
    |> List.first()
  end

  @doc """
  Returns the text value of `html`.

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.find!(html, "select option[selected]") |> HtmlQuery.text()
  "apples"
  ```
  """
  @spec text(html()) :: binary()
  def text(html) do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.text/1)")
    |> Floki.text(sep: " ")
    |> String.trim()
  end

  # # #

  @doc """
  Returns a map containing the form fields of form `selector` in `html`.

  ```elixir
  iex> html = ~s|<form> <input type="text" name="color" value="green"> <textarea name="desc">A tree</textarea> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{color: "green", desc: "A tree"}
  ```

  If form field names are in `foo[bar]` format, then `foo` becomes a key to a nested map containing `bar`:

  ```elixir
  iex> html = ~s|<form> <input type="text" name="profile[name]" value="fido"> <input type="text" name="profile[age]" value="10"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{profile: %{name: "fido", age: "10"}}
  ```
  """
  @spec form_fields(html()) :: %{atom() => binary() | map()}
  def form_fields(html) do
    %{}
    |> form_field_values(html, "input[value]", &attr(&1, "value"))
    |> form_field_values(html, :textarea, &text/1)
    |> Moar.Map.atomize_keys()
  end

  @doc """
  Prints prettified `html` with a label, and then returns the original html.
  """
  @spec inspect_html(html(), binary()) :: html()
  def inspect_html(html, label \\ "INSPECTED HTML") do
    """
    === #{label}:

    #{pretty(html)}
    """
    |> IO.puts()

    html
  end

  @doc """
  Extracts all the meta tags from `html`, returning a list of maps.

  ```elixir
  iex> html = ~s|<head> <meta charset="utf-8"/> <meta http-equiv="X-UA-Compatible" content="IE=edge"/> </head>|
  iex> HtmlQuery.meta_tags(html)
  [%{"charset" => "utf-8"}, %{"content" => "IE=edge", "http-equiv" => "X-UA-Compatible"}]
  ```
  """
  @spec meta_tags(html()) :: [%{binary() => binary()}]
  def meta_tags(html), do: html |> parse() |> extract_meta_tags()

  @doc """
  Parses and then re-stringifies `html`, increasing the liklihood that two equivalent HTML strings can
  be considered equal.

  ```elixir
  iex> a = ~s|<p id="color">green</p>|
  iex> b = ~s|<p  id = "color" >green</p>|
  iex> a == b
  false
  iex> HtmlQuery.normalize(a) == HtmlQuery.normalize(b)
  true
  ```
  """
  @spec normalize(html()) :: binary()
  def normalize(html), do: html |> parse() |> Floki.raw_html()

  @doc """
  Parses an HTML fragment using `Floki.parse_fragment!/1`, returning a Floki HTML tree.
  """
  @spec parse(html()) :: Floki.html_tree()
  def parse(html) when is_binary(html), do: html |> Floki.parse_fragment!()
  def parse(html) when is_list(html), do: html
  def parse({element, attrs, contents}), do: [{element, attrs, contents}]
  def parse(%_{} = html), do: html |> Moar.Protocol.implements!(String.Chars) |> to_string() |> parse()

  @doc """
  Parses an HTML document using `Floki.parse_document!/1`, returning a Floki HTML tree.
  """
  @spec parse_doc(html()) :: Floki.html_tree()
  def parse_doc(html) when is_binary(html), do: html |> Floki.parse_document!()
  def parse_doc(html) when is_list(html), do: html
  def parse_doc(%_{} = html), do: html |> Moar.Protocol.implements!(String.Chars) |> to_string() |> parse_doc()

  @doc """
  Returns `html` as a prettified string, using `Floki.raw_html/2` and its `pretty: true` option.
  """
  @spec pretty(html()) :: binary()
  def pretty(html), do: html |> parse() |> Floki.raw_html(encode: false, pretty: true)

  # # #

  @spec extract_meta_tags(html()) :: [map()]
  defp extract_meta_tags(html),
    do: all(html, "meta") |> Enum.map(fn {"meta", attrs, _} -> Map.new(attrs) end)

  @spec first!(html(), binary() | nil) :: html()
  defp first!(html, hint \\ nil)

  defp first!([], _hint), do: raise("Expected a single HTML node but found none")

  defp first!([node], _hint), do: node

  defp first!(html, hint) do
    raise """
    Expected a single HTML node but got:

    #{pretty(html)}
    #{hint}
    """
  end

  @spec form_field_values(map(), html(), HtmlQuery.Css.selector(), (html() -> binary())) :: map()
  defp form_field_values(acc, html, selector, value_fn) do
    html
    |> all(selector)
    |> Enum.reduce(acc, &form_field_value(&2, &1, value_fn))
    |> Moar.Map.deep_atomize_keys()
  end

  @spec form_field_value(map(), html(), (html() -> binary())) :: map()
  defp form_field_value(acc, input, value_fn) do
    value = value_fn.(input)

    map =
      case input |> attr("name") |> unwrap_input_name() do
        {key1, key2} -> %{key1 => %{key2 => value}} |> Moar.Map.deep_atomize_keys()
        key -> %{key => value} |> Moar.Map.atomize_keys()
      end

    Moar.Map.deep_merge(acc, map)
  end

  @spec unwrap_input_name(binary()) :: binary() | {binary(), binary()}
  defp unwrap_input_name(input_name) do
    case Regex.run(~r|(.*)\[(.*)\]|, input_name) do
      [_, parent, child] -> {parent, child}
      _ -> input_name
    end
  end
end

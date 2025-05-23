defmodule HtmlQuery do
  # @related [test](/test/html_query_test.exs)

  @moduledoc """
  A concise HTML query API. HTML parsing is handled by [Floki](https://hex.pm/packages/floki).

  We created a related library called [XmlQuery](https://hexdocs.pm/xml_query/readme.html) which has the same API but
  is used for querying XML. You can read more about them in
  [Querying HTML and XML in Elixir with HtmlQuery and XmlQuery](https://eahanson.com/articles/html-query-xml-query).

  ## Data types

  All functions can accept HTML in the form of a string, a Floki HTML tree, a Floki HTML node, or anything that
  implements the `String.Chars` protocol. See `t:HtmlQuery.html/0`.

  Some functions take a CSS selector, which can be a string, a keyword list, or a list.
  See `t:HtmlQuery.Css.selector/0`.

  ## Query functions

  | `all/2`   | return all elements matching the selector                   |
  | `find/2`  | return the first element that matches the selector          |
  | `find!/2` | return the only element that matches the selector, or raise |

  ## Extraction functions

  | `attr/2`        | returns the attribute value as a string                 |
  | `form_fields/1` | returns the names and values of form fields as a map    |
  | `meta_tags/1`   | returns the names and values of metadata fields         |
  | `table/2`       | returns the cells of a table as a list of lists or maps |
  | `text/2`        | returns the text contents as a single string            |

  ## Parsing functions

  | `parse/1`     | parses an HTML fragment into a [Floki HTML tree] |
  | `parse_doc/1` | parses an HTML doc into a [Floki HTML tree]      |

  ## Utility functions

  | `inspect_html/2` | prints prettified HTML with a label   |
  | `normalize/1`    | parses and re-stringifies HTML        |
  | `pretty/1`       | prettifies HTML                       |
  | `reject/2`       | removes nodes that match the selector |


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

  Use a keyword list as the selector (see `HtmlQuery.Css` for details on selectors):

  ```elixir
  iex> html = ~s|<div> <a href="/logout" test-role="logout-link">logout</a> </div>|
  iex> HtmlQuery.find!(html, test_role: "logout-link") |> HtmlQuery.attr("href")
  "/logout"
  ```
  """

  alias HtmlQuery.QueryError

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

  # # # Main Query Functions

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
  def all(nil, selector) do
    raise(QueryError, """
    HtmlQuery.all expected to have been given HTML

    HTML: nil

    Selector: #{HtmlQuery.Css.selector(selector)}
    """)
  end

  def all(html, selector),
    do: html |> parse() |> Floki.find(HtmlQuery.Css.selector(selector))

  @doc """
  Finds the first element in `html` that matches `selector`, returning a Floki HTML node.

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.find(html, "select option[selected]")
  {"option", [{"value", "a"}, {"selected", "selected"}], ["apples"]}
  ```
  """
  @spec find(html(), HtmlQuery.Css.selector()) :: Floki.html_node() | nil
  def find(nil, selector) do
    raise(QueryError, """
    HtmlQuery.find expected to have been given HTML

    HTML: nil

    Selector: #{HtmlQuery.Css.selector(selector)}
    """)
  end

  def find(html, selector),
    do: all(html, selector) |> List.first()

  @doc """
  Like `find/2` but raises unless exactly one element is found.
  """
  @spec find!(html(), HtmlQuery.Css.selector()) :: Floki.html_node()
  def find!(html, selector),
    do: all(html, selector) |> first!("Selector: #{HtmlQuery.Css.selector(selector)}")

  # # # Extraction Functions

  @doc """
  Returns the value of `attr` from the outermost element of `html`.
  If `attr` is an atom, any underscores are converted to dashes.

  ```elixir
  iex> html = ~s|<div> <a href="/logout" test-role="logout-link">logout</a> </div>|
  iex> HtmlQuery.find!(html, test_role: "logout-link") |> HtmlQuery.attr("href")
  "/logout"
  ```
  """
  @spec attr(html(), attr()) :: binary() | nil
  def attr(nil, _attr),
    do: nil

  def attr(html, attr) do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.attr(&1, #{inspect(attr)}))")
    |> Floki.attribute(attr |> to_string() |> Moar.String.dasherize())
    |> List.first()
  end

  @doc """
  The beginnings of an experimental replacement for `HtmlQuery.form_fields/1`.

  Returns all the fields of the supplied form, in order, without trying to emulate what a web framework might
  convert the values to.

  The `:as` option can be `:lists` or `:map`. When `:lists` (the default), each input's attributes are returned as
  a list in the order found in the HTML, and therefore the function returns a list of lists. Because HTML allows
  multiple inputs with the same name, no de-duplication is performed. When `:map`, the fields are returned as a
  map, where the keys are the "name" attribute (converted into snake-cased atoms) and the values are a list of
  lists of attributes (to handle the case when there are multiple inputs with the same name).
  """
  @spec form(html(), Keyword.t()) :: [Keyword.t()]
  def form(html, opts \\ []) do
    as = Keyword.get(opts, :as, :lists)

    html
    |> all("input, select, textarea")
    |> Enum.map(&form_input/1)
    |> form_results(as)
  end

  @doc """
  Returns a map containing the form fields of form `selector` in `html`. Because it returns a map, any information
  about the order of form fields is lost.

  ```elixir
  iex> html = ~s|<form> <input type="text" name="color" value="green"> <textarea name="desc">A tree</textarea> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{color: "green", desc: "A tree"}
  ```

  Field names are converted to snake case atoms:

  ```elixir
  iex> html = ~s|<form> <input type="text" name="favorite-color" value="green"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{favorite_color: "green"}
  ```

  If form field names are in `foo[bar]` format, then `foo` becomes a key to a nested map containing `bar`:

  ```elixir
  iex> html = ~s|<form> <input type="text" name="profile[name]" value="fido"> <input type="text" name="profile[age]" value="10"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{profile: %{name: "fido", age: "10"}}
  ```

  If a text field has no value attribute, it will not be returned at all:

  ```elixir
  iex> html = ~s|<form> <input type="text" name="no-value"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{}

  iex> html = ~s|<form> <input type="text" name="empty-value" value=""> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{empty_value: ""}

  iex> html = ~s|<form> <input type="text" name="non-empty-value" value="something"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{non_empty_value: "something"}
  ```

  The checked value of a radio button set is returned, or `nil` is returned if no value is checked:

  ```elixir
  iex> html = ~s|<form> <input type="radio" name="x" value="1"> <input type="radio" name="x" value="2" checked> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{x: "2"}

  iex> html = ~s|<form> <input type="radio" name="x" value="1"> <input type="radio" name="x" value="2"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{x: nil}
  ```

  When evaluating checkboxes, the `name` attribute of the input defines whether or not a term or a
  list will be returned. A name that ends in `[]` allows a browser to send multiple values, in which case
  our form fields will return an array of values. A name that does not end in `[]` will evaluate to a
  single value, the last checked value in a list:

  ```elixir
  iex> html = ~s|<form> <input type="checkbox" name="x" value="1" checked> <input type="checkbox" name="x" value="2" checked> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{x: "2"}

  iex> html = ~s|<form> <input type="checkbox" name="x" value="1"> <input type="checkbox" name="x" value="2"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{x: nil}

  iex> html = ~s|<form>
  ...>   <input type="hidden" name="x" value="false">
  ...>   <input type="checkbox" name="x" value="true">
  ...>   <input type="hidden" name="y" value="false">
  ...>   <input type="checkbox" name="y" checked value="true">
  ...> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{x: false, y: true}

  iex> html = ~s|<form> <input type="checkbox" name="x[]" value="1" checked> <input type="checkbox" name="x[]" value="2" checked> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{x: ["1", "2"]}

  iex> html = ~s|<form> <input type="checkbox" name="x[]" value="1"> <input type="checkbox" name="x[]" value="2"> </form>|
  iex> html |> HtmlQuery.find("form") |> HtmlQuery.form_fields()
  %{x: []}
  ```
  """
  @spec form_fields(html()) :: %{atom() => binary() | map()}
  def form_fields(html),
    do: HtmlQuery.Form.fields(html)

  @doc """
  Extracts all the meta tags from `html`, returning a list of maps.

  ```elixir
  iex> html = ~s|<head> <meta charset="utf-8"/> <meta http-equiv="X-UA-Compatible" content="IE=edge"/> </head>|
  iex> HtmlQuery.meta_tags(html)
  [%{"charset" => "utf-8"}, %{"content" => "IE=edge", "http-equiv" => "X-UA-Compatible"}]
  ```
  """
  @spec meta_tags(html()) :: [%{binary() => binary()}]
  def meta_tags(html),
    do: html |> parse() |> extract_meta_tags()

  @doc """
  Returns the contents of the table as a list of lists, or as a single list if only one column is selected via
  the `:only` or `:except` options. Headers are returned by default (see the `:headers` option).

  Options:
  * `:as`
      - if `:lists` (the default), returns the table as a list of lists; or
      - if `:maps`, returns the table as a list of maps.
  * `:only`
      - a list of the indices of the columns to return; or
      - a single index of the column, which will return a single list, rather than a list of lists; or
      - a list of column header names to return, assuming that the first row of the table is the column names; or
      - a single column header name, which will return a single list, rather than a list of lists; or
      - `:all` to return all columns (which is the same as not specifying this option at all)
  * `:except`
      - returns all the columns except the ones whose indices or names are given. `only` and `except` can be
        combined to further reduce the set of columns
  * `:headers`
      - if `true` (the default), returns the list of headers along with the rows. Ignored if `as` option is `:maps`
  * `:update`
      - accepts a function that will be used to transform each header and body cell

  Deprecated options:
  * `:columns` - use `only` instead.

  ```elixir
  iex> html = "<table> <tr><th>A</th><th>B</th><th>C</th></tr> <tr><td>1</td><td>2</td><td>3</td></tr> </table>"
  iex> HtmlQuery.table(html)
  [
    ["A", "B", "C"],
    ["1", "2", "3"]
  ]
  iex> HtmlQuery.table(html, as: :maps)
  [
    %{"A" => "1", "B" => "2", "C" => "3"}
  ]
  iex> HtmlQuery.table(html, only: [0, 2])
  [
    ["A", "C"],
    ["1", "3"]
  ]
  iex> HtmlQuery.table(html, only: [2, 0])
  [
    ["C", "A"],
    ["3", "1"]
  ]
  iex> HtmlQuery.table(html, only: 2)
  ["C", "3"]
  iex> HtmlQuery.table(html, only: ["C", "A"])
  [
    ["C", "A"],
    ["3", "1"]
  ]
  iex> HtmlQuery.table(html, only: "C")
  ["C", "3"]
  iex> HtmlQuery.table(html, only: "C", headers: false)
  ["3"]
  iex> HtmlQuery.table(html, except: ["C", "A"])
  [
    ["B"],
    ["2"]
  ]
  iex> HtmlQuery.table(html, only: ["C", "A"], headers: false)
  [
    ["3", "1"]
  ]
  iex> HtmlQuery.table(html, update: &String.downcase/1)
  [
    ["a", "b", "c"],
    ["1", "2", "3"]
  ]
  ```
  """
  @spec table(html(), keyword()) :: [[]] | [map()]
  def table(html, opts \\ []) do
    rows = [header_row | non_header_rows] = html |> parse() |> all("tr")
    header_row_values = header_row |> all("th,td") |> Enum.map(&text/1)
    update_fn = Keyword.get(opts, :update, &Function.identity/1)

    only =
      case Keyword.get(opts, :only) || Keyword.get(opts, :columns, :all) do
        :all -> Range.to_list(0..(length(header_row_values) - 1))
        [first | _] = names when is_binary(first) -> Moar.Enum.find_indices!(header_row_values, names)
        first = name when is_binary(first) -> Moar.Enum.find_indices!(header_row_values, [name]) |> List.first()
        [first | _] = indices when is_integer(first) -> indices
        first = index when is_integer(first) -> index
      end

    except =
      case Keyword.get(opts, :except) do
        nil -> []
        [first | _] = names when is_binary(first) -> Moar.Enum.find_indices!(header_row_values, names)
        first = name when is_binary(first) -> Moar.Enum.find_indices!(header_row_values, [name]) |> List.first()
        [first | _] = indices when is_integer(first) -> indices
        first = index when is_integer(first) -> index
      end

    columns = List.wrap(only) -- List.wrap(except)
    single? = length(columns) == 1 && !is_list(only) && (except == [] || !is_list(except))

    case Keyword.get(opts, :as, :lists) do
      :lists ->
        rows =
          case Keyword.get(opts, :headers, true) do
            false -> non_header_rows
            true -> rows
            other -> raise "Expected `:headers` option to be `true` or `false`, got: #{other}"
          end

        rows
        |> Enum.map(&table_row_values(&1, columns, update_fn))
        |> then(fn rows -> if single?, do: List.flatten(rows), else: rows end)

      :maps ->
        rows
        |> Enum.map(&table_row_values(&1, columns, update_fn))
        |> Moar.Enum.lists_to_maps(:first_list)
        |> then(fn rows -> if single?, do: List.flatten(rows), else: rows end)

      other ->
        raise "Expected `:as` option to be `:lists` or `:maps`, got: #{other}"
    end
  end

  @doc """
  Returns the text value of `html`, separating substrings with a space by default. (Floki will split text into
  substrings.) You can pass a separator as the second argument; sometimes it's useful to pass an empty string.

  ```elixir
  iex> html = ~s|<select> <option value="a" selected>apples</option> <option value="b">bananas</option> </select>|
  iex> HtmlQuery.find!(html, "select option[selected]") |> HtmlQuery.text()
  "apples"
  ```
  """
  @spec text(html(), String.t()) :: binary()
  def text(html, separator \\ " ") do
    html
    |> parse()
    |> first!("Consider using Enum.map(html, &#{@module_name}.text/1)")
    |> Floki.text(sep: separator)
    |> String.trim()
  end

  # # # Parsing Functions

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

  # # # Utility Functions

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
  def normalize(html),
    do: html |> parse() |> Floki.raw_html()

  @doc """
  Returns `html` as a prettified string (delgates to `Floki.raw_html/2` with the `pretty: true` option).
  """
  @spec pretty(html()) :: binary()
  def pretty(html),
    do: html |> parse() |> Floki.raw_html(encode: false, pretty: true)

  @doc """
  Returns `html` after removing all nodes that don't match `selector` (delegates to `Floki.filter_out/2`).

  ```elixir
  iex> html = ~s|<div> <span id="name">Alice</span> <span id="password">topaz</span> </div>|
  iex> HtmlQuery.reject(html, id: "password") |> HtmlQuery.normalize()
  ~s|<div><span id="name">Alice</span></div>|
  ```
  """
  @spec reject(html(), HtmlQuery.Css.selector()) :: html()
  def reject(html, selector),
    do: html |> parse() |> Floki.filter_out(HtmlQuery.Css.selector(selector))

  # # # Private Functions

  defp empty_elements(0), do: []
  defp empty_elements(count), do: for(_ <- 1..count, do: nil)

  @spec extract_meta_tags(html()) :: [map()]
  defp extract_meta_tags(html),
    do: all(html, "meta") |> Enum.map(fn {"meta", attrs, _} -> Map.new(attrs) end)

  @spec first!(html(), binary()) :: html()
  defp first!([], hint) do
    raise(QueryError, """
    Expected a single HTML node but found none

    #{hint}
    """)
  end

  defp first!([node], _hint), do: node

  defp first!(html, hint) do
    raise QueryError, """
    Expected a single HTML node but got:

    #{pretty(html)}
    #{hint}
    """
  end

  # # #

  defp form_input({type, attrs, children}) do
    attrs
    |> Keyword.new(fn {k, v} -> {String.to_atom(k), v} end)
    |> put_form_input_type(type)
    |> add_form_input_attrs(type, children)
    |> Enum.sort_by(fn {k, _v} -> k end)
  end

  defp put_form_input_type(attrs, type) do
    type =
      if type == "input",
        do: Keyword.get(attrs, :type, "unknown"),
        else: type

    attrs |> Keyword.delete(:type) |> Keyword.put(:type, type)
  end

  defp add_form_input_attrs(attrs, "select", children) do
    options =
      all(children, "option")
      |> List.foldr([], fn {_, option_attrs, text}, acc ->
        option =
          Keyword.new(option_attrs, fn {k, v} -> {String.to_atom(k), v} end)
          |> Keyword.put(:text, Enum.join(text))
          |> Enum.sort_by(fn {k, _v} -> k end)

        [option | acc]
      end)

    Keyword.put(attrs, :options, options)
  end

  defp add_form_input_attrs(attrs, "textarea", children),
    do: Keyword.put(attrs, :text, Enum.join(children))

  defp add_form_input_attrs(attrs, _, _),
    do: attrs

  defp form_results(results, :lists), do: results

  defp form_results(results, :map) do
    Enum.reduce(results, %{}, fn result, acc ->
      {key, attrs} = Keyword.pop(result, :name)
      key = key |> Moar.String.to_case(:snake_case) |> Moar.Atom.atomize()

      {_, acc} =
        Map.get_and_update(acc, key, fn
          nil -> {nil, [attrs]}
          value -> {value, List.insert_at(value, -1, attrs)}
        end)

      acc
    end)
  end

  # # #

  @spec table_row_values(html(), :all | [integer()], fun()) :: [binary()]
  defp table_row_values(row, columns, update_fn) do
    row
    |> all("td,th")
    |> Enum.reduce([], fn el, elements ->
      colspan = attr(el, "colspan") |> Moar.Term.when_present(&String.to_integer/1, 1)
      elements ++ [el | empty_elements(colspan - 1)]
    end)
    |> Moar.Enum.take_at(columns)
    |> Enum.map(&table_cell_value(&1, update_fn))
  end

  defp table_cell_value(nil, _), do: nil

  defp table_cell_value(cell, update_fn) do
    case text(cell) do
      "" -> form_fields(cell) |> to_table_cell()
      text -> text
    end
    |> update_fn.()
  end

  defp to_table_cell(map) when map_size(map) == 1,
    do: Map.values(map) |> List.first() |> to_string()

  defp to_table_cell(_map), do: ""
end

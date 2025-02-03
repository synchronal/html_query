# HtmlQuery

A concise API, honed over multiple years, for querying HTML. There are just 5 main functions:
`all/2`, `find/2` and `find!/2` for finding things, plus `attr/2` and `text/1` for extracting
information. There are also a handful of other useful functions, referenced below and described in detail in
the [module docs](https://hexdocs.pm/html_query/HtmlQuery.html). HTML parsing is handled by
[Floki](https://hexdocs.pm/floki/readme.html).

The input can be:

* A string of HTML.
* An [IO Data](https://hexdocs.pm/elixir/IO.html#module-io-data) of HTML.
* A [Floki](https://hexdocs.pm/floki/readme.html) [html_node](https://hexdocs.pm/floki/Floki.html#t:html_node/0)
  or [html_tree](https://hexdocs.pm/floki/Floki.html#t:html_tree/0) data structure. HtmlQuery uses Floki internally
  and can accept its data structure as input, and some HtmlQuery functions return its data structure as output.
* Anything that implements the `String.Chars` protocol. See [Implementing String.Chars](#implementing-string-chars)
  below.

We created a related library called [XmlQuery](https://hexdocs.pm/xml_query/readme.html) which has the same API but
is used for querying XML. You can read more about them in
[Querying HTML and XML in Elixir with HtmlQuery and XmlQuery](https://eahanson.com/articles/html-query-xml-query).

This library is MIT licensed and is part of a growing number of Elixir open source libraries published at
[github.com/synchronal](https://github.com/synchronal#elixir).

This library is tested against the most recent 3 versions of Elixir and Erlang.

## Installation

```elixir
def deps do
  [
    {:html_query, "~> 4.1"}
  ]
end
```

## Usage

Detailed docs are in the [HtmlQuery module docs](https://hexdocs.pm/html_query/HtmlQuery.html); a quick usage
overview follows.

We typically alias `HtmlQuery` to `Hq`:

```elixir
alias HtmlQuery, as: Hq
```

The rest of these examples use the following HTML:

```elixir
html = """
  <h1>Please update your profile</h1>
  <form id="profile" test-role="profile">
    <label>Name <input name="name" type="text" value="Fido"> </label>
    <label>Age <input name="age" type="text" value="10"> </label>
    <label>Bio <textarea name="bio">Fido likes long walks and playing fetch.</textarea> </label>
  </form>
</form>
"""
```

### Querying

Query functions use CSS selector strings for finding nodes. The
[MDN CSS Selectors guide](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_selectors/Selectors_and_combinators)
is a helpful CSS reference.

```elixir
Hq.find(html, "form#profile label textarea")
```

We’ve found that reserving CSS classes and IDs for styling instead of using them for testing reduces the chance of
styling changes breaking tests, and so we often add attributes that start with `test-` into our HTML; a query for
`test-role` would look like:

```elixir
Hq.find(html, "form[test-role=profile]")
```

For simple queries, [HtmlQuery.Css](https://hexdocs.pm/html_query/HtmlQuery.Css.html#selector/1) provides a shorthand
using keyword lists. For complicated queries, it’s usually clearer to use a CSS string.

```elixir
Hq.find(html, test_role: "profile")
```

### Finding

`all/2` finds all elements matching the query, `find/2` returns the first element that matches the selector or `nil` if
none was found, and `find!/2` is like `find/2` but raises unless exactly one element is found.

```elixir
Hq.all(html, "input") # returns a list of all the <input> elements
Hq.find(html, "input[name=age]") # returns the <input> with `name=age`
Hq.find!(html, "input[name=foo]") # raises because no such element exists
```

See the [module docs](https://hexdocs.pm/html_query/HtmlQuery.html) for more details.

### Extracting

`text/1` is the simplest extraction function:

```elixir
html |> Hq.find(:h1) |> Hq.text() # returns "Please update your profile"
```

`attr/2` returns the value of an attribute:

```elixir
html |> Hq.find("input[name=age]") |> Hq.attr(:value) # returns "10"
```

To extract data from multiple HTML nodes, we found that it is clearer to compose multiple functions rather than to
have a more complicated API:

```elixir
html |> Hq.all(:input) |> Enum.map(&Hq.text/1) # returns ["Name", "Age"]
html |> Hq.all("input[type=text]") |> Enum.map(&Hq.attr(&1, "value")) # returns ["Fido", "10"]
```

There are also functions for extracting form fields as a map, meta tags as a list, and table contents as a list of
lists or a list of maps. See the [module docs](https://hexdocs.pm/html_query/HtmlQuery.html) for more details.

### Parsing

`parse/1` and `parse_doc/1` delegate to Floki’s `parse_fragment/1` and `parse_document!/1` functions. These functions
are rarely needed since all the HtmlQuery functions will parse HTML if needed. See the
[module docs](https://hexdocs.pm/html_query/HtmlQuery.html) for more details.

### Utilities

`inspect_html/2` prints prettified HTML with a label, `normalize/1` parses and re-stringifies HTML which can be handy
when trying to compare two strings of HTML, `pretty/1` formats HTML in a human-friendly format, and `reject/2` removes
nodes that match the given selector. See the [module docs](https://hexdocs.pm/html_query/HtmlQuery.html) for more
details.

## Implementing String.Chars

HtmlQuery functions that accept HTML will convert any module that implements `String.Chars`. For example, our
[Pages](https://hexdocs.pm/pages/readme.html) testing library implements `String.Chars` for controller output like
this:

```elixir
defimpl String.Chars do
  def to_string(%Pages.Driver.Conn{conn: %Plug.Conn{status: 200} = conn}),
    do: Phoenix.ConnTest.html_response(conn, 200)
end
```

and implements `String.Chars` for LiveView output like this:

```elixir
defimpl String.Chars, for: Pages.Driver.LiveView do
  def to_string(%Pages.Driver.LiveView{rendered: rendered}) when not is_nil(rendered),
    do: rendered

  def to_string(%Pages.Driver.LiveView{live: live}) when not is_nil(live),
    do: live |> Phoenix.LiveViewTest.render()
end
```

## Development

```shell
brew bundle

bin/dev/doctor
bin/dev/update
bin/dev/audit
bin/dev/shipit
```

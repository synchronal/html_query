# Changelog

## Unreleased changes

## 2.0.0

- `HtmlQuery.form_fields/1` returns singular value for checkboxes where name does not end in `[]`.

## 1.4.1

- `HtmlQuery.form_fields/1` uses the value of selected options when different from the inner text.

## 1.4.0

- deprecate `HtmlQuery.table`'s `columns` option in favor of `only`
- add `except` option to `HtmlQuery.table`

## 1.3.0

- require Elixir 1.15 or later
- test against the latest Elixir and Erlang

## 1.2.3

- Documentation updates

## 1.2.2

- Update deps.

## 1.2.1

- Fix compiler warnings on `HtmlQuery.reject/2`.

## 1.2.0

- `HtmlQuery.reject/2` removes nodes that match the given selector.

## 1.1.1

- Fix text of error message produced by `HtmlQuery.table`

## 1.1.0

- `HtmlQuery.table` can now optionally return the table as a list of maps.

## 1.0.0

- No changes from 0.8.0.

## 0.8.0

- `HtmlQuery.table` does not return the header row if `headers: false` is set.

## 0.7.2

- `HtmlQuery.table/2` raises if a given column name does not exist in the table.

## 0.7.1

- Update `Moar` to fix bug where `HtmlQuery.form_fields/1` would return `%{}` instead of `[]` when no checkboxes
  were checked.

## 0.7.0

- `HtmlQuery.table/2` can accept a list of column names to filter by.

## 0.6.2

- `HtmlQuery.form_fields/1` handles arrays of checkboxes.

## 0.6.1

- Fix typespec on `HtmlQuery.table/2`

## 0.6.0

- Add `columns` option to `HtmlQuery.table`, which returns only the given columns.

## 0.5.2

- Dependency on `Moar` allows for any version greater than or equal to 1.24.1.

## 0.5.1

- `HtmlQuery.form_fields/1` only returns inputs that have a `name` attribute.

## 0.5.0

- `HtmlQuery.form_fields/1` now handles checkboxes and radio buttons.

## 0.4.0

- `HtmlQuery.form_fields/1` response includes `select` fields.

## 0.3.0

- Add `HtmlQuery.table/1` which returns the contents of a table's cells as a list of lists.

## 0.2.4

- Fix typespec

## 0.2.3

- Raise `HtmlQuery.QueryError` instead of `RuntimeError`.
  - includes selector.

## 0.2.2

- Relax Floki version restriction.

## 0.2.1

- Fix typespec for `HtmlQuery.find/2`

## 0.2.0

- `HtmlQuery.form_fields/1` converts dashes in field names to underscores.

## 0.1.1

- Documentation and typespec updates

## 0.1.0

- Initial release

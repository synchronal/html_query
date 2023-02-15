# Changelog

## Unreleased changes

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

# Subject title uniqueness

FromThePage treats an article's title as the canonical subject name. New and
edited articles are validated so that two articles in the same collection
cannot normally use the same title. The comparison is case-insensitive, while
the same title may be used in different collections.

This rule is **not enforced by a unique database index**. Historical data can
contain duplicate subject titles, and retaining those rows allows operators and
collection owners to inspect and remediate them. It also means the application
validation is not a concurrency guarantee: simultaneous writes can pass the
validation before either transaction commits.

Code that creates or renames subjects should use the normal validated
Active Record APIs and handle validation failures. Do not assume that a query
by collection and title can return only one row. Existing duplicates should be
resolved through the subject-combination workflow rather than deleted directly,
so that references and article text are preserved.

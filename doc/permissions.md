# Explicit permission checks (`require_permission`)

Controllers that opt in with `enforce_permission_checks` must begin each action with a
`require_permission` call:

```ruby
def enable_ruler
  require_permission(:collection_owner, @collection)

  transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
  transcription_field.update(row_highlight: true)
  ...
end
```

This page explains why the check is written this way, and why it lives in each action
rather than in a shared filter or helper.

## The goal: every endpoint's access is a deliberate decision

When someone reads an action, they should be able to see who may call it without looking
anywhere else. When someone writes a new action, they should have to decide who may call
it. Leaving that decision out by accident should not be possible.

The `before_action :authorized?` pattern does neither of these reliably.

## What goes wrong with filter-based checks

`TranscriptionFieldController` (SEC-02) showed how this pattern fails. On `development` it
had:

```ruby
before_action :authorized?, only: [:new, :edit_fields, :add_field]

def authorized?
  ...
  if @collection && !current_user.like_owner?(@collection)
    ajax_redirect_to dashboard_path
  end
end
```

That one line had three separate problems, and none of them was visible from the actions
it was supposed to protect:

1. **The `only:` list was stale.** `:new` and `:add_field` were not actions in this
   controller (the real one is `add_fields`). The check guarded `edit_fields` and nothing
   else, so new actions added later were never covered.
2. **A missing record turned off the check.** `if @collection && ...` skips the check
   when `@collection` is nil. Most field routes carried only `transcription_field_id`, so
   nothing loaded `@collection` before the filter ran. The global `authorize_collection`
   also begins with `return unless @collection`, so the same thing happened there.
3. **Records were loaded after authorization.** Several actions set `@collection` from the
   field inside the action body, which runs after every filter. Whatever check was meant to
   happen had already been skipped by then.

The result: any user, often without signing in, could change or delete another
collection's transcription fields and spreadsheet columns by ID.

None of these is unusual. `only:`/`except:` lists drift whenever someone adds an action,
guards like `if @record` fail open, and filter order is invisible from the action body.
Code review doesn't catch any of these well, because the diff for a new action shows no
authorization code that could be wrong.

## How `require_permission` addresses each failure

| Failure | What `require_permission` does instead |
|---|---|
| Check lives far from the action | The first line of the action says who may call it. |
| `only:` list drifts | There is no list. Each action makes its own call. `enforce_permission_checks` logs any action that finishes without making one. |
| Missing record fails open | Permissions that need a record (`RECORD_REQUIRED`) **deny** when the record is nil, admins included, and log an error, since a nil record is a loading bug. |
| Vague, duplicated predicates | Permissions come from a fixed vocabulary (`Permissions::PERMISSIONS`: `:collection_owner`, `:collection_viewer`, `:signed_in`, ...). An unknown name raises an `ArgumentError`. |
| "Public by accident" looks the same as "public on purpose" | Public endpoints must say so with `:allow`. Undecided ones use `:pending`, which passes but logs a warning so it can be found and fixed later. |

Even `:allow` has to be written out. An action that really is public still makes a call,
because writing it records that someone decided the action should be public.

## Why each action writes its own lookups

Shared filters and helpers (`before_action :load_x`, `def find_x`) would remove some
repetition. We still write each action's record loading out in full:

```ruby
def save_multiselect
  require_permission(:collection_owner, @collection)

  transcription_field = @collection.metadata_fields.find(params[:transcription_field_id])
  ...
end
```

- **The whole security story is in one place.** Which collection is checked, which
  permission is required, and how the record is scoped to that collection can all be read
  in the first few lines. A shared loader hides the scoping, and the scoping is where
  insecure direct object reference (IDOR) bugs live.
- **It matches the existing convention.** `ApplicationController#load_objects_from_params`
  already loads `@collection` explicitly from `params[:collection_id]`. Field-level
  actions build on that: every request sends `collection_id`, and the action then looks up
  the child record **through** `@collection`, so an ID from another collection is a 404.
  We never trust a child record to tell us its parent.
- **Each action picks the scope it needs.** Spreadsheet actions use
  `@collection.transcription_fields`, multiselect uses `@collection.metadata_fields`, and
  actions that serve both editors use `TranscriptionField.where(collection_id: @collection.id)`.
  A shared helper tends to pick the broadest scope for everyone.
- **Changing one action can't weaken another.** Editing a shared loader changes every
  action that uses it. With inline lookups, a change only affects the action it was made
  in.

The repetition is intentional. Don't factor it back out.

## Rules of thumb

1. Load records **only** through their authorized parent (`@collection.<association>.find`).
   Never use a bare `Model.find(params[:id])` for something that belongs to a collection.
2. Call `require_permission` before reading or changing anything sensitive. Loading the
   parent (done by `ApplicationController`) is the only thing that may happen before it.
3. Pick the narrowest permission that fits. Admins pass every permission except
   `:disallow`, so you don't need a separate admin branch.
4. If a route doesn't carry the parent's ID, add the ID to the URL rather than deriving
   the parent from the child.
5. Cover each action with request specs for: signed out, signed-in non-owner, the owner,
   and a cross-collection ID (the IDOR case).

## Where things live

- `app/controllers/concerns/permissions.rb`: `require_permission`,
  `enforce_permission_checks`, the permission vocabulary, and how denied requests are
  redirected.
- `app/lib/permissions/*_rules.rb`: the logic behind each permission, copied from the model
  predicates it replaces. `spec/lib/permissions/rules_parity_spec.rb` keeps the two in sync.
- `spec/requests/transcription_field_controller_spec.rb`: the reference example for testing
  a migrated controller.

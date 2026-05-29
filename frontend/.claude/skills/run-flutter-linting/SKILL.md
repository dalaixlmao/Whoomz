---
name: run-flutter-linting
description: Run and configure Flutter linting & style — flutter analyze, dart format, flutter_lints baseline rules, very_good_analysis for stricter enforcement, and fixing common lint warnings. Use when asked to lint the codebase, format code, configure analysis_options.yaml, or enforce stricter lint rules.
---

`flutter_lints ^6.0.0` is already in this project's dev dependencies. Linting runs without any extra setup.

## Run lint analysis

```bash
~/flutter/bin/flutter analyze
```

A clean project prints:

```
Analyzing whoomz...
No issues found!
```

## Format code

```bash
# Dry run — show what would change
~/flutter/bin/dart format lib/ test/ --set-exit-if-changed

# Apply formatting
~/flutter/bin/dart format lib/ test/
```

## Current analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Add per-rule overrides here
```

## Add stricter rules (very_good_analysis)

`very_good_analysis` enforces a stricter superset of `flutter_lints`:

```bash
~/flutter/bin/flutter pub add --dev very_good_analysis
```

```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    # Disable specific noisy rules if needed:
    public_member_api_docs: false  # disable doc requirement for private apps
```

## Useful individual lint rules

```yaml
linter:
  rules:
    # Safety
    avoid_dynamic_calls: true          # no foo.bar when foo is dynamic
    avoid_print: true                  # use proper logging
    cancel_subscriptions: true         # cancel StreamSubscription in dispose
    close_sinks: true                  # close Sinks in dispose

    # Code quality
    prefer_const_constructors: true    # promote to const
    prefer_const_declarations: true
    prefer_final_locals: true          # immutable locals
    prefer_single_quotes: true         # consistent string style
    require_trailing_commas: true      # better diffs for multi-line args

    # Dart style
    always_use_package_imports: true   # no relative imports in lib/
    directives_ordering: true          # sort imports
    sort_constructors_first: true
```

## Disable a rule for one line

```dart
// ignore: avoid_print
print('debug only');
```

## Disable a rule for a file

```dart
// ignore_for_file: public_member_api_docs
```

## Common lint fixes

| Warning | Fix |
|---|---|
| `prefer_const_constructors` | Add `const` before `MyWidget(...)` |
| `avoid_print` | Replace with `debugPrint` or a logger |
| `unnecessary_this` | Remove `this.` prefix |
| `prefer_single_quotes` | Change `"..."` to `'...'` (dart format handles this) |
| `cancel_subscriptions` | Store `StreamSubscription` and call `.cancel()` in `dispose()` |
| `use_build_context_synchronously` | Don't use `context` after an `await` without a `mounted` check |

## use_build_context_synchronously — common flutter issue

```dart
// Bad — context may be invalid after await
Future<void> _submit() async {
  await repo.save(data);
  Navigator.of(context).pop(); // context might be unmounted
}

// Good
Future<void> _submit() async {
  await repo.save(data);
  if (!mounted) return;
  Navigator.of(context).pop();
}
```

## CI integration

```yaml
# .github/workflows/ci.yml
- name: Lint
  run: flutter analyze --fatal-infos

- name: Format check
  run: dart format lib/ test/ --set-exit-if-changed
```

## Gotchas

- `flutter analyze` respects `.gitignore` and skips generated files (`*.g.dart`, `*.freezed.dart`). If generated files show errors, re-run `dart run build_runner build`.
- `very_good_analysis` enables `public_member_api_docs`, which requires doc comments on every public symbol — disable it for app code (only useful for published packages).
- `prefer_const_constructors` fires frequently on widgets. Use `const` wherever the arguments are compile-time constants — it's a free performance win, not just a style choice.
- `dart format` uses 80-character line width by default. Pass `--line-length 120` to relax it if your team prefers wider lines.

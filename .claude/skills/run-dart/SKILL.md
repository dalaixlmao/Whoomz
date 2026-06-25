---
name: run-dart
description: Run, test, and smoke-check Dart language features — null safety, async/await, streams, generics, extensions. Use when asked to run a Dart snippet, verify a Dart language feature, or smoke-test Dart SDK behaviour in this project.
---

Dart 3.12.0 (arm64) is at `~/flutter/bin/dart`. This skill drives it as a CLI tool — write a `.dart` file, run it, observe stdout. No build step needed for single-file scripts.

## Prerequisites

No installs needed — Dart ships with Flutter:

```
~/flutter/bin/dart --version
# Dart SDK version: 3.12.0 (stable) … on "macos_arm64"
```

## Run (agent path)

Run the bundled smoke script that exercises all five language features:

```bash
~/flutter/bin/dart run .claude/skills/run-dart/smoke.dart
```

Expected output:

```
Hello, Dart!
Hello, stranger!
Box<int>: 42
Box<String>: hello
hahaha
Stream values: [1, 2, 3, 4, 5]
ALL CHECKS PASSED
```

To run an arbitrary snippet, write it to a temp file and run it the same way:

```bash
cat > /tmp/snippet.dart << 'EOF'
void main() { print('hello'); }
EOF
~/flutter/bin/dart run /tmp/snippet.dart
```

## What smoke.dart covers

- **Null safety** — nullable `String?` parameter with `??` fallback
- **Generics** — `Box<T>` class with type-parameterised `unwrap()`
- **Extensions** — `extension StringRepeat on String`
- **Async/await** — `await for` loop over a stream
- **Streams** — `async*` / `yield` generator

## Gotchas

- `dart run` prints `Running build hooks...` twice to stderr before output — this is normal for Flutter-bundled Dart and does not indicate an error.
- The dart binary at `~/flutter/bin/dart` is not on `$PATH` by default in new shells. Always use the full path.
- Single-file scripts do not need a `pubspec.yaml`. Multi-package work needs one; run `dart pub get` first.

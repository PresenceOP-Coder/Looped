# Contributing to Looped

Thanks for taking the time to contribute.

## Setup

1. Install Flutter and confirm your toolchain:

```bash
flutter doctor
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run checks before opening a PR:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

4. Run the app locally:

```bash
flutter run
```

## Branch and PR Guidelines

1. Create a focused branch from `main`.
2. Keep pull requests small and scoped to one change.
3. Include clear reproduction steps for bug fixes.
4. Add or update tests when behavior changes.
5. Ensure CI passes before requesting review.

## Commit Messages

Use concise, imperative messages, for example:

- `fix: prevent duplicate habit creation`
- `feat: add weekly streak card`

## Reporting Bugs and Requesting Features

Use GitHub issue templates:

- Bug report template for defects
- Feature request template for enhancements

## Security

Do not open public issues for vulnerabilities or leaked credentials.
Use the process in [SECURITY.md](SECURITY.md).
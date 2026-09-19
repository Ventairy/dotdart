# AGENTS.md — Documentation

## Purpose

`doc/` contains consumer documentation for Flutter developers using dotdart:
configuration, supported assets, troubleshooting, and performance guidance.
Keep maintainer workflows and implementation details in `CONTRIBUTING.md` or
the repository's root `AGENTS.md`. The `api/` subfolder contains generated
Dartdoc; do not edit it by hand.

## Writing style

- Be direct and use plain language familiar to Flutter developers.
- Explain what a feature means for the user: what works, what does not, and
  what they need to do.
- Avoid overly technical explanations, internal algorithms, and implementation
  terminology unless the reader needs them to configure or use the package.
- Use exact API names and configuration keys when needed. Explain unfamiliar
  terms briefly when they first appear.
- State limitations accurately without listing every internal validation rule.
  Do not imply broader format support than dotdart provides.
- When something is unsupported, give a practical next step or alternative.
- Prefer short paragraphs and concrete examples over long technical lists.

describe the visible effect, supported cases, limitations, and alternatives.
Do not explain the underlying chain or Flutter painting operations.

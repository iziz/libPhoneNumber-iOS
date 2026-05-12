# Issue-Driven Metadata Patch Policy

This project normally treats Google's libphonenumber metadata as the source of truth. Local metadata overrides are exceptional and must be handled as temporary, evidence-backed maintenance decisions.

## Default Position

- Prefer waiting for upstream Google libphonenumber when a numbering-plan change is not yet represented upstream.
- Do not patch generated metadata based only on user reports, screenshots, or app-specific failures.
- Do not patch metadata to satisfy a single carrier or market assumption unless the numbering authority evidence is clear.

## Required Evidence For Local Overrides

A local override may be considered only when at least one authoritative source confirms the numbering-plan change:

- National numbering authority publication.
- Regulator document or official numbering-plan update.
- Carrier allocation document that is public and directly tied to the national plan.
- Upstream Google libphonenumber issue or pull request with accepted maintainership signal.

The PR must link the evidence and describe the exact metadata field being overridden.

## Override Requirements

Every local metadata override must include:

- A focused test that fails without the override.
- The affected region, number range, and phone-number type.
- The upstream Google libphonenumber ref that does not yet contain the change.
- A removal condition, such as "remove when Google libphonenumber includes this range."
- A follow-up issue or checklist item to re-check on each metadata update.

## Expiry And Removal

Local overrides should be removed as soon as upstream metadata includes the change. During each metadata update:

1. Run `swift scripts/checkMetadataFreshness.swift`.
2. Re-run the override-specific tests.
3. Compare the affected region metadata against upstream.
4. Remove the override if upstream now covers the case.

## Applying This To Uganda 794

For issue #447, `v9.0.30` still excludes Uganda mobile `794` from the upstream mobile pattern. That means the issue is not automatically resolved by the metadata update.

The maintainable choices are:

- Wait for Google libphonenumber to include the range.
- Add a local override only after authoritative Uganda numbering-plan evidence is linked and a removal condition is documented.

Without that evidence, this project should not add a local metadata override.

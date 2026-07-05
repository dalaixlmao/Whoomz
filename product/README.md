# Whoomz — Product

Product planning for Whoomz, the conversation-first fitness app.

## Structure

```
features/
  v1_1.md    # features shipping in the 1st release
  v1_2.md    # features shipping in the 2nd release
  ...
```

One file per release: `features/v1_<number>.md` holds the features going into the
*number*-th release. A feature lives in exactly one release file; if it slips, move
it to the next file rather than duplicating it.

## Feature entry format

```markdown
## <Feature name>

**Status:** planned | in progress | shipped | cut
**Why:** one line on the user problem this solves.

Scope notes, decisions, and links (designs, PRs, issues).
```

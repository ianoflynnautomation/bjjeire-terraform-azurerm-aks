# Diagrams

## `architecture.drawio.svg`

The detailed platform topology. It is a **dual-format file**: a plain SVG that
GitHub renders inline anywhere it is referenced, carrying the draw.io model in
the root element's `content` attribute so the same file reopens as a fully
editable diagram.

**To edit:**

- **VS Code** — install the *Draw.io Integration* extension and open the file;
  it opens as a canvas, not as markup. Save writes both the picture and the
  model back.
- **Browser** — open [diagrams.net](https://app.diagrams.net/), then
  *File → Open from → Device* and pick this file. Export with
  *File → Export as → SVG* with **"Include a copy of my diagram"** ticked, or
  the file stops being editable next time.

Keep the `.drawio.svg` extension. It is what signals the editable-SVG format to
both tools.

## Conventions

| Element | Meaning |
|---|---|
| Solid blue edge | Request / data path |
| Dashed purple edge | OIDC, workload identity, Azure RBAC |
| Dotted grey edge | Node egress via the NAT Gateway |
| Dashed black edge | GitOps / CI control plane |
| Green dashed box | In-cluster, owned by `bjjeire-gitops` — not provisioned by this stack |

## Scope

This diagram shows the dev environment; staging and prod share the same root
module and differ only in the values listed in
[../architecture/environments.md](../architecture/environments.md).

The lighter, per-view Mermaid diagrams in [../architecture/](../architecture/)
are the ones to update for small changes — they render everywhere and cost
nothing to edit. Reach for this file when the change is structural.

> Replaced `architecture-diagram.csv` (a draw.io CSV import source), which
> GitHub rendered as a table of style attributes and which required a manual
> import to view.

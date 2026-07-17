# Open Collaborative Paper: Commentary on Forecasting Accuracy

This repository hosts an **open, community-driven academic paper**.
Anyone can contribute via GitHub issues and pull requests.

## How to contribute
- Open an issue for ideas, errors, or discussion
- Submit a pull request for text changes
- See [CONTRIBUTING.md](CONTRIBUTING.md) for authorship and review policy

## Build
The paper is automatically compiled to PDF via GitHub Actions, you can find the resulting pdf file in the "Actions" tab by then clicking on the last executed action, there will be a link to the pdf file.

## Build locally

Requirements: pandoc, LaTeX (e.g., texlive-latex-base, texlive-latex-extra), and `pdflatex` on PATH.

Command (from repo root):

```bash
pandoc paper/paper.md \
	--metadata-file=paper/metadata.yaml \
	--resource-path=.:paper:paper/images \
	--citeproc \
	--pdf-engine=pdflatex \
	-o output/paper.pdf
```

Notes:
- Images live under `paper/images`; the `--resource-path` flag ensures Pandoc finds them.
- Citations rely on `paper/references.bib`; `--citeproc` renders them.
- If you add a CSL file (e.g., `nature.csl`) to `paper/`, re-enable the `csl` line in `paper/metadata.yaml`.

## Visible draft comments in PDF

This project supports visible draft comments in the compiled PDF via LaTeX `todonotes`.

Current example:
- `paper/metadata.yaml` defines `\CBtodo{...}` for **Christoph Bergmeir**.
- `paper/paper.md` uses `\CBtodo{...}` in the recommendations section.

How contributors can add identifiable comments:
1. Add an author-specific command to `paper/metadata.yaml` under `header-includes`.
2. Use that command in `paper/paper.md` where you want a visible comment.

Example command for another contributor:

```yaml
header-includes:
	- '\newcommand{\ABtodo}[1]{\todo[inline,color=green!12]{\textbf{Alice Brown}: #1}}'
```

Then in the paper markdown:

```markdown
\ABtodo{Please check this claim against the latest reference.}
```

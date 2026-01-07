# Open Collaborative Paper: Commentary on Forecasting Accuracy

This repository hosts an **open, community-driven academic paper**.
Anyone can contribute via GitHub issues and pull requests.

## How to contribute
- Open an issue for ideas, errors, or discussion
- Submit a pull request for text changes
- See [CONTRIBUTING.md](CONTRIBUTING.md) for authorship and review policy

## Build
The paper is automatically compiled to PDF via GitHub Actions.

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

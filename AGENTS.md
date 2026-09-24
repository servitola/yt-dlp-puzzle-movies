# yt-dlp-puzzle-movies — agent rules

A yt-dlp extractor plugin for puzzle-movies.com, shipped as the Homebrew formula
`servitola/tap/yt-dlp-puzzle-movies`. `README.md` is for the person installing it and
stays short. This file is for whoever changes the code.

## Private

The repository is private on GitHub, and the code must not end up anywhere public:
no PyPI, no gists, no pasting into issues of other projects. The public tap carries
only the formula, which fetches a release asset through the GitHub API with a token.

## Layout

- `yt_dlp_plugins/extractor/puzzlemovies.py` is the whole plugin. yt-dlp imports
  plugins through the `yt_dlp_plugins` namespace package, so that path is fixed. Don't
  add an `__init__.py` to `yt_dlp_plugins/` or `extractor/`, and don't rename either
  directory.
- `tests/` holds offline unit tests. They build pages from inline HTML fixtures and
  mock `_download_webpage` and `_extract_m3u8_formats`.
- `pyproject.toml` holds tool settings only. There is no Python package, because
  Homebrew is the only distribution channel.

## Commands and gates

- `make test` runs pytest against the latest yt-dlp from PyPI.
- `make lint` runs ruff check and ruff format, with ruff pinned in the `Makefile`.
  `make format` fixes what it can.
- `make live URL=...` runs a real extraction against the site using this checkout,
  with any installed copy of the plugin switched off. Use it after any change to
  parsing. The unit tests only prove the parser matches the fixtures, not that the
  site still looks like them.
- CI (`.github/workflows/ci.yml`) runs lint and tests on every push to `main`.

Code follows yt-dlp's own style: single quotes, 120 columns. Comments explain why and
never what.

## How the site works (settled; re-verify before changing)

- `/films/<slug>` and `/<slug>` are different records, not two routes to the same
  page. `/films/the-mentalist` is a movie, and `/the-mentalist` is the series. The
  extractor reads `var media_type` from the page before choosing a layout.
- Series pages embed the episode list as `var episodes = [...]` JSON. Film pages
  expose `movieID`, `movieTitle` and `posterUrl` as JS variables.
- Manifests live on `cdn3.puzzle-movies.com` under one sitewide bucket id,
  `_CDN_BUCKET_ID`. It was checked on unrelated series and is not per-video:
  - series: `/<bucket>/series/video/<slug>/s<S>e<E>/video_hd.mp4/master.m3u8`
  - films: `/<bucket>/movies/<slug>/video_hd.mp4/master.m3u8`, 720p only, with no
    `video_sd` sibling.
- No cookies are needed. The extractor sends `Referer: https://puzzle-movies.com/`
  the way the site's own player does. On 2026-09-24 `master.m3u8` answered 200
  without it too, but the segments were never tested without it, so keep sending it.

## Release

To release, commit and push `main`, then run
`~/projects/homebrew-tap/bin/release-yt-dlp-puzzle-movies.sh <YYYY.MM.DD>`. It tags,
attaches a `git archive` tarball to the GitHub release and
bumps `url`/`sha256` in the formula. Tap CI can't reach a private release, so check a
release locally: `brew upgrade servitola/tap/yt-dlp-puzzle-movies && brew test
servitola/tap/yt-dlp-puzzle-movies`.

The formula links `yt_dlp_plugins/` into `$(brew --prefix)/lib/pythonX.Y/site-packages`.
Homebrew's yt-dlp virtualenv includes system site-packages, so the plugin is on its
`sys.path` without any setup. X.Y is the `python@` that yt-dlp's formula depends on.
When yt-dlp moves to a new Python, bump the formula's `revision` so it reinstalls under
the new path; `brew test` fails until then.

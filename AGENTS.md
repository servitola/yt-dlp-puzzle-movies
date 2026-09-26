# yt-dlp-puzzle-movies — agent rules

A yt-dlp extractor plugin for puzzle-movies.com. It ships as the Homebrew formula
`servitola/tap/yt-dlp-puzzle-movies` and as a drop-in zip attached to every GitHub
release. `README.md` is for the person installing it and stays short. This file is
everything needed to change, check and release the plugin from this checkout.

## Layout

- `yt_dlp_plugins/extractor/puzzlemovies.py` is the whole plugin. yt-dlp imports
  plugins through the `yt_dlp_plugins` namespace package, so that path is fixed. Don't
  add an `__init__.py` to `yt_dlp_plugins/` or `extractor/`, and don't rename either
  directory.
- `tests/` holds offline unit tests. They build pages from inline HTML fixtures and
  mock `_download_webpage` and `_extract_m3u8_formats`.
- `scripts/release.sh` is the release, end to end (see [Release](#release)).
- `pyproject.toml` holds tool settings only. There is no Python package: Homebrew and
  the release zip are the only distribution channels.

## Commands and gates

- `make test` runs pytest against the latest yt-dlp from PyPI.
- `make lint` runs ruff check and ruff format, with ruff pinned in the `Makefile`.
  `make format` fixes what it can.
- `make live URL=...` runs a real extraction against the site using this checkout,
  with any installed copy of the plugin switched off. Use it after any change to
  parsing. The unit tests only prove the parser matches the fixtures, not that the
  site still looks like them.
- CI (`.github/workflows/ci.yml`) runs lint and tests on every push to `main`. The
  release refuses to start until it is green on the commit being released.

Code follows yt-dlp's own style: single quotes, 120 columns. Comments explain why and
never what. One commit per logical change. The machine's commit hook rejects AI
co-author and tool footers.

## How the site works (settled; re-verify before changing)

- `/films/<slug>` and `/<slug>` are different records, not two routes to the same
  page. `/the-mentalist` is the series, and `/films/the-mentalist` is a separate film
  record, an empty one: its manifest has answered 404 since at least 2026-09-25. For a
  film that actually plays, use `/films/only-the-brave-2017`. The extractor reads
  `var media_type` from the page before choosing a layout.
- Series pages embed the episode list as `var episodes = [...]` JSON. A series comes
  back as a playlist of episode URLs, and each episode's manifest is fetched only when
  yt-dlp reaches it. Film pages expose `movieID`, `movieTitle` and `posterUrl` as JS
  variables.
- Manifests live on `cdn3.puzzle-movies.com` under one sitewide bucket id,
  `_CDN_BUCKET_ID`. It was checked on unrelated series and is not per-video:
  - series: `/<bucket>/series/video/<slug>/s<S>e<E>/video_hd.mp4/master.m3u8`
  - films: `/<bucket>/movies/<slug>/video_hd.mp4/master.m3u8`, 720p only, with no
    `video_sd` sibling.
- No cookies are needed. The extractor sends `Referer: https://puzzle-movies.com/`
  with the manifest and the segments, the way the site's own player does. Until
  2026-09-26 the segments went out without it and still downloaded, so the CDN does
  not require it yet. Keep sending it anyway.

When downloads break, the site changed. `make live` shows which step fails: the page
fetch, the `episodes` JSON, or the manifest URL. Fix the parser, update the fixtures in
`tests/` to the new page shape, then release.

## How it gets installed

- **Homebrew.** The formula lives in `servitola/homebrew-tap`, checked out at
  `~/projects/homebrew-tap` (override with `TAP_DIR`), in `Formula/yt-dlp-puzzle-movies.rb`.
  It builds from the tag's source tarball and links `yt_dlp_plugins/` into
  `$(brew --prefix)/lib/pythonX.Y/site-packages`. Homebrew's yt-dlp virtualenv includes
  system site-packages, so the plugin is on its `sys.path` with no symlink or config.
  X.Y is the `python@` that yt-dlp's formula depends on. When yt-dlp moves to a new
  Python, the plugin stops loading and `brew test` fails: bump `revision` in the formula
  so it reinstalls under the new path.
- **Release zip.** `yt-dlp-puzzle-movies.zip` holds `yt_dlp_plugins/` at its root, and
  yt-dlp loads it as is from `~/.config/yt-dlp/plugins/` (Windows:
  `%APPDATA%\yt-dlp\plugins`). GitHub's own "Source code" archive nests everything one
  level down and does not load that way.

`yt-dlp -v` prints `Extractor Plugins: PuzzleMoviesIE` and the directory it came from.
That is the first thing to check when the plugin seems missing. Two copies, for example
the brew one plus a zip, both show up in `Plugin directories`.

## Git

`origin` is the private primary remote, and GitHub is a force-mirror of it. Push only to
`origin`. Anything pushed to GitHub directly is erased by the next sync, and the
`github` remote is fetch-only. GitHub receives each push within about 20 seconds.

The repository is public. Don't commit anything about the private hosting: host names,
addresses, or the name of the software behind `origin`.

## Release

Releasing publishes: a tag, a GitHub release, and a tap commit that every Homebrew user
gets on `brew update`. Show the owner the dry run and get an explicit yes first.

1. Commit, `git push origin main`, and wait for `ci.yml` to go green on that commit.
2. `make release-plan` is `scripts/release.sh --dry-run`. It runs the preflight and
   prints the version and the notes (commit subjects since the last tag), then stops.
3. `make release` runs the whole release. The version defaults to today in Cyprus,
   `YYYY.MM.DD`, with a `.1`, `.2`, … suffix until it is above the highest tag ever made.
   Homebrew only upgrades upwards, and a reused name may sit in someone's download cache
   with another sha256. To force a version: `scripts/release.sh <version>`.

The script refuses to start on:
- a dirty tree, a branch other than `main`, or `main` not pushed or not yet mirrored;
- CI not green on the commit;
- a version that is not above the highest tag;
- local edits to the formula in the tap checkout, or the tap checkout behind its origin.

Then it:
1. tags, pushes the tag to `origin` and waits for GitHub;
2. builds the zip and checks that yt-dlp loads it;
3. creates the release with the zip attached;
4. writes the new `url` and `sha256` into the formula and runs `brew style`;
5. proves the formula in Homebrew's own clone of the tap (`brew audit --strict --online`,
   `brew upgrade`, `brew test`), then puts that clone back;
6. commits only the formula in the tap, pushes it, waits for the mirror and for the tap CI
   (`tests.yml`, which audits, installs and tests the formula on a clean runner);
7. checks that the installed yt-dlp loads the plugin.

### When a release breaks half-way

A tag the formula ever pointed at is never moved or deleted: the formula pins the
tarball's sha256. Fix forward with the next version.

| Where it stopped | State | What to do |
| --- | --- | --- |
| Preflight | nothing published | Fix what it names, run again. |
| Zip check or `gh release create` | tag pushed, no release, formula untouched | Nobody could have installed it, so delete it: `git tag -d <tag> && git push origin :refs/tags/<tag>`. Fix on `main`, release again. |
| Tarball not served yet | tag and release exist, formula untouched | Wait a minute and finish by hand: rewrite `url`/`sha256` in the formula and do steps 5–6 above. |
| Local audit, install or test | formula changed in the tap checkout, not pushed | Read the brew output. Fix the formula, or `git -C ~/projects/homebrew-tap checkout -- Formula/yt-dlp-puzzle-movies.rb` and release a fixed plugin. |
| Tap CI red | users get a broken formula on `brew update` | `gh run view <id> -R servitola/homebrew-tap --log-failed`. Fix forward with a tap commit, or `git revert` the formula commit, with the owner's yes. |

# puzzle-movies.com yt-dlp plugin

Personal-use yt-dlp plugin for downloading from puzzle-movies.com (requires an active paid subscription to browse the catalog, but the plugin itself does not need cookies)

**This is private. Do not publish or share this plugin.** The repository is
private on GitHub; the formula in the public tap fetches the release through the
GitHub API with the local `gh` login.

## Install

    brew install servitola/tap/yt-dlp-puzzle-movies
    mkdir -p ~/.config/yt-dlp/plugins
    ln -sfn "$(brew --prefix)/opt/yt-dlp-puzzle-movies/libexec" ~/.config/yt-dlp/plugins/yt-dlp-puzzle-movies

yt-dlp looks for plugins in `~/.config/yt-dlp/plugins`, `/etc/yt-dlp` and its
own virtualenv, and a formula can write to none of them, hence the symlink. It
goes through `opt`, so it survives upgrades of both this formula and yt-dlp.
The dotfiles `install/07-config-links.sh` makes it on every `up`.

`yt-dlp -v` prints `[debug] Extractor Plugins: PuzzleMoviesIE` once it is found.

## Usage

    # one episode
    yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1e2"

    # one season
    yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1"

    # whole series
    yt-dlp "https://puzzle-movies.com/the-mentalist"

    # a film
    yt-dlp "https://puzzle-movies.com/films/only-the-brave-2017"

Films and series are separate records with separate CDN layouts, and the
`/films/` prefix is what tells them apart — `/films/the-mentalist` is a movie
(id 2322), `/the-mentalist` the series. The extractor confirms the page it got
by reading `var media_type` before choosing a layout:

    series: /<bucket>/series/video/<slug>/s<S>e<E>/video_hd.mp4/master.m3u8
    films:  /<bucket>/movies/<slug>/video_hd.mp4/master.m3u8

Films come in one quality only (720p HD); there is no `video_sd` sibling.

## Run tests

    uv run --with yt-dlp --with pytest python -m pytest tests/ -v

## Release

    ~/projects/homebrew-tap/bin/release-yt-dlp-puzzle-movies.sh <YYYY.MM.DD>

Tags `main`, attaches a `git archive` tarball to a GitHub release and bumps
`url`/`sha256` in the tap formula.

## Known limitations

- No subtitles (site uses a custom in-page dictionary widget, not plain
  `.vtt`/`.srt`).

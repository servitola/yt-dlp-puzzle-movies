# yt-dlp-puzzle-movies

A [yt-dlp](https://github.com/yt-dlp/yt-dlp) plugin that downloads series and films
from [puzzle-movies.com](https://puzzle-movies.com). You need a subscription to browse
the catalogue, but the plugin itself needs no cookies.

## Install

```bash
brew install servitola/tap/yt-dlp-puzzle-movies
```

This also installs yt-dlp.
`yt-dlp -v` prints `Extractor Plugins: PuzzleMoviesIE` once the plugin is found.

### Manual

Use this with a yt-dlp that doesn't come from Homebrew:

```bash
curl -L --create-dirs -o ~/.config/yt-dlp/plugins/yt-dlp-puzzle-movies.zip \
  https://github.com/servitola/yt-dlp-puzzle-movies/releases/latest/download/yt-dlp-puzzle-movies.zip
```

Or download `yt-dlp-puzzle-movies.zip` from
[Releases](https://github.com/servitola/yt-dlp-puzzle-movies/releases) and put it
into the yt-dlp plugins folder as is, without unpacking. On Windows that folder is
`%APPDATA%\yt-dlp\plugins`. To update, replace the zip.

## Usage

```bash
yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1e2"   # one episode
yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1"     # one season
yt-dlp "https://puzzle-movies.com/the-mentalist"                      # whole series
yt-dlp "https://puzzle-movies.com/films/only-the-brave-2017"          # a film
```

Films come in 720p only. Subtitles are not supported: the site renders them with its
own in-page widget, not as `.vtt` or `.srt` files.

[MIT](LICENSE)

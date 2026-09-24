# yt-dlp-puzzle-movies

A [yt-dlp](https://github.com/yt-dlp/yt-dlp) plugin that downloads series and films
from [puzzle-movies.com](https://puzzle-movies.com). You need a subscription to browse
the catalogue, but the plugin itself needs no cookies.

**Private. Do not publish or share.**

## Install

```bash
brew install servitola/tap/yt-dlp-puzzle-movies
mkdir -p ~/.config/yt-dlp/plugins
ln -sfn "$(brew --prefix)/opt/yt-dlp-puzzle-movies/libexec" ~/.config/yt-dlp/plugins/yt-dlp-puzzle-movies
```

The release comes from a private repository, so Homebrew reads it with your `gh` login
(`gh auth login`) or with `HOMEBREW_GITHUB_API_TOKEN`. yt-dlp only looks for plugins
in places a formula cannot write to, which is why the link is a separate step. The link
points through `opt`, so upgrades don't break it. `yt-dlp -v` prints
`Extractor Plugins: PuzzleMoviesIE` once the plugin is found.

## Usage

```bash
yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1e2"   # one episode
yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1"     # one season
yt-dlp "https://puzzle-movies.com/the-mentalist"                      # whole series
yt-dlp "https://puzzle-movies.com/films/only-the-brave-2017"          # a film
```

Films come in 720p only. Subtitles are not supported: the site renders them with its
own in-page widget, not as `.vtt` or `.srt` files.

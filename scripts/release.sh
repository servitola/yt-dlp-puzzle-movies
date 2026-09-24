#!/usr/bin/env zsh
# Release yt-dlp-puzzle-movies: tag, GitHub release with the plugin zip, Homebrew formula bump.
# Usage: scripts/release.sh [--dry-run] [version]    (default version: today, YYYY.MM.DD[.N])
# Everything after the preflight leaves the machine; --dry-run stops before it.
set -euo pipefail

repo=${0:a:h:h}
gh_repo=servitola/yt-dlp-puzzle-movies
tap=${TAP_DIR:-$HOME/projects/homebrew-tap}
formula=Formula/yt-dlp-puzzle-movies.rb
name=servitola/tap/yt-dlp-puzzle-movies
dry=0
[[ ${1:-} == --dry-run ]] && { dry=1; shift }
(( $# <= 1 )) || { sed -n '2,4p' "$0" >&2; exit 2 }

die() { echo "release: $*" >&2; exit 1 }
step() { print -P "%B==> $*%b" }

# GitHub only ever receives what origin mirrors to it, a few seconds after the push.
wait_github() {  # <repo> <ref> <sha>
  for _ in {1..24}; do
    [[ $(gh api "repos/$1/commits/$2" -q .sha 2>/dev/null) == "$3" ]] && return 0
    sleep 5
  done
  die "GitHub did not receive $2 of $1"
}

wait_ci() {  # <repo> <workflow> <sha>
  local id=
  for _ in {1..24}; do
    id=$(gh run list -R "$1" --workflow "$2" --commit "$3" --limit 1 --json databaseId -q '.[0].databaseId')
    [[ -n $id ]] && break
    sleep 5
  done
  [[ -n $id ]] || die "no $2 run on $1@$3"
  gh run watch "$id" -R "$1" --exit-status >/dev/null || die "$2 failed on $1@$3: gh run view $id -R $1 --log-failed"
}

step "preflight"
git -C "$repo" fetch -q --tags origin
last=$(git -C "$repo" tag --list 'v*' | sort -V | tail -1)
# Homebrew only upgrades to a higher version, and a name that was ever published may sit in
# someone's download cache with another sha256, so a new version must be above the last tag.
newer() { [[ -z $last || $1 != "${last#v}" && $(printf '%s\n' "${last#v}" "$1" | sort -V | tail -1) == "$1" ]] }
if (( $# )); then
  version=$1
else
  version=$(TZ=Asia/Nicosia date +%Y.%m.%d)
  base=$version n=0
  until newer "$version"; do version=$base.$(( ++n )); done
fi
re='^[0-9]{4}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?$'
[[ $version =~ $re ]] || die "version must be YYYY.MM.DD or YYYY.MM.DD.N, got $version"
newer "$version" || die "version $version is not above the last tag $last"
tag=v$version
git -C "$repo" rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"
[[ -z $(git -C "$repo" status --porcelain) ]] || die "uncommitted changes in $repo"
[[ $(git -C "$repo" branch --show-current) == main ]] || die "not on main"
head=$(git -C "$repo" rev-parse HEAD)
[[ $head == $(git -C "$repo" rev-parse origin/main) ]] || die "main is not pushed to origin"
[[ $(gh api "repos/$gh_repo/commits/main" -q .sha) == "$head" ]] || die "GitHub main is not $head yet: wait for the mirror"
[[ $(gh run list -R "$gh_repo" --workflow ci.yml --commit "$head" --limit 1 --json conclusion -q '.[0].conclusion') == success ]] ||
  die "ci.yml is not green on $head: gh run list -R $gh_repo --workflow ci.yml"
[[ -f $tap/$formula ]] || die "no $formula in $tap (set TAP_DIR)"
git -C "$tap" diff --quiet -- "$formula" && git -C "$tap" diff --cached --quiet -- "$formula" || die "$tap/$formula has local edits"
git -C "$tap" fetch -q origin
[[ $(git -C "$tap" rev-parse HEAD) == $(git -C "$tap" rev-parse origin/main) ]] || die "$tap main differs from origin/main"

since=$(git -C "$repo" describe --tags --abbrev=0 2>/dev/null || true)
notes=$(git -C "$repo" log --format='- %s' ${since:+$since..}HEAD)
print "version: $version (tag $tag on $head)"
print "since ${since:-the first commit}:\n$notes"
(( dry )) && { print "dry run: nothing tagged, released or pushed"; exit 0 }

step "tag $tag"
git -C "$repo" tag -a "$tag" -m "yt-dlp-puzzle-movies $version"
git -C "$repo" push -q origin "$tag"
wait_github "$gh_repo" "$tag" "$head"

step "GitHub release"
# yt-dlp loads a zip with yt_dlp_plugins/ at its root straight from its plugins folder,
# which GitHub's own "Source code" archive is not: that one nests everything a level down.
# No version in the asset name, so releases/latest/download/<name> stays a stable link.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
zip=$work/yt-dlp-puzzle-movies.zip
git -C "$repo" archive --format=zip -o "$zip" "$tag" yt_dlp_plugins
mkdir "$work/plugins" && cp "$zip" "$work/plugins/"
yt-dlp --ignore-config --no-plugin-dirs --plugin-dirs "$work/plugins" -v 2>&1 | grep -q 'Extractor Plugins: PuzzleMoviesIE' ||
  die "yt-dlp does not load the release zip; $tag is pushed but not released"
gh release create "$tag" -R "$gh_repo" --verify-tag --title "yt-dlp-puzzle-movies $version" --notes "$notes

Homebrew: \`brew install $name\`. Any other yt-dlp: put yt-dlp-puzzle-movies.zip into ~/.config/yt-dlp/plugins/ as is." "$zip"

step "formula"
url="https://github.com/$gh_repo/archive/refs/tags/$tag.tar.gz"
sha=
for _ in {1..12}; do
  sha=$(curl -fsSL "$url" 2>/dev/null | shasum -a 256 | cut -d' ' -f1) && [[ $sha != e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 ]] && break
  sha=; sleep 5
done
[[ -n $sha ]] || die "GitHub does not serve $url yet; rerun from the formula step by hand"
sed -i '' -e "s|^  url \".*\"\$|  url \"$url\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$tap/$formula"
grep -qF "url \"$url\"" "$tap/$formula" && grep -q "sha256 \"$sha\"" "$tap/$formula" || die "formula bump failed"
brew style "$tap/$formula"

# Homebrew audits and installs only from its own clone of the tap, so the new formula is proven
# there before anyone else can fetch it, and the clone is put back so `brew update` still
# fast-forwards.
clone=$(brew --repo servitola/tap)
cp "$tap/$formula" "$clone/$formula"
export HOMEBREW_NO_AUTO_UPDATE=1
{
  brew audit --strict --online "$name" &&
    if brew list --versions "$name" >/dev/null; then brew upgrade "$name"; else brew install "$name"; fi &&
    brew test "$name"
} || { git -C "$clone" checkout -- "$formula"; die "formula failed locally; the tap is not pushed"; }
git -C "$clone" checkout -- "$formula"

step "tap"
git -C "$tap" commit -q -m "yt-dlp-puzzle-movies $version" -- "$formula"
git -C "$tap" push -q origin main
tap_head=$(git -C "$tap" rev-parse HEAD)
wait_github servitola/homebrew-tap main "$tap_head"
git -C "$clone" pull -q --ff-only
wait_ci servitola/homebrew-tap tests.yml "$tap_head"

yt-dlp -v 2>&1 | grep -q 'Extractor Plugins: PuzzleMoviesIE' || die "the installed yt-dlp does not load the plugin"
print "released $version: https://github.com/$gh_repo/releases/tag/$tag"

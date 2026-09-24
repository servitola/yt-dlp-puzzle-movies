RUFF := uvx ruff@0.16.8
URL ?= https://puzzle-movies.com/the-mentalist\#the-mentalist-s1e2

.PHONY: test lint format live

test:
	uv run --with yt-dlp --with pytest pytest

lint:
	$(RUFF) check .
	$(RUFF) format --check .

format:
	$(RUFF) format .
	$(RUFF) check --fix .

# yt-dlp takes a directory of plugin packages, and this checkout is one of them,
# so point it at the parent. --no-plugin-dirs keeps an installed copy out of the run.
live:
	yt-dlp --no-plugin-dirs --plugin-dirs "$(CURDIR)/.." --simulate -v "$(URL)"

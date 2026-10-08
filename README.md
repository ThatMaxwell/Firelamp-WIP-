# Firelamp OS

The best operating system for AI automation. An Arch-based Linux distro where your AI gets its own fire cursor and a live map of every window, button and text field.

Made with care by [ThatMaxwell](https://github.com/thatmaxwell).

## Launch site

The launch site lives in [`docs/`](docs/) and is plain HTML, CSS and JS with no build step: a language picker (English / Português), a 2-second loader, a ~30s launch intro rendered live in code with a soundtrack synthesized in the browser (Web Audio), then the scroll-animated site.

To publish it: **Settings → Pages → Deploy from a branch → `main` / `/docs`**.

To preview locally: `npx http-server docs` and open http://localhost:8080.

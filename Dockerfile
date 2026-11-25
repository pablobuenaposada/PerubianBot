FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:latest AS uv
FROM --platform=linux/amd64 debian:trixie-slim

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl firefox-esr ncurses-bin; \
    rm -rf /var/lib/apt/lists/*; \
    useradd --create-home --uid 10001 bot

ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
WORKDIR /app
COPY pyproject.toml uv.lock .python-version README.md LICENSE ./
COPY --from=uv /uv /usr/local/bin/uv
RUN uv sync --locked --no-dev --no-cache --managed-python

RUN set -eux; \
    release_json="$(curl -fsSL https://api.github.com/repos/mozilla/geckodriver/releases/latest)"; \
    driver_url="$(printf '%s' "$release_json" | .venv/bin/python -c 'import json, sys; print(next(asset["browser_download_url"] for asset in json.load(sys.stdin)["assets"] if asset["name"].endswith("-linux64.tar.gz")))')"; \
    curl -fsSL "$driver_url" -o /tmp/geckodriver.tar.gz; \
    tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin geckodriver; \
    rm /tmp/geckodriver.tar.gz

COPY perubianbot.py webs.py ./

ENV GECKODRIVER_PATH=/usr/local/bin/geckodriver \
    PYTHONUNBUFFERED=1 \
    TERM=xterm
USER bot
ENTRYPOINT ["uv", "run", "--no-sync", "python", "/app/perubianbot.py", "--headless"]

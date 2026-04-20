FROM python:3.12-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /repo

COPY paths_filter.py /app/paths_filter.py
COPY test_paths_filter.py /app/test_paths_filter.py

ENTRYPOINT ["python3", "/app/paths_filter.py"]

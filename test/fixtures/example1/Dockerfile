FROM ruby:3.2-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    libxml2 \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

FROM base AS build-packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libxml2-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

FROM build-packages AS development
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    silversearcher-ag \
    && rm -rf /var/lib/apt/lists/*

CMD ["sleep", "infinity"]

FROM build-packages AS build-assets

# Would build packages
# Should NOT install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    hello \
    cowsay \
    && rm -rf /var/lib/apt/lists/*

FROM base AS production

# would copy from build-assets as needed ...
# Should NOT install packages

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sl \
    fortune \
    && rm -rf /var/lib/apt/lists/*

CMD ["echo", "Override command!"]
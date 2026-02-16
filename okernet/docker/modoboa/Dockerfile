# syntax=docker/dockerfile:1.6

ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim-bookworm AS builder

ARG BUILD_VERSION=0.0.0
ENV SETUPTOOLS_SCM_PRETEND_VERSION=${BUILD_VERSION}
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Build deps (compile python wheels)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      git \
      pkg-config \
      libpq-dev \
      libsasl2-dev \
      libldap2-dev \
      librrd-dev \
      rrdtool \
      libmagic-dev \
      libffi-dev \
      libxml2-dev \
      libxslt1-dev \
      gettext \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . /src

# Build wheels for faster/cleaner runtime image
RUN python -m pip install --upgrade pip wheel setuptools setuptools_scm[toml] \
 && python -m pip wheel --wheel-dir=/wheels ".[postgresql,ldap]" \
 && python -m pip wheel --wheel-dir=/wheels gunicorn

FROM python:${PYTHON_VERSION}-slim-bookworm AS runtime

ARG BUILD_VERSION=0.0.0
ENV APP_VERSION=${BUILD_VERSION}
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Runtime libs (for compiled wheels / system integrations)
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 \
      libsasl2-2 \
      libldap-2.5-0 \
      librrd8 \
      rrdtool \
      libmagic1 \
      libffi8 \
      libxml2 \
      libxslt1.1 \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install wheels
COPY --from=builder /wheels /wheels
RUN python -m pip install --no-cache-dir /wheels/*.whl \
 && rm -rf /wheels

# Non-root runtime user
RUN useradd -r -u 10001 -g root -d /data -s /usr/sbin/nologin modoboa \
 && mkdir -p /data /shared/modoboa \
 && chown -R modoboa:root /data /shared/modoboa

COPY okernet/docker/modoboa/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY okernet/docker/modoboa/init.sh okernet/docker/modoboa/django-hardening.py okernet/docker/modoboa/mail-config.sh /scripts/
RUN chmod +x /scripts/*.sh

EXPOSE 8000
VOLUME ["/data", "/shared/modoboa"]

USER modoboa
ENTRYPOINT ["/entrypoint.sh"]

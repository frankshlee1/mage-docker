###
# MAGE Docker image
#
# Feel free to add or customise the image according to your needs.
###
ARG node_version=9.2.0
ARG base_image=node:${node_version}

FROM ${base_image}
MAINTAINER Marc Trudel <mtrudel@wizcorp.jp>

# System dependencies
RUN ((test -f /etc/alpine-release) \
        && (apk update \
            && apk add sudo vim bash-completion ncurses zeromq-dev || exit 1)) \
        || \
    ((test -f /etc/debian_version) \
        && (test $(cat /etc/debian_version | cut -d "." -f1) = 7 && \
                echo 'deb http://ftp.debian.org/debian wheezy-backports main' > \
                /etc/apt/sources.list.d/backports.list || true) \
        && (test $(cat /etc/debian_version | cut -d "." -f1) = 8 && \
                echo 'deb http://ftp.debian.org/debian jessie-backports main' > \
                /etc/apt/sources.list.d/backports.list || true)\
            && apt-get -qq update \
            && apt-get -qq install apt-utils \
            && apt-get -qq install --no-install-recommends sudo vim bash-completion libzmq3-dev \
            && apt-get clean all || exit 1)

# Update NPM
RUN cd /tmp \
        && ((test $(npm -v | tr -d 'v' | cut -d\. -f 1) -le 4) \
                && npm install npm@5 \
                && rm -rf /usr/local/lib/node_modules \
                && mv node_modules /usr/local/lib) \
        || npm -v

# Create an app user to run things from
RUN ((test -f /etc/alpine-release) \
        && adduser -h /home/app -D app \
        && echo "app:app" | chpasswd \
        && addgroup sudo \
        && adduser app sudo \
        && sed -i'' 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers || exit 1) \
        || \
    ((test -f /etc/debian_version) \
        && useradd -m app \
        && echo "app:app" | chpasswd \
        && adduser app sudo || exit 1)

# Have the app user own the app folder
RUN ((test -d /usr/src/app) && exit 1) || \
        (mkdir -p /usr/src/app && chown app.app /usr/src/app)

# Make app user a sudoer
RUN echo "app         ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch current user to app
USER app

# Copy custom bashrc file
COPY .bashrc /home/app
RUN test -f /etc/alpine-release \
        && cd /home/app \
        && ln -s .bashrc .profile || true
 
# Environment variables
# Set EDITOR variable (for git)
ENV EDITOR=vim

# Set working directory (this will get mounted during development)
WORKDIR /usr/src/app

# Load files and install dependencies
ONBUILD ARG node_env=production
ONBUILD ARG npm_flags
ONBUILD ARG npm_loglevel=http

ONBUILD ENV NODE_ENV=${node_env}
ONBUILD ENV NPM_CONFIG_LOGLEVEL=${npm_loglevel}
ONBUILD COPY package.json /usr/src/app
ONBUILD COPY package-lock.json /usr/src/app
ONBUILD RUN npm install ${npm_flags} \
      && npm cache clean --force
ONBUILD COPY . /usr/src/app

# Stop signal
STOPSIGNAL SIGTERM

# Command to run
CMD ["npm", "run", "mage"]

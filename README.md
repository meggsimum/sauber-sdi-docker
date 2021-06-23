# SAUBER SDI Docker

Docker setup for the SDI of the [SAUBER](https://sauber-projekt.de) project.

## Start Setup

Prerequisites: [Docker](https://www.docker.com/) and [Docker Stack](https://docs.docker.com/engine/reference/commandline/stack/) have to be installed on your target platform.

  - Clone or download this repository
  - Navigate to the checkout / download in a terminal, e.g.
    `cd /path/checkout/sauber-sdi-docker`
  - Run

    ```
    docker stack deploy -c docker-stack.yml <stack-name>
    ```
    e.g.
    ```
    docker stack deploy -c docker-stack.yml sauber-stack-local
    ```

## Prod Setup

In order to fire up the SDI on a production machine or you want to simulate this on your local machine we provide some helper scripts.
Execute the following:

```bash
# starts the setup with the latest images from Docker Hub
# see https://hub.docker.com/u/sauberprojekt
./build-and-start.sh SKIPBUILD

```

## Dev Setup

### Build and Start

In case you want to fire up the SDI setup with local images, which are explicitly built for the dev setup execute the following:

```bash
# build all images locally with the tag 'foobar' and starts the setup
TAG=foobar ./build-and-start.sh
```

**CAUTION: This can take some time since all images are built**

### Build only

Build all images of the stack locally with the given tag (default is master):

```bash
# build all images locally with the tag 'foobar'
TAG=foobar ./build-images.sh
```
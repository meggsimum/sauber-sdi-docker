# SAUBER SDI Docker

Docker setup for the SDI of the [SAUBER](https://sauber-projekt.de) project.

## Start Setup

Prerequisites: [Docker](https://www.docker.com/) and [Docker Stack](https://docs.docker.com/engine/reference/commandline/stack/) have to be installed on your target plattform.

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

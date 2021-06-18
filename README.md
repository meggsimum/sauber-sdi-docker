# SAUBER SDI Docker

Docker setup for the SDI of the [SAUBER](https://sauber-projekt.de) project.

## Start Setup

Prerequisites: [Docker](https://www.docker.com/) and [Docker Stack](https://docs.docker.com/engine/reference/commandline/stack/) have to be installed on your target plattform.

  - Clone or download this repository
  - Navigate to the checkout / download in a terminal, e.g.
    `cd /path/checkout/sauber-sdi-docker`
  - Run

    ```
    build-and-start.sh 
    ```
    Which builds all relevant images on the local machine and deploys the SAUBER SDI as *docker stack*. 

    **Flags**: 
    
    `SKIPBUILD=1`: Skip the *docker build* process and pull the images directly from the projects DockerHub repository. Default: 0. 

    `export TAG=<tagname> build-and-start.sh`: Use specific *docker image tag* for images. This allows for local versioning of images and helps ensuring which tag is being used by the *docker stack*. Avoid using *latest*-tag for images. Default: "master".

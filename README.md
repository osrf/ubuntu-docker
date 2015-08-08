# ubuntu-docker
This contains the Ubuntu images used for OSRF's docker based build farm. Included are the tools used to build core images for various architectures and releases.

# Usage
## Structure
#### `config.yaml`
The configuration for creating docker images for various archachers is encapsulated in this file. It holds the list of tags or suites to build for each architecture as well as some global parameters for the python tool. This can be altered to build images under your own user profile, enable or disable core and image builds, as well as core and image pushes or print a dry run of commands to be called.
``` yaml
username:
    osrf
build_core:
    true
push_core:
    false
build_image:
    true
push_image:
    false
dry:
    false
architectures:
    armhf:
        suites:
            - trusty
    arm64:
        suites:
            - trusty
```


#### `make.py`
This is the main python script that is invoked to parse the `config.yaml` file and builds/pushes the required docker images as specified. This tool is simply invoked by specifying the location of config file and architecture directories. Calling the tool from within the directory would look like so:

```
./make.py dir -d .
```

#### `build_core.sh`
This is shell script that is used to download the core Ubuntu image and build up the costume chroot used to create the core docker image. This is a shell script repetitively called by the python tool. To call this script manually, it take two parameters like so:
``` shell
./build_core.sh --arch armhf --suite trusty
```

#### Dockerfiles
There are Dockerfiles within every suite folder for each architecture directory. This is used to add the final touches and updates to the buildfarm images. The core images are expected to change relatively little overtime. So a Dockerfile can be built from the same core image to periodically bring the buildfarm up to date. To manually build the image with the core image available locally from the repo's root folder would be of this form:
``` shell
docker build --tag <username>/ubuntu_<arch>:<suite> <arch>/<suite>/.
```


## Building
Simply enable the desired build flags in the config file and run the python tool. You will need super user prevleges so that the build_core.sh script may write to the chroot directory. This may also required to interface with the docker client depending how you created your Docker group. See the docker [installation guide](https://docs.docker.com/installation/ubuntulinux/#Create_a_Docker_group).

## Pushing Images
Simply enable the desired push flags in the config file and run the python tool. You will need to be logged into your Docker Hub account to push to the public registry. See the dockerhub [userguide](https://docs.docker.com/userguide/dockerhub/).

# docker-registry-cleanup
Script to cleanup your private Docker v2 registry.
## Prerequisites
- curl
- jq
- perl
- sort
- sed
- cut
## Install
Change the variable REGISTRY to your registry DNS and the variable REGISTRYDATA to the local storage folder of the REGISTRY.
The script must be run on the server where the Docker Registry v2 is running.
## Run
It will loop through all repositories and ask you which tags should be removed.
Then it will run mortensrasmussen/docker-registry-manifest-cleanup to remove unused manifests.
Finally it will run the Docker registry garbage collection to free up the storage.

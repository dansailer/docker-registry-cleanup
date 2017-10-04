#! /bin/bash
REGISTRY="YOURREGISTRY:5000"
REGISTRYDATA="/var/opt/docker_registry/data"
echo -e "\e[1;36m$(date '+%Y-%m-%d %H:%M:%S') ------------------------------------------------------------------------------------------\e[0m"
IGNORETAGS="latest|^$(perl -MPOSIX -le '@now = localtime; $now[4] -= 1; $now[3] = 1; print strftime("%Y%m", localtime mktime @now);')|^$(perl -MPOSIX -le '@now = localtime; $now[3] = 1; print strftime("%Y%m", localtime mktime @now);')"
echo "We will be ignoring tags whitch follow this patter: ${IGNORETAGS}"
read -p "Do you want to continue? [y/N] " response
response=${response,,} # tolower
if [[ ! $response =~ ^(yes|y) ]]; then
    echo "exiting..."
    exit
fi
echo -e "\e[1;36m$(date '+%Y-%m-%d %H:%M:%S') -  Getting all repositories from the registry ${REGISTRY}                                -\e[0m"
IMAGENAMES=$(curl -s https://${REGISTRY}/v2/_catalog | jq .repositories[] | sed 's/"//g')
for IMAGENAME in ${IMAGENAMES}; do
    echo -e "\e[1;36m$(date '+%Y-%m-%d %H:%M:%S') ------------------------------------------------------------------------------------------\e[0m"
    echo -e "\e[1;36m$(date '+%Y-%m-%d %H:%M:%S') -  ${IMAGENAME}                                                                          -\e[0m"
    echo -e "\e[1;36m$(date '+%Y-%m-%d %H:%M:%S') ------------------------------------------------------------------------------------------\e[0m"
    TAGS=$(curl -s https://${REGISTRY}/v2/${IMAGENAME}/tags/list | jq .tags[] 2>/dev/null | sed 's/"//g' | sort | grep -Eiv "${IGNORETAGS}")
    echo "${TAGS}"
    if [[ "${TAGS}" != "" ]]; then
        read -p "Would you like to delete ALL those image tags? [y/N] " response
        response=${response,,} # tolower
        if [[ $response =~ ^(yes|y) ]]; then
            for TAG in ${TAGS}; do
                MANIFEST=$(curl -D - -s -o /dev/null -H "Accept: application/vnd.docker.distribution.manifest.v2+json" https://${REGISTRY}/v2/${IMAGENAME}/manifests/${TAG} | \grep Docker-Content-Digest | cut -d: -f2-3 | sed 's/ //g' | tr -dc '[[:print:]]')
                echo "Deleting ${TAG} / ${MANIFEST} ..."
                curl -w "%{http_code}" -X DELETE https://${REGISTRY}/v2/${IMAGENAME}/manifests/${MANIFEST}
                #curl -w "%{http_code}" -X DELETE https://${REGISTRY}/v2/${IMAGENAME}/blobs/${MANIFEST}
                echo ""
            done
        else
            for TAG in ${TAGS}; do
                read -p "Would you like to delete image tag ${TAG}? [y/N] " response
                response=${response,,} # tolower
                if [[ $response =~ ^(yes|y) ]]; then
                    MANIFEST=$(curl -D - -s -o /dev/null -H "Accept: application/vnd.docker.distribution.manifest.v2+json" https://${REGISTRY}/v2/${IMAGENAME}/manifests/${TAG} | \grep Docker-Content-Digest | cut -d: -f2-3 | sed 's/ //g' | tr -dc '[[:print:]]')
                    echo "Deleting ${TAG} / ${MANIFEST} ..."
                    curl -w "%{http_code}" -X DELETE https://${REGISTRY}/v2/${IMAGENAME}/manifests/${MANIFEST}
                    #curl -w "%{http_code}" -X DELETE https://${REGISTRY}/v2/${IMAGENAME}/blobs/${MANIFEST}
                    echo ""
                fi
            done
        fi
    fi
done

docker run -it -v /etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt:ro -v ${REGISTRYDATA}:/registry -e "REGISTRY_URL=https://${REGISTRY}" -e "CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt" -e DRY_RUN=true mortensrasmussen/docker-registry-manifest-cleanup
read -p "Would you like to run this command? [y/N] " response
response=${response,,} # tolower
if [[ $response =~ ^(yes|y) ]]; then
    docker run -it -v /etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt:ro -v ${REGISTRYDATA}:/registry -e "REGISTRY_URL=https://${REGISTRY}" -e "CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt" mortensrasmussen/docker-registry-manifest-cleanup
fi
docker exec -it $(docker ps | grep "docker-registry\." | awk '{ print $1 }') bin/registry garbage-collect --dry-run /etc/docker/registry/config.yml
read -p "Would you like to run this command? [y/N] " response
response=${response,,} # tolower
if [[ $response =~ ^(yes|y) ]]; then
    docker exec -it $(docker ps | grep "docker-registry\." | awk '{ print $1 }') bin/registry garbage-collect /etc/docker/registry/config.yml
fi



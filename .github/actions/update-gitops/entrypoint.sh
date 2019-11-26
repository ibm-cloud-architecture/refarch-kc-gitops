#!/bin/bash

REGISTRY_URL="https://registry.hub.docker.com/v1/repositories/__IMAGE_NAME__/tags"

##TODO## Explode into CSL for 'input'
COMPONENTS=(
  fleetms
  kc-ui
  ordercommandms
  orderqueryms
  reefersimulator
  springcontainerms
  voyagesms
)

#COMPONENTS=(
#  kc-ui
#)

##TODO## Parameterize into 'input'
REPO_NAME=ibmcase

for COMPONENT in ${COMPONENTS[@]}; do
  echo "Updating GitOps YAMLs for '${COMPONENT}'"
  IMAGE_NAME=$(cat ${COMPONENT}/templates/deployment.yaml | grep "image:" | sed 's/.*image\: \"//' | sed 's/\:.*$//')
  echo "Calculated image name: ${IMAGE_NAME}"

  CURRENT_VER_TAG=$(cat ${COMPONENT}/templates/deployment.yaml | grep "image:" | grep --only-matching -e "[0-9]*\.[0-9]*\.[0-9]*")
  echo "Calculated current tag: ${CURRENT_VER_TAG}"

  LATEST_VER_URL=${REGISTRY_URL/__IMAGE_NAME__/${IMAGE_NAME}}
  #Get latest tag, formatted for greatest semantic version value
  LATEST_VER_TAG=$(curl --silent ${LATEST_VER_URL} | jq -r '.[] | select(.name|test("[0-9].[0-9].[0-9]")) | .name' | sort -V | tail -n1)
  echo "Calculated latest tag: ${LATEST_VER_TAG}"

  # Split {REPO_NAME}/{IMAGE_NAME} into only {IMAGE_NAME}
  IMAGE_SHORT_NAME=${IMAGE_NAME/${REPO_NAME}\//""}

  # Replace current version (in the pattern of kcontainer-ui:X.Y.Z)
  sed -i "" -e "s/${IMAGE_SHORT_NAME}\:${CURRENT_VER_TAG}/${IMAGE_SHORT_NAME}\:${LATEST_VER_TAG}/" ${COMPONENT}/templates/deployment.yaml

  cat ${COMPONENT}/templates/deployment.yaml

  echo ""
done

##TODO
# 1. Turn this into an in-repo action
# 2. Create the following flow
#  -`git-clone` as first step (OPEN QUESTIONS patterns for correct branch)
#  - this action as second step
#  - git commit & push as third step
# 3. Kick that off on a schedule & validate it works
# 4. Integrate it with a repository_dispatch event
# 5. Build repository_dispatch into source code dockerbuild.yaml

###TBD
#update-gitops-repo:
#    runs-on: ubuntu-latest
#    env:
#      GITOPS_TOKEN: ${{ secrets.GITOPS_TOKEN }}
#      GITOPS_REPO: ${{ secrets.GITOPS_REPO }}
#      GITOPS_BRANCH: ${{ secrets.GITOPS_BRANCH }}
#    steps:
#      - name: Update deployment yamls
#        shell: bash
#        run: |
#          git clone ${{ secrets.GITOPS_REPO }} gitops
#          cd gitops
#          git checkout ${GITOPS_BRANCH}
#
#      - name: Commit files
#        run: |
#          IMAGE_TAG=$(cat cached-build-tag/latest_tag.txt)
#          cd gitops
#          git config --local user.email "gitops@ibmcloud.com"
#          git config --local user.name "gitops-automation"
#          git commit -m "Update to image ${IMAGE_TAG} for ${GITHUB_REPOSITORY}" -a
#      - name: Push changes
#        with:
#          github_token: ${{ secrets.GITOPS_TOKEN }}
#          repository: ${{ secrets.GITOPS_REPO }}
#          branch: ${{ secrets.GITOPS_BRANCH }}
#          directory: "gitops"

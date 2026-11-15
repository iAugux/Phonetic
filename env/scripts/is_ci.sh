#!/bin/bash

CI_ENVIRONMENT_VARIABLES=(
  JENKINS_HOME
  JENKINS_URL
  TRAVIS
  CI
  CIRCLECI
  APPCENTER_BUILD_ID
  TEAMCITY_VERSION
  GO_PIPELINE_NAME
  bamboo_buildKey
  GITLAB_CI
  XCS
  TF_BUILD
  GITHUB_ACTION
  GITHUB_ACTIONS
  BITRISE_IO
  BUDDY
)

for KEY in "${CI_ENVIRONMENT_VARIABLES[@]}"; do
  VALUE=$(printenv $KEY)
  if [[ ! -z "$VALUE" ]]; then
    echo "true"
    exit 0 # Indicates success, i.e. it's CI
  fi
done

echo "false"
exit 1 # Indicates failure, i.e. it's not CI
#!/bin/bash

OCP_VERSION=4.14
INDEX_NAME=certified-operator-index
#example: registry.redhat.io/redhat/redhat-operator-index:v4.14
INDEX_LOCATION=registry.redhat.io/redhat/$INDEX_NAME:v$OCP_VERSION
LOCAL_REGISTRY="hub-helper:5000"
LOCAL_REPOSITORY="operators"

declare -A OPERATORS=(
  ["sriov-fec"]="sriov-fec.v2.7.2"
  ["datadog-operator-certified"]="datadog-operator.v1.5.0"
  ["vault-secrets-operator"]="vault-secrets-operator.v0.6.0"
  )

basedir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

workspace="$basedir/operators/$OCP_VERSION"
full_index="$workspace/index-full.yaml"
tuned_index="$workspace/$INDEX_NAME/index.yaml"

init(){
  echo "creating workspace: $workspace/$INDEX_NAME."
  mkdir -p "$workspace/$INDEX_NAME"
  touch "$tuned_index"
  > "$tuned_index"
}

get_full_index(){
  echo "fetching full operator index from $INDEX_LOCATION to $full_index."
  opm render $INDEX_LOCATION -o yaml > "$full_index"
}

generate_dockerfile(){
  if [[ ! -f "$workspace/$INDEX_NAME.Dockerfile" ]]; then
    echo "generator $workspace/$INDEX_NAME.Dockerfile."
    opm generate dockerfile "$workspace/$INDEX_NAME"
  else
    echo "file $workspace/$INDEX_NAME.Dockerfile exists."
  fi
}

build_index_image(){
  echo "build container image with $workspace/$INDEX_NAME.Dockerfile."
  podman build ${workspace} -f $workspace/$INDEX_NAME.Dockerfile -t "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/${INDEX_NAME}:v${OCP_VERSION}"

  echo "push container image ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/${INDEX_NAME}:v${OCP_VERSION}."
  podman push ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/${INDEX_NAME}:v${OCP_VERSION}

  echo
  echo "you can use: ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/${INDEX_NAME}:v${OCP_VERSION} as operator catalog index on your cluster."
}

build_index(){
  export operator=$1
  export max_version=$2
  local op_workspace="$workspace/$operator"/"$max_version"
  mkdir -p "$op_workspace"

  #get olm.package
  echo "[$operator]: generating olm-package."
  yq '. | select(.schema=="olm.package" and .name == env(operator) and .defaultChannel=="stable")' "$full_index" > "$op_workspace"/olm-package.yaml

  echo "[$operator]: processing olm-channel, generating olm-channel-original.yaml."
  #get original olm.channel
  yq '. | select(.schema=="olm.channel" and .package == env(operator) and .name=="stable")' "$full_index" > "$op_workspace"/olm-channel-original.yaml

  #fetch the name/skipRange of the one desired to keep
  local entry_name_keep=$(yq '.entries[] | select(.name == env(max_version))|.name' "$op_workspace"/olm-channel-original.yaml)
  local entry_skipRange_keep=$(yq '.entries[] | select(.name == env(max_version))|.skipRange' "$op_workspace"/olm-channel-original.yaml)
  local entry_replace_keep=$(yq '.entries[] | select(.name == env(max_version))|.replaces' "$op_workspace"/olm-channel-original.yaml)

  #fetch the name/skipRange of the latest one on the index
  export entry_name_latest=$(yq '.entries[].name' "$op_workspace"/olm-channel-original.yaml |sort -r |head -n1)
  export min_version=$(yq '.entries[].name' "$op_workspace"/olm-channel-original.yaml |sort |head -n1)
  local entry_skipRange_latest=$(yq '.entries[]|select(.name == env(entry_name_latest)) |.skipRange' "$op_workspace"/olm-channel-original.yaml)
  local entry_replaces_latest=$(yq '.entries[]|select(.name == env(entry_name_latest)) |.replaces' "$op_workspace"/olm-channel-original.yaml)

  if [[ "$entry_name_keep" == "$entry_name_latest" ]]; then
    echo "[$operator]: $entry_name_keep is the latest one, no need update olm-channel.yaml."
    cp "$op_workspace"/olm-channel-original.yaml "$op_workspace"/olm-channel.yaml
  else
    echo "[$operator]: $entry_name_keep is different with the latest version $entry_name_latest: will update olm-channel.yaml."
    echo "[$operator]: deleting $max_version from the entries in olm-channel."
    yq 'del( .entries[] |select(.name == env(max_version)))' "$op_workspace"/olm-channel-original.yaml > "$op_workspace"/olm-channel-updated-0.yaml

    echo "[$operator]: patching \"latest\" to point instead of $entry_name_latest to $max_version in olm-channel."
    sed  "s/name: ${entry_name_latest}/name: ${entry_name_keep}/g" "$op_workspace"/olm-channel-updated-0.yaml > "$op_workspace"/olm-channel-updated-1.yaml
    sed  "s/skipRange: '${entry_skipRange_latest}'/skipRange: '${entry_skipRange_keep}'/g" "$op_workspace"/olm-channel-updated-1.yaml > "$op_workspace"/olm-channel-updated-2.yaml
    #some operator doesn't have '' in the skipRange
    sed  "s/skipRange: ${entry_skipRange_latest}/skipRange: '${entry_skipRange_keep}'/g" "$op_workspace"/olm-channel-updated-2.yaml > "$op_workspace"/olm-channel-updated-3.yaml
    sed  "s/replaces: '${entry_skipRange_latest}'/replaces: '${entry_replace_keep}'/g" "$op_workspace"/olm-channel-updated-3.yaml > "$op_workspace"/olm-channel-updated-4.yaml
    sed  "s/replaces: ${entry_replaces_latest}/replaces: ${entry_replace_keep}/g" "$op_workspace"/olm-channel-updated-4.yaml > "$op_workspace"/olm-channel-updated-5.yaml

    echo "[$operator]: deleting entries whose version is greater than $max_version in olm-channel."
    yq 'del( .entries[] |select(.name > env(max_version)))' "$op_workspace"/olm-channel-updated-5.yaml > "$op_workspace"/olm-channel-updated-6.yaml

    echo "[$operator]: deleting versions greater than $max_version from the skips in olm-channel."
    yq '.entries[]| select(.name == env(max_version)).skips |del(.[] | select(. >= env(max_version)))|parent|parent|parent' "$op_workspace"/olm-channel-updated-6.yaml  > "$op_workspace"/olm-channel.yaml
  fi

  echo "[$operator]: generating olm-bundles version <= $max_version."
  #get olm.bundles lower than $max_version
  yq '. | select(.schema=="olm.bundle" and .package == env(operator) and .name >= env(min_version) and .name <= env(max_version))' "$full_index" > "$op_workspace"/olm-bundles.yaml

  echo "---" >> $tuned_index
  cat "$op_workspace"/olm-package.yaml >> $tuned_index
  echo "---" >> $tuned_index
  cat "$op_workspace"/olm-channel.yaml >> $tuned_index
  echo "---" >> $tuned_index
  cat "$op_workspace"/olm-bundles.yaml >> $tuned_index

  echo "[$operator]: completed."
}

init
get_full_index

echo
echo "processing olm files:"

for key in "${!OPERATORS[@]}"; do
  build_index "$key" "${OPERATORS[$key]}"
  echo
done

generate_dockerfile
build_index_image

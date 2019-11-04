#!/usr/bin/env bash

debug() {
    if [[ "$DEBUG" -gt 0 ]]; then
       echo "===> [${FUNCNAME[1]}] $*" 1>&2
    fi
}
_run() {
    if [[ "$DRY" ]]; then
      debug '---> DRY-RUN'
      echo "$@" | sed 's/ -/ \\\n -/g'
    else 
      "$@"
    fi
}

delete() {
  declare user=$1

  : ${user:? required}
  _run kubectl delete ns,sa,deploy,svc,ing,clusterrolebinding,rolebinding \
  -l user=user3
}

createWorkshopHack() {
  : ${user:=user3}

  _run kubectl apply -k ${user}-workshop-hack
}

dev(){
  declare dev=$1
  
  : ${dev:? required}
  local newDir=new
  debug "generate new yaml set into dir: ${newDir} ..."
  mkdir -p ${newDir}
  tar c -C template/ . | tar -xv -C ${newDir}
   find ${newDir} -name kustomization.yaml \
     -exec  sed -i "s/user3/${dev}/g" {} \;

  create ${newDir}
}

create() {
  declare dir=$1
  : ${dir:=template}
  : ${user:=user}
  : ${cloud:=gcp}

  _run kubectl apply -k ${dir}/${user}-workshop-${cloud}
  _run kubectl apply -k ${dir}/${user}-ns
  _run kubectl apply -k ${dir}/${user}-play-ns
}

main() {
  : ${DEBUG:=1}  
  # if last arg is --dry sets DRY=1
  [[ ${@:$#} =~ --dry ]] && { set -- "${@:1:$(($#-1))}" ; DRY=1 ; } || :

  if [[ $1 =~ :: ]]; then 
    debug DIRECT-COMMAND  ...
    command=${1#::}
    shift
    $command "$@"
  else 
    echo "default command: todo ..."
  fi 
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || true


function debug () {
  [[ "$DEBUG" ]] && builtin echo $@ || return 0
}

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}
export -f contains

function applyRepopick(){
  change=$1
  options="$2"
  if [ $(contains "${ARRAY[@]}" "$change") == "y" ]; then
    debug "Skipping change $change - already applied in this session or it is excluded"
  else
    echo "Apply change $change"
    python ./vendor/lineage/build/tools/repopick.py -c 50 $options $change
    curl -s -H 'Accept-Type: application/json' "https://review.lineageos.org/changes/$change" | tail -n +2 | jq -r '{project, _number, subject} | {topic: "\(._number|tostring) # \(.project) # \(.subject)"} | join("\t")' >>$OUT_FILE
    ARRAY+=($change)
  fi
}
export -f applyRepopick

function reverse(){
    echo "$1" | awk '{for(i=NF;i>=1;i--) printf "%s ", $i;print ""}' | tac
}

function querySubmittedTogether(){
    change=$1
    curl -s -H 'Accept-Type: application/json' "https://review.lineageos.org/changes/${change}/submitted_together" | tail -n +2 | jq -r '.[]._number'
}
export -f querySubmittedTogether

function exclude(){
     excludedChanges=$1
     echo "Exclude changes: $excludedChanges"
     for excludedItem in ${excludedChanges[*]}
     do
         echo "Exclude $excludedItem"
         ARRAY+=($excludedItem)
     done
}
export -f exclude

function queryGerrit(){
     fetchSubmittedTogether=$1
     query=$2
     excludedChanges=$3
     exclude "$excludedChanges"
     echo "Perform query $query"
     change_list=$(curl -s -H 'Accept-Type: application/json' `echo "https://review.lineageos.org/changes/?q="${query} | sed "s/ /+/g"`| tail -n +2 | jq -r '.[]._number')
     debug $change_list
     for item in ${change_list[*]}
     do
        if [ $(contains "${ARRAY[@]}" "$item") == "y" ]; then
         debug "Skipping change $item - already fetched it's sub entries or it is excluded"
        else
         debug $item
         if [ $fetchSubmittedTogether == "y"  ]; then
              submitted_together=$(querySubmittedTogether $item)
              debug "Org:" $submitted_together
              submitted_together_rev=$(reverse "$submitted_together")
              debug "Rev:" $submitted_together_rev
              for subItem in ${submitted_together_rev[*]}
              do
                   applyRepopick $subItem
             done
         fi
         applyRepopick $item
        fi
     done
}
export -f queryGerrit

function queryGerrit2(){
while [[ "$#" > 0 ]]; do case $1 in
  -f|--fetchSubmittedTogether) fetchSubmittedTogether="$2"; shift;;
  -q|--query)     query="$2"; shift;;
  -e|--exclude)   excludedChanges="$2"; shift;;
  -o|--options)   repopickOptions="$2"; shift;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

     exclude "$excludedChanges"
     echo "Perform query $query"
     change_list=$(curl -s -H 'Accept-Type: application/json' `echo "https://review.lineageos.org/changes/?q="${query} | sed "s/ /+/g"`| tail -n +2 | jq -r '.[]._number')
     debug $change_list
     for item in ${change_list[*]}
     do
        if [ $(contains "${ARRAY[@]}" "$item") == "y" ]; then
         debug "Skipping change $item - already fetched it's sub entries or it is excluded"
        else
         debug $item
         if [ $fetchSubmittedTogether == "y"  ]; then
              submitted_together=$(querySubmittedTogether $item)
              debug "Org:" $submitted_together
              submitted_together_rev=$(reverse "$submitted_together")
              debug "Rev:" $submitted_together_rev
              for subItem in ${submitted_together_rev[*]}
              do
                   applyRepopick $subItem "$repopickOptions"
             done
         fi
         applyRepopick $item "$repopickOptions"
        fi
     done
}
export -f queryGerrit


function excludeQueryGerrit(){
     query=$1
     echo "Perform query $query"
     change_list=$(curl -s -H 'Accept-Type: application/json' `echo "https://review.lineageos.org/changes/?q="${query} | sed "s/ /+/g"`| tail -n +2 | jq -r '.[]._number')
     debug $change_list
     for item in ${change_list[*]}
     do
         exclude $item
     done
}
export -f excludeQueryGerrit


function performCleanup()
{
  # Import exluded projects array
  _get_excluded_projects_from_cleanup

  cd ${BUILD_PWD}
  repo="$1"
  echo -n ${repo}
  echo -n " "
  if [ $(contains "${EXCLUDED_PROJECTS_FROM_CLEANUP[@]}" "$1") == "y" ]; then
    echo "Skipping"
  else
    echo "Clean up now"
    git -C ${repo} reset --hard m/lineage-16.0 ||
        repo sync --force-sync --detach ${repo}
    #git -C ${repo} checkout lineage-16.0
    #git -C ${repo} reset --hard github/lineage-16.0
  fi
}
export -f performCleanup

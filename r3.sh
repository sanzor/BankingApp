
release_name=${3:- "ex_banking"}
node="'${1:-"c"}@127.0.0.1'"
port=${2:-8300}
release_name=${3:- "ex_banking"}
folder=${4:- "./prod2/ex_banking/bin/ex_banking"}
echo "Using node: $node on port: $port for release: $release_name"
rebar3 as prod3 release -o prod3
echo "Node name passing is:\n"
echo "${node}"
echo "${port}"
RELX_REPLACE_OS_VARS=true NODE_NAME=${node}  PORT=${port} $folder console
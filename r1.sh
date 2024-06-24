
release_name=${3:- "ex_banking"}
node="'${1:-"a"}@127.0.0.1'"
port=${2:-8300}
release_name=${3:- "ex_banking"}
folder=${4:- "./prod1/ex_banking/bin/ex_banking"}
echo "Using node: $node on port: $port for release: $release_name"
rebar3 as prod1 release -o prod1
echo "Node name passing is:"
echo "${node}"
echo "${port}"
RELX_REPLACE_OS_VARS=true NODE_NAME=${node}  PORT=${port} $folder console 

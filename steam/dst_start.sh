#!/bin/bash

cluster_name=${1:-"DSTServer"}
steam_dir=${2:-"/home/steam"}
steam_app=${3:-"dst"}
install_dir=${3:-"${steam_dir}/${steam_app}/"}
dontstarve_dir="${steam_dir}/.klei/DoNotStarveTogether"

if [ ! -d "$steam_dir" ]; then
	echo "Error: Missing $steam_dir directory!"
	exit 1
fi

cd "$steam_dir"

bash ${steam_dir}/steamcmd/steamcmd.sh +force_install_dir "$install_dir" +login anonymous +app_update 343050 validate +quit


if [[ -d "$install_dir/bin64" && -e "$steam_dir/files/dedicated_server_mods_setup.lua" ]]; then
        cp "$steam_dir/files/dedicated_server_mods_setup.lua" "$install_dir/mods/"
fi

run_shared=(./dontstarve_dedicated_server_nullrenderer_x64)
run_shared+=(-console)
run_shared+=(-cluster "$cluster_name")
run_shared+=(-monitor_parent_process $$)

"${run_shared[@]}" -shard Caves  | sed 's/^/Caves:  /' &
"${run_shared[@]}" -shard Master | sed 's/^/Master: /'
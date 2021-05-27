#!/usr/bin/with-contenv bash

# Copyright 2021 Cortex Labs, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# CORTEX_VERSION
# export EXPECTED_CORTEX_VERSION=master

# if [ "$CORTEX_VERSION" != "$EXPECTED_CORTEX_VERSION" ]; then
#     echo "error: your Cortex operator version ($CORTEX_VERSION) doesn't match your handler image version ($EXPECTED_CORTEX_VERSION); please update your handler image by modifying the \`image\` field in your API configuration file (e.g. cortex.yaml) and re-running \`cortex deploy\`, or update your cluster by following the instructions at https://docs.cortex.dev/"
#     exit 1
# fi

export CORTEX_DEBUGGING=${CORTEX_DEBUGGING:-"true"}

eval $(/opt/conda/envs/env/bin/python /src/cortex/serve/init/export_env_vars.py $CORTEX_API_SPEC)

# function substitute_env_vars() {
#     file_to_run_substitution=$1
#     /opt/conda/envs/env/bin/python -c "from cortex_internal.lib import util; import os; util.expand_environment_vars_on_file('$file_to_run_substitution')"
# }

# # configure log level for python scripts§
# substitute_env_vars $CORTEX_LOG_CONFIG_FILE

mkdir -p /mnt/workspace
mkdir -p /mnt/requests

cd /mnt/project

# if the container restarted, ensure that it is not perceived as ready
rm -rf /mnt/workspace/api_readiness.txt
rm -rf /mnt/workspace/init_script_run.txt
rm -rf /mnt/workspace/proc-*-ready.txt

# if [ "$CORTEX_KIND" == "RealtimeAPI" ]; then
#     sysctl -w net.core.somaxconn="65535" >/dev/null
#     sysctl -w net.ipv4.ip_local_port_range="15000 64000" >/dev/null
#     sysctl -w net.ipv4.tcp_fin_timeout=30 >/dev/null
# fi
# 添加local 启动方案
if [ "$CORTEX_PROVIDER" != "local" ]; then
    if [ "$CORTEX_KIND" == "RealtimeAPI" ]; then
        sysctl -w net.core.somaxconn="65535" >/dev/null
        sysctl -w net.ipv4.ip_local_port_range="15000 64000" >/dev/null
        sysctl -w net.ipv4.tcp_fin_timeout=30 >/dev/null
    fi
fi

# to export user-specified environment files
source_env_file_cmd="if [ -f \"/mnt/project/.env\" ]; then set -a; source /mnt/project/.env; set +a; fi"

function install_deps() {
    eval $source_env_file_cmd

    # execute script if present in project's directory
    if [ -f "/mnt/project/${CORTEX_DEPENDENCIES_SHELL}" ]; then
        bash -e "/mnt/project/${CORTEX_DEPENDENCIES_SHELL}"
    fi

    # install from conda-packages.txt
    if [ -f "/mnt/project/${CORTEX_DEPENDENCIES_CONDA}" ]; then
        # look for packages in defaults and then conda-forge to improve chances of finding the package (specifically for python reinstalls)
        conda config --append channels conda-forge
        conda install -y --file "/mnt/project/${CORTEX_DEPENDENCIES_CONDA}"
    fi

    # install pip packages
    if [ -f "/mnt/project/${CORTEX_DEPENDENCIES_PIP}" ]; then
        pip --no-cache-dir install -r "/mnt/project/${CORTEX_DEPENDENCIES_PIP}"
    fi

    # install core cortex dependencies if required
    /usr/local/cortex/install-core-dependencies.sh
}

# install user dependencies
if [ "$CORTEX_LOG_LEVEL" = "DEBUG" ] || [ "$CORTEX_LOG_LEVEL" = "INFO" ]; then
    install_deps
# if log level is set to warning/error
else
    # buffer install_deps stdout/stderr to a file
    tempf=$(mktemp)
    set +e
    (
        set -e
        install_deps
    ) > $tempf 2>&1
    set -e

    # if there was an error while running install_deps
    # print the stdout/stderr and exit
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        cat $tempf
        exit $exit_code
    fi
    rm $tempf
fi

# only terminate pod if this process exits with non-zero exit code
# create_s6_service() {
#     export SERVICE_NAME=$1
#     export COMMAND_TO_RUN=$2

#     dest_dir="/etc/services.d/$SERVICE_NAME"
#     mkdir $dest_dir

#     dest_script="$dest_dir/run"
#     cp /src/cortex/serve/init/templates/run $dest_script
#     substitute_env_vars $dest_script
#     chmod +x $dest_script

#     dest_script="$dest_dir/finish"
#     cp /src/cortex/serve/init/templates/finish $dest_script
#     substitute_env_vars $dest_script
#     chmod +x $dest_script

#     unset SERVICE_NAME
#     unset COMMAND_TO_RUN
# }
create_s6_service() {
    service_name=$1
    cmd=$2

    dest_dir="/etc/services.d/$service_name"
    mkdir $dest_dir

    dest_script="$dest_dir/run"
    echo "#!/usr/bin/with-contenv bash" > $dest_script
    echo $cmd >> $dest_script
    chmod +x $dest_script

    dest_script="$dest_dir/finish"
    echo "#!/usr/bin/execlineb -S0" > $dest_script
    echo "ifelse { s6-test \${1} -ne 0 } { foreground { redirfd -w 1 /var/run/s6/env-stage3/S6_STAGE2_EXITED s6-echo -n -- \${1} } s6-svscanctl -t /var/run/s6/services }" >> $dest_script
    echo "s6-svc -O /var/run/s6/services/$service_name" >> $dest_script
    chmod +x $dest_script
}



# # only terminate pod if this process exits with non-zero exit code
# create_s6_service_from_file() {
#     export SERVICE_NAME=$1
#     runnable=$2

#     dest_dir="/etc/services.d/$SERVICE_NAME"
#     mkdir $dest_dir

#     cp $runnable $dest_dir/run
#     chmod +x $dest_dir/run

#     dest_script="$dest_dir/finish"
#     cp /src/cortex/serve/init/templates/finish $dest_script
#     substitute_env_vars $dest_script
#     chmod +x $dest_script

#     unset SERVICE_NAME
# }

# prepare webserver
if [ "$CORTEX_KIND" = "RealtimeAPI" ]; then
    # if [ $CORTEX_SERVING_PROTOCOL = "http" ]; then
    #     mkdir /run/servers
    # fi

    # if [ $CORTEX_SERVING_PROTOCOL = "grpc" ]; then
    #     /opt/conda/envs/env/bin/python -m grpc_tools.protoc --proto_path=$CORTEX_PROJECT_DIR --python_out=$CORTEX_PYTHON_PATH --grpc_python_out=$CORTEX_PYTHON_PATH $CORTEX_PROTOBUF_FILE
    # fi

    # prepare servers
    # for i in $(seq 1 $CORTEX_PROCESSES_PER_REPLICA); do
    #     # prepare uvicorn workers
    #     if [ $CORTEX_SERVING_PROTOCOL = "http" ]; then
    #         create_s6_service "uvicorn-$((i-1))" "cd /mnt/project && $source_env_file_cmd && PYTHONUNBUFFERED=TRUE PYTHONPATH=$PYTHONPATH:$CORTEX_PYTHON_PATH exec /opt/conda/envs/env/bin/python /src/cortex/serve/start/server.py /run/servers/proc-$((i-1)).sock"
    #     fi

    #     # prepare grpc workers
    #     if [ $CORTEX_SERVING_PROTOCOL = "grpc" ]; then
    #         create_s6_service "grpc-$((i-1))" "cd /mnt/project && $source_env_file_cmd && PYTHONUNBUFFERED=TRUE PYTHONPATH=$PYTHONPATH:$CORTEX_PYTHON_PATH exec /opt/conda/envs/env/bin/python /src/cortex/serve/start/server_grpc.py localhost:$((i-1+20000))"
    #     fi
    # done
    mkdir /run/uvicorn
    for i in $(seq 1 $CORTEX_PROCESSES_PER_REPLICA); do
        echo "starting uvicorn..."
        echo "uvicorn-$((i-1))" "cd /mnt/project && $source_env_file_cmd && exec env PYTHONUNBUFFERED=TRUE env PYTHONPATH=$PYTHONPATH:$CORTEX_PYTHON_PATH /opt/conda/envs/env/bin/python /src/cortex/serve/start/server.py /run/uvicorn/proc-$((i-1)).sock"
        create_s6_service "uvicorn-$((i-1))" "cd /mnt/project && $source_env_file_cmd && exec env PYTHONUNBUFFERED=TRUE env PYTHONPATH=$PYTHONPATH:$CORTEX_PYTHON_PATH /opt/conda/envs/env/bin/python /src/cortex/serve/start/server.py /run/uvicorn/proc-$((i-1)).sock"
    done


    # generate nginx conf
    echo "generate nginx conf"
    /opt/conda/envs/env/bin/python -c 'from cortex_internal.lib import util; import os; generated = util.render_jinja_template("/src/cortex/serve/nginx.conf.j2", os.environ); print(generated);' > /run/nginx.conf

    create_s6_service "py_init" "cd /mnt/project && exec /opt/conda/envs/env/bin/python /src/cortex/serve/init/script.py"
    echo "start nginx"
    create_s6_service "nginx" "exec nginx -c /run/nginx.conf"
    # create_s6_service_from_file "api_readiness" "/src/cortex/serve/poll/readiness.sh"

elif [ "$CORTEX_KIND" = "BatchAPI" ]; then
    start_cmd="/opt/conda/envs/env/bin/python /src/cortex/serve/start/batch.py"
    if [ -f "/mnt/kubexit" ]; then
      start_cmd="/mnt/kubexit ${start_cmd}"
    fi

    create_s6_service "py_init" "cd /mnt/project && exec /opt/conda/envs/env/bin/python /src/cortex/serve/init/script.py"
    create_s6_service "batch" "cd /mnt/project && $source_env_file_cmd && PYTHONUNBUFFERED=TRUE PYTHONPATH=$PYTHONPATH:$CORTEX_PYTHON_PATH exec ${start_cmd}"
elif [ "$CORTEX_KIND" = "AsyncAPI" ]; then
    create_s6_service "py_init" "cd /mnt/project && exec /opt/conda/envs/env/bin/python /src/cortex/serve/init/script.py"
    create_s6_service "async" "cd /mnt/project && $source_env_file_cmd && PYTHONUNBUFFERED=TRUE PYTHONPATH=$PYTHONPATH:$CORTEX_PYTHON_PATH exec /opt/conda/envs/env/bin/python /src/cortex/serve/start/async_api.py"
elif [ "$CORTEX_KIND" = "TaskAPI" ]; then
    start_cmd="/opt/conda/envs/env/bin/python /src/cortex/serve/start/task.py"
    if [ -f "/mnt/kubexit" ]; then
      start_cmd="/mnt/kubexit ${start_cmd}"
    fi

    create_s6_service "task" "cd /mnt/project && $source_env_file_cmd && PYTHONUNBUFFERED=TRUE PYTHONPATH=$PYTHONPATH:$CORTEX_PYTHON_PATH exec ${start_cmd}"
fi

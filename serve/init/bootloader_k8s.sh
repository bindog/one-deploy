#!/usr/bin/with-contenv bash

set -e

export CORTEX_DEBUGGING=${CORTEX_DEBUGGING:-"true"}

mkdir -p /mnt/workspace
mkdir -p /mnt/requests

eval $(/opt/conda/envs/env/bin/python /src/gen_json_file.py)
eval $(/opt/conda/envs/env/bin/python /src/cortex/serve/init/export_env_vars.py $CORTEX_API_SPEC)

cd /mnt/project

# k8s change parameters
# https://bbotte.github.io/service_config/adjust-the-kernel-parameters-of-the-pod-on-kubernetes.html
# sysctl -w net.core.somaxconn="65535" >/dev/null
# sysctl -w net.ipv4.ip_local_port_range="15000 64000" >/dev/null
# sysctl -w net.ipv4.tcp_fin_timeout=30 >/dev/null

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

# start server
cd /src/cortex/serve && PYTHONUNBUFFERED=TRUE uvicorn cortex_internal.serve.wsgi:app --host 0.0.0.0 --port $CORTEX_SERVING_PORT

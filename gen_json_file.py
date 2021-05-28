import json
from pydantic import BaseModel
from typing import Optional
import os


class ServerSideBatchingModel(BaseModel):
    max_batch_size: int
    batch_interval: int

class DependenciesModel(BaseModel):
    pip: str
    conda: str
    shell: str

class HandleModel(BaseModel):
    type: str
    path: str
    multi_model_reloading: Optional[str]
    models: Optional[str]
    processes_per_replica: Optional[int]
    threads_per_process: Optional[int]
    server_side_batching: ServerSideBatchingModel
    dependencies: DependenciesModel
    tensorflow_serving_image: str = ""
    log_level: str = "info"

class ComputeModel(BaseModel):
    cpu: Optional[int]
    mem: Optional[int]
    gpu: int
    local_gpus: str
    inf: int

class SpecModel(BaseModel):
    id: str
    handler_id: str
    deployment_id: str
    name: str
    kind: str
    apis: Optional[str]
    handler: HandleModel
    compute: ComputeModel

def gen_json_file():
    file_path = os.getenv('CORTEX_API_SPEC')
    data = {
    "id": "9527",
    "handler_id": "handler_9527",
    "deployment_id": "deployment_9527",
    "name": os.getenv('SERVICE_NAME'),
    "kind": os.getenv('CORTEX_KIND'),
    "apis": None,
    "handler": {
        "type": os.getenv('CORTEX_TYPE'),
        "path": os.getenv('CORTEX_PROJECT_DIR'),
        "multi_model_reloading": None,
        "models": None,
        "processes_per_replica": 1,
        "processes_per_replica": 8,
        "server_side_batching": {
            "max_batch_size": os.getenv('CORTEX_MAX_BATCH_SIZE'),
            "batch_interval": os.getenv('CORTEX_BATCH_INTERVAL')
        },
        "dependencies": {
            "pip": os.getenv('CORTEX_DEPENDENCIES_PIP'),
            "conda": os.getenv('CORTEX_DEPENDENCIES_CONDA'),
            "shell": os.getenv('CORTEX_DEPENDENCIES_SHELL')
        },
        "tensorflow_serving_image": "",
        "log_level": "info"
    },
    "compute": {
        "cpu": os.getenv('CORTEX_COMPUTE_CPU'),
        "mem": os.getenv('CORTEX_COMPUTE_MEM'),
        "gpu": os.getenv('CORTEX_COMPUTE_GPU'),
        # TODO fix this
        "local_gpus": "0",
        "inf": 0
        }
    }
    with open(file_path, 'w') as f:
        f.write(SpecModel(**data).json())

if __name__ == "__main__":
    gen_json_file()

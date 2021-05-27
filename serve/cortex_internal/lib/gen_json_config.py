import json
from pydantic import BaseModel
from typing import Optional
import os
from logging import getLogger, log

logger = getLogger('cortex')

class ServerSideBatchingModel(BaseModel):
    max_batch_size: int
    batch_interval: int

class HandleModel(BaseModel):
    type: str
    path: str
    multi_model_reloading: Optional[str]
    models: Optional[str]
    server_side_batching: ServerSideBatchingModel
    tensorflow_serving_image: str = ""

class ComputeModel(BaseModel):
    cpu: Optional[int]
    mem: Optional[int]
    gpu: int
    local_gpus: str
    inf: int

class SpecModel(BaseModel):
    name: str
    kind: str
    apis: Optional[str]
    handler: HandleModel
    compute: ComputeModel

def gen_json_file():
    file_path = os.getenv('CORTEX_API_SPEC')
    data = {
    "name": os.getenv('SERVICE_NAME'),
    "kind": os.getenv('CORTEX_KIND'),
    "apis": None,
    "handler": {
        "type": os.getenv('CORTEX_TYPE'),
        "path": os.getenv('CORTEX_PROJECT_DIR'),
        "multi_model_reloading": None,
        "models": None,
        "server_side_batching": {
            "max_batch_size": os.getenv('CORTEX_MAX_BATCH_SIZE'),
            "batch_interval": os.getenv('CORTEX_BATCH_INTERVAL')
        },
        "tensorflow_serving_image": ""
    },
    "compute": {
        "cpu": os.getenv('CORTEX_COMPUTE_CPU'),
        "mem": os.getenv('CORTEX_COMPUTE_MEM'),
        "gpu": os.getenv('CORTEX_COMPUTE_GPU'),
        "local_gpus": "0",
        "inf": 0
        }
    }
    with open(file_path, 'w') as f:
        logger.info('generate spec json file')
        f.write(SpecModel(**data).json())


import json
from jinja2 import Template
import argparse


def RenderTemplate(tmpl_path, namespace, name, model_name, image, gpu, gpu_mem, replicas=1):
    with open(tmpl_path, "r") as f:
        yml_render = Template(f.read()).render(namespace=namespace, name=name, model_name=model_name, image=image, gpu=gpu, gpu_mem=gpu_mem, replicas=replicas)
        print(yml_render)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="k8s jinja template")
    parser.add_argument("--template", type=str, default="./nlp-deploy/nlp-base.yaml.tmpl")
    parser.add_argument("--render", type=str, required=True)
    args = parser.parse_args()

    with open(args.render, "r") as f:
        obj = json.loads(f.read())
        namespace = obj["namespace"]
        name = obj["name"]
        model_name = obj["model_name"]
        image = obj["image"]
        gpu = obj["gpu"]
        gpu_mem = obj["gpu_mem"]
        replicas = obj["replicas"]

    RenderTemplate(args.template, namespace, name, model_name, image, gpu, gpu_mem, replicas)

import torch
from transformers import MBartForConditionalGeneration, MBartTokenizer

class Handler:
    def __init__(self, config):
        model_path = config.get("model_path", "/mnt/project/models")
        device = config.get("device", 0)  # default on gpu 0
        self.tokenizer = MBartTokenizer.from_pretrained(model_path)
        self.model = MBartForConditionalGeneration.from_pretrained(model_path)
        self.model.eval()
        self.model.half()
        self.device = torch.device("cpu" if device < 0 else "cuda:{}".format(device))
        if self.device.type == "cuda":
            self.model = self.model.to(self.device)

    def ensure_tensor_on_device(self, **inputs):
        return {name: tensor.to(self.device) for name, tensor in inputs.items()}

    def handle_post(self, query_params, payload):
        text = [p["data"] for p in payload]
        encoded_inputs = self.tokenizer(text, padding="max_length", max_length=1024, truncation=True, return_tensors='pt')
        encoded_inputs = self.ensure_tensor_on_device(**encoded_inputs)

        generated_tokens = self.model.generate(
            **encoded_inputs,
            num_beams=4,
            max_length=50,
            early_stopping=True
        )
        output = self.tokenizer.batch_decode(generated_tokens, skip_special_tokens=True, clean_up_tokenization_spaces=False)

        results = []
        for s in output:
            result_dict = {
                "status": 200,
                "result": s
            }
            results.append(result_dict)
        return results

    def handle_get(self, query_params):
        return "API alive"

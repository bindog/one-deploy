import torch
from transformers import MBartForConditionalGeneration, MBart50TokenizerFast


class PythonPredictor:
    def __init__(self, config):
        model_name = config.get("model_name", None)
        model_path = config.get("model_path", None)
        device = config.get("device", 0)  # default on gpu 0
        self.tokenizer = MBart50TokenizerFast.from_pretrained(model_path)
        self.model = MBartForConditionalGeneration.from_pretrained(model_path)
        self.model.eval()
        self.model.half()
        self.device = torch.device("cpu" if device < 0 else "cuda:{}".format(device))
        if self.device.type == "cuda":
            self.model = self.model.to(self.device)

    def ensure_tensor_on_device(self, **inputs):
        return {name: tensor.to(self.device) for name, tensor in inputs.items()}

    def predict(self, query_params, payload):
        # TODO: support multi lang batch
        text = payload["data"]
        src_lang = payload["src_lang"]
        tgt_lang = payload["tgt_lang"]
        self.tokenizer.src_lang = src_lang
        encoded_inputs = self.tokenizer(text, return_tensors="pt")
        encoded_inputs = self.ensure_tensor_on_device(**encoded_inputs)
        generated_tokens = self.model.generate(
            **encoded_inputs,
            forced_bos_token_id=self.tokenizer.lang_code_to_id[tgt_lang]
        )
        output = self.tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)
        return {
            "status": 200,
            "result": output[0]
        }

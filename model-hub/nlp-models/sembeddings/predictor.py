import torch
from transformers import XLMRobertaTokenizer, XLMRobertaModel

# Mean Pooling - Take attention mask into account for correct averaging
def mean_pooling(model_output, attention_mask):
    token_embeddings = model_output[0]  # First element of model_output contains all token embeddings
    input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
    sum_embeddings = torch.sum(token_embeddings * input_mask_expanded, 1)
    sum_mask = torch.clamp(input_mask_expanded.sum(1), min=1e-9)
    return sum_embeddings / sum_mask

class Handler:
    def __init__(self, config):
        model_path = config.get("model_path", "/mnt/project/models")
        device = config.get("device", 0)  # default on gpu 0
        self.tokenizer = XLMRobertaTokenizer.from_pretrained(model_path)
        self.model = XLMRobertaModel.from_pretrained(model_path)
        self.device = torch.device("cpu" if device < 0 else "cuda:{}".format(device))
        self.model.cuda()
        self.model.eval()
        self.model.half()

    def ensure_tensor_on_device(self, **inputs):
        return {name: tensor.to(self.device) for name, tensor in inputs.items()}

    def handle_post(self, query_params, payload):
        inputs = [p["data"] for p in payload]
        encoded_input = self.tokenizer(inputs, padding=True, truncation=True, max_length=128, return_tensors='pt')
        with torch.no_grad():
            encoded_input = self.ensure_tensor_on_device(**encoded_input)
            model_output = self.model(**encoded_input)
        sentence_embeddings = mean_pooling(model_output, encoded_input['attention_mask'])
        results = []
        for se in sentence_embeddings:
            result_dict = {
                "status": 200,
                "results": se.cpu().numpy().tolist()
            }
            results.append(result_dict)
        return results

    def handle_get(self, query_params):
        return "API alive"

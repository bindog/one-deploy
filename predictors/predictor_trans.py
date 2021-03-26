import sys
from transformers import MarianMTModel, MarianTokenizer


class PythonPredictor:
    def __init__(self, config):
        model_name = config.get("model_name", None)
        self.tokenizer = MarianTokenizer.from_pretrained(model_name)
        self.model = MarianMTModel.from_pretrained(model_name)
        self.model.eval()
        self.model.half()
        self.model.cuda()

    def predict(self, query_params, payload):
        input_list = [p["data"] for p in payload]
        inputs = self.tokenizer(input_list, padding="max_length", max_length=512, truncation=True, return_tensors='pt')
        outputs = self.model.generate(
                                inputs.input_ids.cuda(),
                                num_beams=4,
                                max_length=512,
                                early_stopping=True
                            )
        results = []
        for output in outputs:
            trans_text = self.tokenizer.decode(
                                        output,
                                        skip_special_tokens=True,
                                        clean_up_tokenization_spaces=False
                                    )
            result_dict = {
                "status": 200,
                "result": trans_text
            }
            results.append(result_dict)
        return results

import sys
from LAC import LAC


class PythonPredictor:
    def __init__(self, config):
        use_cuda_flag = config.get("use_cuda", False)
        self.model = LAC(mode='lac', use_cuda=use_cuda_flag)

    def predict(self, query_params, payload):
        input_list = [p["text"] for p in payload]
        result_list = self.model.run(input_list)
        final_result = []
        for i, result in enumerate(result_list):
            for word, wtype in zip(result[0], result[1]):
                if wtype in ["PER", "LOC", "ORG", "TIME"]:
                    final_result.append((word, wtype))
        return final_result

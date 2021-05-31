import sys
from LAC import LAC
from stopwordsiso import stopwords


class Handler:
    def __init__(self, config):
        self.all_stopwords = stopwords(["en", "zh"])
        use_cuda_flag = config.get("use_cuda", False)
        self.model = LAC(mode='seg', use_cuda=use_cuda_flag)

    def handle_post(self, query_params, payload):
        input_list = [p["data"] for p in payload]
        result_list = self.model.run(input_list)
        final_result = []
        for i, result in enumerate(result_list):
            clean_flag = query_params[i].get("clean", False)
            if clean_flag:
                clean_result = [w for w in result if w not in self.all_stopwords]
                final_result.append(clean_result)
            else:
                final_result.append(result)
        return final_result

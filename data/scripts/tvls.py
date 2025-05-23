import os
import requests
import json
from datetime import datetime

API_KEY = os.environ["DUNE_API_KEY"]
HEADERS = {"x-dune-api-key": API_KEY}
QUERIES = {
    "ocv1": {
        "query_id": 3196716,
        "tvl_field_key": "total_deposited_value"
    },
    "ocv2": {
        "query_id": 2811723,
        "tvl_field_key": "totalUnderlyingSupplyValue"
    },
    "defi": {
        "query_id": 3841112,
        "tvl_field_key": "_col0"
    }
}

def get_cached_results(query_id):
    res = requests.get(
        f"https://api.dune.com/api/v1/query/{query_id}/results",
        headers=HEADERS
    )
    res.raise_for_status()
    data = res.json()
    return data["result"]["rows"], data["execution_ended_at"]

def main():
    timestamp = datetime.utcnow().isoformat()
    tvl = {
        "data": {}
    }

    for name, query in QUERIES.items():
        print(f"[*] fetching cached result: {name}")
        results, timestamp = get_cached_results(query["query_id"])
        print(f"[+] {name} tvl: {results[0][query['tvl_field_key']]}")
        tvl["data"][name] = {
            "tvl": results[0][query["tvl_field_key"]],
            "timestamp": timestamp
        }

    os.makedirs("data", exist_ok=True)
    print(f"[*] writing to data/tvl.json")
    with open("data/tvl.json", "w") as f:
        json.dump(tvl, f, indent=2)

if __name__ == "__main__":
    main()

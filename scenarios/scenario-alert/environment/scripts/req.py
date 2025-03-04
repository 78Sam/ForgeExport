import requests
from random import choice, randint, random
from time import sleep

alpha = "abcdefghijklmnopqrstuvwxyz"

URL = "http://172.18.0.2"
path = [
    "/",
    "/?p=1",
    "/wp-admin",
    "/" + "".join([choice(alpha) for _ in range(randint(1, 12))]),
    "/?page_id=29"
]

for _ in range(randint(2, 10)):
    to_get = f"{URL}{choice(path)}"
    try:
        resp = requests.get(url=to_get, timeout=5)
    except Exception as e:
        print(f"\nRequest failed for URL {to_get}\n")
    sleep(2+randint(0, 2)+random())
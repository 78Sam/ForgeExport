import os


def genCLI(
        items_in: list,
        display: int = 10,
        controls: dict = {"next": "n", "previous": "p", "quit": -1},
        message: str = ""
    ) -> tuple[int, str]:

    items = [x for x in items_in]

    page = 0
    max_index = len(items)

    if display == -1:
        max_index = len(items)
        display = len(items)

    nxt, prev = "", ""
    if max_index > display:
        nxt = f"({controls['next']})->"
        prev = f"<-({controls['previous']})"

    blocks = []
    x = 0
    while items != []:
        blocks.append([])
        for _ in range(0, min(display, len(items))):
            blocks[-1].append(f"{x}: {items.pop(0)}")
            x += 1

    choices = {controls["next"], controls["previous"], controls["quit"], *range(max_index)}

    choice = ""
    while choice not in choices:
        os.system("clear")

        print(message)
        print(f"{controls['quit']}: QUIT")
        if max_index > display:
            print(f"{prev} {page+1}/{len(blocks)} {nxt}")

        for item in blocks[page]:
            print(f"{item}")

        choice = input("").lower()

        if choice == controls["next"]:
            page = min(len(blocks)-1, page+1)
            choice = ""
        elif choice == controls["previous"]:
            page = max(0, page-1)
            choice = ""
        else:
            try:
                choice = int(choice)
            except ValueError:
                choice = ""

    os.system("clear")

    if choice != -1:
        selected = blocks[choice//display][choice % display]
        return (choice, selected[selected.index(":")+2:])
    else:
        return (-1, "QUIT")

if __name__ == "__main__":
    print(genCLI(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"], message="pick"))
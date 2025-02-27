import os


def main() -> None:
    file_name = input("Enter the name of the new capture: ")
    root_dir = os.path.dirname(os.path.dirname(__file__))
    # dir_path = f"{root_dir}/captures/capture-{file_name}"
    dir_path = f"{root_dir}/scenarios/scenario-{file_name}"
    
    try:
        os.makedirs(dir_path, exist_ok=False)
    except OSError:
        print("Capture name already taken")
        main()
        return
    except Exception as E:
        print(f"Something weird happened... {E}")
        return
    
    schematics_path = f"{os.path.dirname(__file__)}/schemas"
    
    capture_code = ""
    with open(f"{schematics_path}/schema-capture.py") as capture_schema:
        capture_code = capture_schema.read()
    
    with open(f"{dir_path}/capture.py", "w") as capture_file:
        capture_file.write(capture_code)

    schema_code = ""
    with open(f"{schematics_path}/schema-schema-json.json") as schema_schema:
        schema_code = schema_schema.read()
    
    with open(f"{dir_path}/schema.json", "w") as schema_file:
        schema_file.write(schema_code)

    return



if __name__ == "__main__":
    main()
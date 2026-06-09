import os


# --- CONFIG ---

ROOT_DIR = "."  # change if needed

OUTPUT_FILE = "llm_consolidated.txt"


EXCLUDE_DIRS = {

    ".git", "__pycache__", ".venv", "venv", "node_modules",

    ".idea", ".vscode", "dist", "build"

}


EXCLUDE_FILES = {

    OUTPUT_FILE

}


# --- HELPERS ---


def is_text_file(filepath):

    try:

        with open(filepath, "r", encoding="utf-8") as f:

            f.read(1024)

        return True

    except:

        return False



def detect_language(filename):

    ext = filename.lower().split(".")[-1]


    if ext in ["py"]:

        return "python"

    elif ext in ["yml", "yaml"]:

        return "yaml"

    elif ext in ["sh"]:

        return "bash"

    elif ext in ["json"]:

        return "json"

    elif ext in ["md"]:

        return "markdown"

    else:

        return "text"



def detect_role(path):

    path_lower = path.lower()


    if "roles/" in path_lower and "tasks" in path_lower:

        return "ansible-task"

    elif "roles/" in path_lower and "handlers" in path_lower:

        return "ansible-handler"

    elif "roles/" in path_lower and "defaults" in path_lower:

        return "ansible-default"

    elif "roles/" in path_lower:

        return "ansible-role"

    elif path_lower.endswith(".py"):

        return "simulation-core"

    elif path_lower.endswith((".yml", ".yaml")):

        return "config"

    else:

        return "general"



# --- MAIN LOGIC ---


def consolidate_repo(root_dir, output_file):

    with open(output_file, "w", encoding="utf-8") as outfile:


        # Repo header (lightweight but useful)

        outfile.write("### REPO: Threat Simulator\n")

        outfile.write("### DESCRIPTION: Ansible-driven adversarial simulation\n\n")


        for dirpath, dirnames, filenames in os.walk(root_dir):


            # Remove excluded directories in-place (important!)

            dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]


            for filename in filenames:

                if filename in EXCLUDE_FILES:

                    continue


                full_path = os.path.join(dirpath, filename)


                if not is_text_file(full_path):

                    continue


                rel_path = os.path.relpath(full_path, root_dir)

                lang = detect_language(filename)

                role = detect_role(rel_path)


                try:

                    with open(full_path, "r", encoding="utf-8") as infile:

                        content = infile.read().strip()


                    if not content:

                        continue


                    # Write structured block

                    outfile.write(f"### FILE: {rel_path}\n")

                    outfile.write(f"### LANG: {lang}\n")

                    outfile.write(f"### ROLE: {role}\n\n")

                    outfile.write("<CONTENT>\n")

                    outfile.write(content)

                    outfile.write("\n</CONTENT>\n\n\n")


                except Exception as e:

                    print(f"Skipping {rel_path}: {e}")


    print(f"\n✅ Done. Output written to: {output_file}")



# --- RUN ---


if __name__ == "__main__":

    consolidate_repo(ROOT_DIR, OUTPUT_FILE)

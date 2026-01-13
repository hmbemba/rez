code commands.xsh

'''
# Update new_nimble_pkg

cp "./commands.xsh" r"C:\Users\hmbem\Desktop\Scripts\bp\blueprints\new_nimble_pkg\commands.xsh"

'''

import subprocess

def _push(args, stdin=None):
    if not args:
        print("Usage: push <commit message>")
        return 1

    commit_msg = " ".join(args).strip()

    # Stage everything
    subprocess.check_call(["git", "add", "."])

    # If nothing is staged, don't try to commit
    diff = subprocess.run(
        ["git", "diff", "--cached", "--quiet"],
        check=False
    )
    if diff.returncode == 0:
        print("Nothing to commit (working tree clean after git add).")
        return 0

    # Commit + push
    subprocess.check_call(["git", "commit", "-m", commit_msg])
    subprocess.check_call(["git", "push"])
    return 0

aliases["push"] = _push

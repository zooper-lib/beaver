"""Prints the first ```<lang> block of a docs page: the configuration the
editor CI job runs is exactly the documented one."""
import re
import sys

path, lang = sys.argv[1], sys.argv[2]
match = re.search(r"```" + lang + r"\n(.*?)```", open(path).read(), re.S)
if not match:
    sys.exit(f"no {lang} block in {path}")
sys.stdout.write(match.group(1))

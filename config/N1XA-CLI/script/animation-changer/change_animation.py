#!/usr/bin/env python3

import sys
import os
def change_animation(choosed_animation):
    config_path = os.path.expanduser("~/.config/N1XA-CLI/config/animation.conf")

    current_animation = f"$current_animation = {choosed_animation}"

    with open(config_path, "w") as animation_file:
        animation_file.write(current_animation)


if __name__ == "__main__":
    change_animation(choosed_animation=sys.argv[1])
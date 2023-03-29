#!/usr/bin/env python3
# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
# Author: Luca Colagrande <colluca@iis.ee.ethz.ch>

import argparse
from git import Repo


def main():
    parser = argparse.ArgumentParser(
        description='Check for changes in repository')
    parser.add_argument('--error-msg',
                        required=False,
                        help='Custom exit code string')
    args = parser.parse_args()

    # Diff tree against working tree
    repo = Repo(search_parent_directories=True)
    diff_to_head = repo.head.commit.diff(None)

    # Report differences and fail if any
    if len(diff_to_head) > 0:
        for diff in diff_to_head:
            # Custom message for 'M' type changes
            if diff.change_type == 'M':
                print(f"::error::File {diff.b_path} modified")
            # Default message for other changes
            else:
                print(f"::error::Files differ. Change type {diff.change_type}")
        # Print custom message on error if provided
        if args.error_msg:
            print(args.error_msg)
        exit(1)


if __name__ == '__main__':
    main()

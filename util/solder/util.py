# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# From: https://github.com/nficano/humps

import re

PASCAL_RE = re.compile(r"([^\-_\s]+)")
UNDERSCORE_RE = re.compile(r"([^\-_\s])[\-_\s]+([^\-_\s])")


def pascalize(s):
    """Convert a string, dict, or list of dicts to pascal case.
    :param str_or_iter:
      A string or iterable.
    :type str_or_iter: Union[list, dict, str]
    :rtype: Union[list, dict, str]
    :returns:
      pascalized string, dictionary, or list of dictionaries.
    """

    if s.isnumeric():
        return s

    if s.isupper():
        return s

    s = camelize(
        PASCAL_RE.sub(lambda m: m.group(1)[0].upper() + m.group(1)[1:], s), )
    return s[0].upper() + s[1:]


def camelize(s):
    """Convert a string, dict, or list of dicts to camel case.
    :param str_or_iter:
      A string or iterable.
    :type str_or_iter: Union[list, dict, str]
    :rtype: Union[list, dict, str]
    :returns:
      camelized string, dictionary, or list of dictionaries.
    """
    if s.isnumeric():
        return s

    if s.isupper():
        return s

    return "".join([
        s[0].lower() if not s[:2].isupper() else s[0],
        UNDERSCORE_RE.sub(lambda m: m.group(1) + m.group(2).upper(), s[1:]),
    ])


def clog2(x):
    return x.bit_length() - 1

# Copyright 2025 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

import config_util  # pylint: disable=import-error


# This class doesn't need an __init__ method, so we disable the warning
# pylint: disable=no-init
class WebTests(config_util.Config):
    """Basic Config class for web-tests."""

    @staticmethod
    def fetch_spec(props):
        url = 'https://chromium.googlesource.com/chromium/web-tests'
        solution = {
            'name': 'web-tests',
            'url': url,
            'deps_file': 'DEPS',
            'managed': False,
            'custom_deps': {},
        }
        spec = {
            'solutions': [solution],
        }
        return {
            'type': 'gclient_git',
            'gclient_git_spec': spec,
        }

    @staticmethod
    def expected_root(_props):
        return 'web-tests'


def main(argv=None):
    return WebTests().handle_args(argv)


if __name__ == '__main__':
    sys.exit(main(sys.argv))

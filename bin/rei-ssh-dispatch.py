#!/usr/bin/env python3
"""Temporary forced SSH command for Yujin's Rei client on Sungkyung."""
import base64
import binascii
import json
import os
import sys


def decode_argv(command):
    prefix = 'rei-argv:'
    if not command.startswith(prefix):
        raise ValueError('expected encoded Rei arguments')
    try:
        args = json.loads(base64.b64decode(command[len(prefix):], validate=True))
    except (ValueError, binascii.Error, UnicodeError) as exc:
        raise ValueError('invalid encoded Rei arguments') from exc
    if not isinstance(args, list) or not all(isinstance(arg, str) and '\0' not in arg for arg in args):
        raise ValueError('expected a list of Rei arguments')
    return args


def main():
    try:
        args = decode_argv(os.environ.get('SSH_ORIGINAL_COMMAND', ''))
    except ValueError as exc:
        print(f'rei SSH client: {exc}', file=sys.stderr)
        return 2
    # The login shell in authorized_keys supplies Sungkyung's managed PATH and
    # database settings. No user-controlled text is evaluated as shell code.
    os.chdir(os.path.expanduser('~'))
    os.execvp('rei', ['rei', *args])


if __name__ == '__main__':
    sys.exit(main())

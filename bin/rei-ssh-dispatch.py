#!/usr/bin/env python3
"""Forced SSH command that runs the runtime owner's Rei for a client's remote rei.

The client encodes its argv as base64 JSON ("rei-argv:<payload>") so SSH cannot
join the arguments into shell text. This command decodes the list, rejects
anything that is not a list of NUL-free strings, and execs Rei directly with
those arguments: no user-controlled text is evaluated as shell code, argument
boundaries are preserved, and Rei's exit status is SSH's exit status.

The managed wrapper (~/.local/libexec/rei-ssh-dispatch, home/rei.nix) sets
REI_SSH_DISPATCH_REI to the owner's own managed Rei by absolute path, so a
client-side remote `rei` on PATH can never be resolved here. Without that
variable, as in the older authorized_keys entry that runs this file through a
login shell, `rei` comes from PATH.
"""
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


def rei_executable(environ):
    managed = environ.get('REI_SSH_DISPATCH_REI')
    if managed is None:
        return 'rei'
    if not os.path.isabs(managed):
        raise ValueError('REI_SSH_DISPATCH_REI must be an absolute path')
    return managed


def main(environ=os.environ, execv=os.execv, execvp=os.execvp):
    try:
        args = decode_argv(environ.get('SSH_ORIGINAL_COMMAND', ''))
        rei = rei_executable(environ)
    except ValueError as exc:
        print(f'rei SSH client: {exc}', file=sys.stderr)
        return 2
    os.chdir(os.path.expanduser('~'))
    if os.path.isabs(rei):
        execv(rei, ['rei', *args])
    else:
        execvp(rei, ['rei', *args])
    return 127


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""Load private Rei API credentials at process startup, never during Nix evaluation."""
import json
import pathlib
import sys


def credential_entries(path):
    entries = []
    for item in pathlib.Path(path).read_text().strip().split(','):
        token, separator, actor = item.strip().partition('=')
        token, actor = token.strip(), actor.strip()
        if not separator or not token or not actor:
            raise ValueError('invalid Rei API credential mapping')
        entries.append((token.strip(), actor.strip()))
    if len({token for token, _ in entries}) != len(entries):
        raise ValueError('duplicate Rei API credential mapping')
    return entries


def select_token(entries, actor):
    tokens = [token for token, identity in entries if identity == actor]
    if len(tokens) != 1:
        raise ValueError('Rei API credential actor must have exactly one mapping')
    return tokens[0]


def main(arguments):
    mode, path, *rest = arguments
    entries = credential_entries(path)
    if mode == 'token' and len(rest) == 1:
        print(select_token(entries, rest[0]))
    elif mode == 'policies' and not rest:
        print(json.dumps([{
            'token': select_token(entries, 'human'),
            'id': 'workstation-owner', 'revision': '1', 'maxAgeSeconds': 3600,
            'profiles': {name: {'agentId': name, 'principal': None, 'version': None}
                         for name in ['claude-code', 'codex']},
        }]))
    else:
        raise ValueError('invalid Rei API credential helper invocation')


if __name__ == '__main__':
    try:
        main(sys.argv[1:])
    except (ValueError, OSError):
        sys.exit('Rei API credential configuration could not be loaded')

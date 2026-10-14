#!/usr/bin/env python3
"""Check declared runtime ownership; never activates hosts or inspects secrets."""
import argparse
import json
from pathlib import Path
import subprocess

EXPRESSION = '''hosts: builtins.mapAttrs (_: host:
  if host.config ? home-manager then
    let
      user = host.config.home-manager.users.shinzui;
      agents = user.launchd.agents;
      owned = user.workstation.reiMori;
      names = builtins.filter (name:
        builtins.elem name owned.agents ||
        builtins.match "(rei|mori)-.*" name != null
      ) (builtins.attrNames agents);
    in {
      owner = owned.enable;
      enabled = builtins.filter (name: agents.${name}.enable) names;
      watchdogSelfHeal = user.home.activation ? rei-watchdog-ensure-loaded;
    }
  else { owner = false; enabled = []; watchdogSelfHeal = false; }
) hosts'''


def validate(hosts, expected):
    owners = sorted(name for name, host in hosts.items() if host['owner'])
    if len(owners) > 1:
        raise ValueError('multiple runtime owners are declared')
    for name, host in hosts.items():
        if not host['owner'] and (host['enabled'] or host['watchdogSelfHeal']):
            raise ValueError('inactive host can start or heal the runtime: ' + name)
    desired = [] if expected == 'none' else [expected]
    if owners != desired:
        raise ValueError('declared owner differs from --expect ' + expected)
    return owners


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--expect', default='SungkyungM1X', help='expected full-host target, or none during cutover')
    args = parser.parse_args()
    root = Path(__file__).absolute().parent.parent
    result = subprocess.run(['nix', 'eval', '--json', '.#darwinConfigurations', '--apply', EXPRESSION], cwd=root, capture_output=True, text=True)
    if result.returncode:
        parser.exit(1, 'CONFLICT: cannot evaluate declared ownership; build/evaluate the flake to diagnose\n')
    try:
        hosts = json.loads(result.stdout)
        owners = validate(hosts, args.expect)
    except (ValueError, KeyError, TypeError):
        parser.exit(1, 'CONFLICT: runtime ownership or inactive-host guard failed\n')
    print('PASS: declared Rei/Mori runtime owner: ' + (owners[0] if owners else 'none (cutover stopped state)'))
    for name, host in sorted(hosts.items()):
        print(name + ': ' + str(len(host['enabled'])) + ' enabled runtime agents')
    print('DECLARATION CHECK: verify both machines live before cutover; stale generations and manual processes are not covered')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Check declared runtime, backup, support-service and client placement.

Evaluates the flake's host declarations and rejects split ownership: two
runtime or backup owners, workers or healing on an inactive or validating
host, support services on both hosts once one is named, a client tunnel on the
owner or pointing at its own machine, and forwards that could never bind.

It never activates hosts, inspects secrets, or looks at running processes:
stale generations and manually started processes are not covered.

  --phase PHASE   evaluate as if hosts/rei-mori-cutover-phase.nix said PHASE
  --all-phases    evaluate every phase against its expected placement
"""
import argparse
import json
from pathlib import Path
import subprocess

PHASES = ('preparation', 'stopped', 'validation', 'active')
SOURCE, DESTINATION = 'SungkyungM1X', 'yujin'

# What each phase must declare: runtime owner, backup owner, support hosts,
# and the owner's stage.
PHASE_EXPECTATIONS = {
    'preparation': {'expect': SOURCE, 'backups': SOURCE, 'support': 'both', 'stage': 'active'},
    'stopped': {'expect': 'none', 'backups': 'none', 'support': DESTINATION, 'stage': None},
    'validation': {'expect': DESTINATION, 'backups': DESTINATION, 'support': DESTINATION, 'stage': 'validation'},
    'active': {'expect': DESTINATION, 'backups': DESTINATION, 'support': DESTINATION, 'stage': 'active'},
}

BACKUP_AGENTS = ('pg-backup', 'pg-backup-offsite-sync')

EXPRESSION = '''phases: hosts:
let
  withPhase = phase: host:
    if phase == null || !(host.config ? home-manager) then host
    else host.extendModules {
      modules = [ ({ lib, ... }: {
        home-manager.users.shinzui.workstation.reiMoriCutover.phase = lib.mkForce phase;
      }) ];
    };
  summary = host:
    if host.config ? home-manager then
      let
        user = host.config.home-manager.users.shinzui;
        agents = user.launchd.agents;
        on = names: builtins.filter (name: agents ? ${name} && agents.${name}.enable) names;
        owned = user.workstation.reiMori;
        runtimeNames = builtins.filter (name:
          builtins.elem name owned.agents ||
          builtins.match "(rei|mori)-.*" name != null
        ) (builtins.attrNames agents);
        support = user.workstation.supportServices;
        client = user.workstation.reiMoriClient;
      in {
        hostName = host.config.networking.hostName;
        owner = owned.enable;
        stage = owned.stage;
        validationAgents = owned.validationAgents;
        enabled = on runtimeNames;
        watchdogSelfHeal = user.home.activation ? rei-watchdog-ensure-loaded;
        backups = user.services.postgresql.backups.enable;
        backupAgents = on [ "pg-backup" "pg-backup-offsite-sync" ];
        offsiteDirectory = user.services.postgresql.backups.offsiteDirectory;
        support = support.enable;
        supportAgents = on (support.agents ++ [ "redpanda" ]);
        redpanda = user.services.redpanda-container.enable;
        client = {
          enable = client.enable;
          target = if client.enable then client.target.name else null;
          agents = on client.agents;
          forwardWebPort = client.enable && client.forwardWebPort;
          supportForwards = client.enable && client.supportForwards;
        };
      }
    else {
      hostName = null; owner = false; stage = "active"; validationAgents = [ ]; enabled = [ ];
      watchdogSelfHeal = false; backups = false; backupAgents = [ ]; offsiteDirectory = null;
      support = false; supportAgents = [ ]; redpanda = false;
      client = { enable = false; target = null; agents = [ ]; forwardWebPort = false; supportForwards = false; };
    };
in builtins.listToAttrs (map (phase: {
  name = if phase == null then "declared" else phase;
  value = builtins.mapAttrs (_: host: summary (withPhase phase host)) hosts;
}) phases)'''


def validate_runtime(hosts, expected, stage=None):
    owners = sorted(name for name, host in hosts.items() if host['owner'])
    if len(owners) > 1:
        raise ValueError('multiple runtime owners are declared: ' + ', '.join(owners))
    for name, host in hosts.items():
        if not host['owner'] and (host['enabled'] or host['watchdogSelfHeal']):
            raise ValueError('inactive host can start or heal the runtime: ' + name)
        if host['owner'] and host['stage'] == 'validation':
            extra = sorted(set(host['enabled']) - set(host['validationAgents']))
            if extra or host['watchdogSelfHeal']:
                raise ValueError('validating owner can start workers or heal: ' + name + ' ' + ', '.join(extra))
    desired = [] if expected == 'none' else [expected]
    if owners != desired:
        raise ValueError('declared owner ' + (', '.join(owners) or 'none') + ' differs from --expect ' + expected)
    if stage is not None and owners and hosts[owners[0]]['stage'] != stage:
        raise ValueError('owner stage is ' + hosts[owners[0]]['stage'] + ', expected ' + stage)
    return owners


def validate_backups(hosts, expected):
    owners = sorted(name for name, host in hosts.items() if host.get('backups'))
    if len(owners) > 1:
        raise ValueError('multiple backup owners are declared: ' + ', '.join(owners))
    for name, host in hosts.items():
        agents = set(host.get('backupAgents', []))
        if not host.get('backups') and agents:
            raise ValueError('non-owner host schedules backups: ' + name)
        if host.get('backups') and agents != set(BACKUP_AGENTS):
            raise ValueError('backup owner lacks its scheduled agents: ' + name)
    directories = [(name, host['offsiteDirectory'].rstrip('/')) for name, host in hosts.items()
                   if host.get('offsiteDirectory')]
    for name, directory in directories:
        for other, other_directory in directories:
            if name != other and (directory == other_directory or directory.startswith(other_directory + '/')):
                raise ValueError('offsite mirror of ' + name + ' is not separate from ' + other + "'s")
    desired = [] if expected == 'none' else [expected]
    if owners != desired:
        raise ValueError('declared backup owner ' + (', '.join(owners) or 'none') + ' differs from --expect-backups ' + expected)
    return owners


def validate_support(hosts, expected):
    workstations = [name for name, host in hosts.items() if host.get('hostName')]
    running = sorted(name for name in workstations if hosts[name]['support'])
    for name in workstations:
        host = hosts[name]
        if not host['support'] and (host['supportAgents'] or host['redpanda']):
            raise ValueError('support services still declared on ' + name)
    if expected == 'both':
        desired = sorted(workstations)
    else:
        desired = [expected]
    if running != desired:
        raise ValueError('support services run on ' + (', '.join(running) or 'none') + ', expected ' + expected)
    return running


def validate_clients(hosts):
    by_host_name = {host['hostName']: name for name, host in hosts.items() if host.get('hostName')}
    owners = [name for name, host in hosts.items() if host['owner']]
    for name, host in hosts.items():
        client = host.get('client') or {}
        if not client.get('enable'):
            if client.get('agents'):
                raise ValueError('disabled client still declares tunnel agents: ' + name)
            continue
        if host['owner']:
            raise ValueError('runtime owner runs a client tunnel: ' + name)
        target = by_host_name.get(client['target'])
        if target == name:
            raise ValueError('client tunnel on ' + name + ' points at its own machine')
        if target is None:
            raise ValueError('client tunnel on ' + name + ' points at an unknown host ' + str(client['target']))
        if target not in owners:
            raise ValueError('client tunnel on ' + name + ' points at ' + target + ', which is not the runtime owner')
        if (client['forwardWebPort'] or client['supportForwards']) and host['support']:
            raise ValueError('client forwards on ' + name + ' cannot bind while its own support services run')


def validate(hosts, expected, expected_backups=None, expected_support=None, stage=None):
    owners = validate_runtime(hosts, expected, stage)
    if expected_backups is not None:
        validate_backups(hosts, expected_backups)
    if expected_support is not None:
        validate_support(hosts, expected_support)
    validate_clients(hosts)
    return owners


def evaluate(root, phases):
    # Phases come from PHASES or argparse choices, so quoting them is safe.
    nix_list = '[ ' + ' '.join('null' if phase is None else '"' + phase + '"' for phase in phases) + ' ]'
    expression = 'let phases = ' + nix_list + '; in ' + EXPRESSION.replace('phases: hosts:', 'hosts:', 1)
    result = subprocess.run(['nix', 'eval', '--json', '.#darwinConfigurations', '--apply', expression],
                            cwd=root, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip().splitlines()[-1] if result.stderr.strip() else 'nix eval failed')
    return json.loads(result.stdout)


def report(label, hosts, owners):
    print('PASS [' + label + ']: runtime owner ' + (owners[0] if owners else 'none (cutover stopped state)'))
    for name, host in sorted(hosts.items()):
        if not host.get('hostName'):
            continue
        client = host['client']
        print('  ' + name + ': ' + str(len(host['enabled'])) + ' runtime agents'
              + (' (stage ' + host['stage'] + ')' if host['owner'] else '')
              + ', backups ' + ('on' if host['backups'] else 'off')
              + ', support ' + ('on' if host['support'] else 'off')
              + ', client ' + ('-> ' + client['target'] + ' ' + str(client['agents']) if client['enable'] else 'off'))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--expect', default='SungkyungM1X', help='expected runtime owner, or none during cutover')
    parser.add_argument('--expect-backups', help='expected backup owner, or none')
    parser.add_argument('--expect-support', help='both, or the one host running the support services')
    parser.add_argument('--phase', choices=PHASES, help='evaluate with this cutover phase instead of the declared one')
    parser.add_argument('--all-phases', action='store_true', help='check every phase against its expected placement')
    args = parser.parse_args()
    root = Path(__file__).absolute().parent.parent
    try:
        if args.all_phases:
            results = evaluate(root, list(PHASES))
            for phase in PHASES:
                expected = PHASE_EXPECTATIONS[phase]
                owners = validate(results[phase], expected['expect'], expected['backups'], expected['support'],
                                  expected['stage'])
                report(phase, results[phase], owners)
        else:
            results = evaluate(root, [args.phase])
            label = args.phase or 'declared'
            owners = validate(results[label], args.expect, args.expect_backups, args.expect_support)
            report(label, results[label], owners)
    except RuntimeError as exc:
        parser.exit(1, 'CONFLICT: cannot evaluate declared ownership; build/evaluate the flake to diagnose\n  ' + str(exc) + '\n')
    except (ValueError, KeyError, TypeError) as exc:
        parser.exit(1, 'CONFLICT: ' + str(exc) + '\n')
    print('DECLARATION CHECK: verify both machines live before cutover; stale generations and manual processes are not covered')


if __name__ == '__main__':
    main()

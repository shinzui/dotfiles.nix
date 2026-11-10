#!/usr/bin/env python3
"""Reject split ownership, premature workers, double backups, and misplaced tunnels."""
import copy
from pathlib import Path
import runpy
import unittest

CHECK = runpy.run_path(str(Path(__file__).absolute().with_name('check-rei-mori-owner.py')))
VALIDATE = CHECK['validate']
SUPPORT_AGENTS = ['local-web-proxy', 'victorialogs', 'victorialogs-shipper-rei-worker-stdout',
                  'victoriatraces', 'victoriatraces-jaeger-ui', 'redpanda']
VALIDATION_AGENTS = ['mori-serve', 'rei-api', 'mina-web', 'reiko-web']


def client(target=None, agents=(), web=False, support=False):
    return {'enable': target is not None, 'target': target, 'agents': list(agents),
            'forwardWebPort': web, 'supportForwards': support}


def host(name, owner=False, enabled=(), heal=False, stage='active', backups=False,
         support=True, offsite='/Volumes/aki-2023/postgresql-backups', client_state=None):
    return {
        'hostName': name, 'owner': owner, 'stage': stage, 'validationAgents': VALIDATION_AGENTS,
        'enabled': list(enabled), 'watchdogSelfHeal': heal,
        'backups': backups, 'backupAgents': ['pg-backup', 'pg-backup-offsite-sync'] if backups else [],
        'offsiteDirectory': offsite,
        'support': support, 'supportAgents': list(SUPPORT_AGENTS) if support else [], 'redpanda': support,
        'client': client_state or client(),
    }


def preparation():
    return {
        'SungkyungM1X': host('sungkyung', owner=True, enabled=['rei-worker', 'mori-automate'], heal=True,
                             backups=True),
        'yujin': host('yujin', offsite='/Volumes/aki-2023/postgresql-backups-yujin',
                      client_state=client('sungkyung', ['sungkyung-client-tunnel', 'sungkyung-client-ingest'])),
        'bootstrap-arm': {'hostName': None, 'owner': False, 'stage': 'active', 'validationAgents': [],
                          'enabled': [], 'watchdogSelfHeal': False, 'backups': False, 'backupAgents': [],
                          'offsiteDirectory': None, 'support': False, 'supportAgents': [], 'redpanda': False,
                          'client': client()},
    }


def stopped():
    hosts = preparation()
    hosts['SungkyungM1X'] = host('sungkyung', support=False)
    hosts['yujin'] = host('yujin', offsite='/Volumes/aki-2023/postgresql-backups-yujin')
    return hosts


def destination(stage):
    hosts = stopped()
    enabled = VALIDATION_AGENTS if stage == 'validation' else VALIDATION_AGENTS + ['rei-worker', 'mori-automate']
    hosts['yujin'] = host('yujin', owner=True, stage=stage, enabled=enabled, heal=stage == 'active',
                          backups=True, offsite='/Volumes/aki-2023/postgresql-backups-yujin')
    hosts['SungkyungM1X']['client'] = client('yujin', ['yujin-client-tunnel', 'yujin-client-ingest',
                                                       'yujin-support-tunnel'], web=True, support=True)
    return hosts


class RuntimeTests(unittest.TestCase):
    def test_current_owner(self):
        self.assertEqual(VALIDATE(preparation(), 'SungkyungM1X', 'SungkyungM1X', 'both'), ['SungkyungM1X'])

    def test_two_owners_rejected(self):
        hosts = preparation()
        hosts['yujin']['owner'] = True
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'yujin')

    def test_inactive_agents_or_self_heal_rejected(self):
        for field, value in (('enabled', ['rei-worker']), ('watchdogSelfHeal', True)):
            hosts = preparation()
            hosts['yujin'][field] = value
            with self.assertRaises(ValueError):
                VALIDATE(hosts, 'SungkyungM1X')

    def test_stopped_cutover_requires_explicit_expectation(self):
        self.assertEqual(VALIDATE(stopped(), 'none', 'none', 'yujin'), [])
        with self.assertRaises(ValueError):
            VALIDATE(stopped(), 'SungkyungM1X')

    def test_validation_permits_only_web_and_api_agents(self):
        self.assertEqual(VALIDATE(destination('validation'), 'yujin', 'yujin', 'yujin', 'validation'), ['yujin'])
        for field, value in (('enabled', VALIDATION_AGENTS + ['rei-worker']),
                             ('enabled', VALIDATION_AGENTS + ['mori-rei-app']),
                             ('watchdogSelfHeal', True)):
            hosts = destination('validation')
            hosts['yujin'][field] = value
            with self.assertRaises(ValueError, msg=str(value)):
                VALIDATE(hosts, 'yujin')

    def test_active_destination_and_stage_expectation(self):
        self.assertEqual(VALIDATE(destination('active'), 'yujin', 'yujin', 'yujin', 'active'), ['yujin'])
        with self.assertRaises(ValueError):
            VALIDATE(destination('validation'), 'yujin', stage='active')


class BackupTests(unittest.TestCase):
    def test_two_backup_owners_rejected(self):
        hosts = preparation()
        hosts['yujin']['backups'] = True
        hosts['yujin']['backupAgents'] = ['pg-backup', 'pg-backup-offsite-sync']
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'SungkyungM1X', 'SungkyungM1X')

    def test_wrong_backup_expectation_rejected(self):
        for expected in ('yujin', 'none'):
            with self.assertRaises(ValueError, msg=expected):
                VALIDATE(preparation(), 'SungkyungM1X', expected)

    def test_non_owner_with_scheduled_agent_rejected(self):
        hosts = preparation()
        hosts['yujin']['backupAgents'] = ['pg-backup-offsite-sync']
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'SungkyungM1X', 'SungkyungM1X')

    def test_shared_or_nested_offsite_mirror_rejected(self):
        for offsite in ('/Volumes/aki-2023/postgresql-backups', '/Volumes/aki-2023/postgresql-backups/yujin'):
            hosts = preparation()
            hosts['yujin']['offsiteDirectory'] = offsite
            with self.assertRaises(ValueError, msg=offsite):
                VALIDATE(hosts, 'SungkyungM1X', 'SungkyungM1X')


class SupportTests(unittest.TestCase):
    def test_support_on_both_rejected_once_one_is_named(self):
        hosts = destination('validation')
        hosts['SungkyungM1X'].update(support=True, supportAgents=list(SUPPORT_AGENTS), redpanda=True)
        hosts['SungkyungM1X']['client'] = client('yujin', ['yujin-client-tunnel'])
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'yujin', 'yujin', 'yujin')

    def test_escaped_shipper_or_redpanda_rejected(self):
        for field, value in (('supportAgents', ['victorialogs-shipper-rei-worker-stdout']), ('redpanda', True)):
            hosts = stopped()
            hosts['SungkyungM1X'][field] = value
            with self.assertRaises(ValueError, msg=field):
                VALIDATE(hosts, 'none', 'none', 'yujin')

    def test_wrong_support_expectation_rejected(self):
        with self.assertRaises(ValueError):
            VALIDATE(preparation(), 'SungkyungM1X', 'SungkyungM1X', 'yujin')


class ClientTests(unittest.TestCase):
    def test_tunnel_on_owner_rejected(self):
        hosts = preparation()
        hosts['SungkyungM1X']['client'] = client('yujin', ['yujin-client-tunnel'])
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'SungkyungM1X')

    def test_tunnel_to_own_machine_rejected(self):
        hosts = preparation()
        hosts['yujin']['client'] = client('yujin', ['yujin-client-tunnel'])
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'SungkyungM1X')

    def test_tunnel_while_stopped_rejected(self):
        hosts = stopped()
        hosts['yujin']['client'] = client('sungkyung', ['sungkyung-client-tunnel'])
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'none')

    def test_support_tunnel_beside_support_services_rejected(self):
        hosts = destination('active')
        hosts['SungkyungM1X'].update(support=True, supportAgents=list(SUPPORT_AGENTS), redpanda=True)
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'yujin')

    def test_disabled_client_with_agents_rejected(self):
        hosts = stopped()
        hosts['yujin']['client']['agents'] = ['sungkyung-client-ingest']
        with self.assertRaises(ValueError):
            VALIDATE(hosts, 'none')


class PhaseTableTests(unittest.TestCase):
    def test_fixtures_match_phase_expectations(self):
        fixtures = {'preparation': preparation(), 'stopped': stopped(),
                    'validation': destination('validation'), 'active': destination('active')}
        for phase, expected in CHECK['PHASE_EXPECTATIONS'].items():
            VALIDATE(fixtures[phase], expected['expect'], expected['backups'], expected['support'],
                     expected['stage'])


if __name__ == '__main__':
    unittest.main()

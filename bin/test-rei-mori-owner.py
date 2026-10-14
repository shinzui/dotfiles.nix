#!/usr/bin/env python3
"""Reject split ownership and healing on a declared inactive host."""
import copy
from pathlib import Path
import runpy
import unittest

VALIDATE = runpy.run_path(str(Path(__file__).absolute().with_name('check-rei-mori-owner.py')))['validate']


class OwnershipTests(unittest.TestCase):
    def setUp(self):
        self.hosts = {
            'SungkyungM1X': {'owner': True, 'enabled': ['rei-worker', 'mori-automate'], 'watchdogSelfHeal': True},
            'yujin': {'owner': False, 'enabled': [], 'watchdogSelfHeal': False},
            'bootstrap-arm': {'owner': False, 'enabled': [], 'watchdogSelfHeal': False},
        }

    def test_current_owner(self):
        self.assertEqual(VALIDATE(self.hosts, 'SungkyungM1X'), ['SungkyungM1X'])

    def test_two_owners_rejected(self):
        self.hosts['yujin']['owner'] = True
        with self.assertRaises(ValueError):
            VALIDATE(self.hosts, 'yujin')

    def test_inactive_agents_or_self_heal_rejected(self):
        for field, value in (('enabled', ['rei-worker']), ('watchdogSelfHeal', True)):
            hosts = copy.deepcopy(self.hosts)
            hosts['yujin'][field] = value
            with self.assertRaises(ValueError):
                VALIDATE(hosts, 'SungkyungM1X')

    def test_stopped_cutover_requires_explicit_expectation(self):
        self.hosts['SungkyungM1X'] = {'owner': False, 'enabled': [], 'watchdogSelfHeal': False}
        self.assertEqual(VALIDATE(self.hosts, 'none'), [])
        with self.assertRaises(ValueError):
            VALIDATE(self.hosts, 'SungkyungM1X')
        self.hosts['yujin'] = {'owner': True, 'enabled': ['rei-worker'], 'watchdogSelfHeal': True}
        self.assertEqual(VALIDATE(self.hosts, 'yujin'), ['yujin'])


if __name__ == '__main__':
    unittest.main()

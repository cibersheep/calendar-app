# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013 Canonical Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Calendar app autopilot tests."""

import os
import shutil
import logging

import fixtures
from calendar_app import emulators

from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from autopilot import logging as autopilot_logging

from ubuntuuitoolkit import (
    base,
    emulators as toolkit_emulators,
    fixture_setup as toolkit_fixtures
)

logger = logging.getLogger(__name__)


class CalendarTestCase(AutopilotTestCase):

    """A common test case class that provides several useful methods for
    calendar-app tests.

    """
    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    local_location = os.path.dirname(os.path.dirname(os.getcwd()))
    local_location_qml = local_location + "/calendar.qml"
    installed_location_qml = "/usr/share/calendar-app/calendar.qml"

    def get_launcher_and_type(self):
        if os.path.exists(self.local_location_qml):
            launcher = self.launch_test_local
            test_type = 'local'
        elif os.path.exists(self.installed_location_qml):
            launcher = self.launch_test_installed
            test_type = 'deb'
        else:
            launcher = self.launch_test_click
            test_type = 'click'
        return launcher, test_type

    def setUp(self):
        launcher, self.test_type = self.get_launcher_and_type()
        self.home_dir = self._patch_home()
        self.pointing_device = Pointer(self.input_device_class.create())
        super(CalendarTestCase, self).setUp()

        #turn off the OSK so it doesn't block screen elements
        if model() != 'Desktop':
            os.system('stop maliit-server')
            self.addCleanup(os.system, 'start maliit-server')

        # Unset the current locale to ensure locale-specific data
        # (day and month names, first day of the week, …) doesn’t get
        # in the way of test expectations.
        self.patch_environment('LC_ALL', 'C')

        self.app = launcher()

    @autopilot_logging.log_action(logger.info)
    def launch_test_local(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.local_location_qml,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_installed(self):
        return self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.installed_location_qml,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_click(self):
        return self.launch_click_package(
            "com.ubuntu.calendar",
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def _copy_xauthority_file(self, directory):
        """ Copy .Xauthority file to directory, if it exists in /home
        """
        xauth = os.path.expanduser(os.path.join('~', '.Xauthority'))
        if os.path.isfile(xauth):
            logger.debug("Copying .Xauthority to " + directory)
            shutil.copyfile(
                os.path.expanduser(os.path.join('~', '.Xauthority')),
                os.path.join(directory, '.Xauthority'))

    def _patch_home(self):
        """ mock /home for testing purposes to preserve user data
        """
        #click has TMPDIR (apparmor) set, but the desktop can write
        #to a traditional /tmp directory
        if self.test_type == 'click':
            temp_dir_fixture = fixtures.TempDir(os.environ['XDG_RUNTIME_DIR'])
        else:
            temp_dir_fixture = fixtures.TempDir()
        self.useFixture(temp_dir_fixture)
        temp_dir = temp_dir_fixture.path

        #If running under xvfb, as jenkins does,
        #xsession will fail to start without xauthority file
        #Thus if the Xauthority file is in the home directory
        #make sure we copy it to our temp home directory
        self._copy_xauthority_file(temp_dir)

        #click requires using initctl env (upstart), but the desktop can set
        #an environment variable instead
        if self.test_type == 'click':
            self.useFixture(toolkit_fixtures.InitctlEnvironmentVariable(
                            HOME=temp_dir))
        else:
            self.useFixture(fixtures.EnvironmentVariable('HOME',
                                                         newvalue=temp_dir))

        logger.debug("Patched home to fake home directory " + temp_dir)

        return temp_dir

    @property
    def main_view(self):
        return self.app.wait_select_single(emulators.MainView)

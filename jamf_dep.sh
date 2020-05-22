#!/bin/bash

# jamf_dep.sh - a script to deploy Jamf Connect Login and Jamf Connect Verify
# with a prestage enrollment package.
# — SRABBITT January 25, 2019 9:01 AM

# MIT License
#
# Copyright (c) 2020 Jamf Software

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


JAMFBIN="/usr/local/bin/jamf"

# Logging for debug purposes
echo "STARTING RUN" >> /var/tmp/depnotify.log

# Set the Main Title at the top of the window

echo "Command: MainTitle: Welcome to AnyCo!" >> /var/tmp/depnotify.log
echo "Command: MainText: Welcome to your new Mac.\\nSit tight as we do some basic setup to get you ready for success.\\nYou can see the status of the setup on the progress bar below." >> /var/tmp/depnotify.log

echo "Status: Installing Jamf" >> /var/tmp/depnotify.log

# Wait until the Jamf Binary is fully downloaded
echo $JAMFBIN
until [ -f $JAMFBIN ]
do
	echo "Status: Waiting on Jamf" >> /var/tmp/depnotify.log 
	sleep 2
done

echo "Status: Jamf Installed" >> /var/tmp/depnotify.log 

serialNumber=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

echo "Status: Naming computer '$serialNumber'" >> /var/tmp/depnotify.log 

$JAMFBIN setComputerName -useSerialNumber

echo "Status: Passing command and control to Jamf Pro" >> /var/tmp/depnotify.log

$JAMFBIN policy -event JamfConnectLoginInstalled

# Use a Jamf Pro policy set to Ongoing and Custom Trigger JamfConnectLoginInstalled to
#	continue your zero touch workflow to install essential apps like Jamf Protect for
#	endpoing protection, the Launch Agent for Jamf Connect Sync, Self Service, etc.
	
# The last polic triggered by JamfConnectLoginInstalled should run a command
# echo "Command: Quit" >> /var/tmp/depnotify.log
# to quit the Notify mechanism if you enabled it in the postinstaller.sh script
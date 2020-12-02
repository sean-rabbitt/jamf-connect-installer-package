#!/bin/bash

# Generic Jamf Connect Prestage Enrollment installer package
# — SRABBITT May 22, 2020 12:52 PM
# Version 2 installer updated on September 29, 2020
# Updated 20NOV2020 - Added wait for .AppleSetupDone to see if we can make Big Sur happier.

# What does it do:
#	Download latest version of Jamf Connect from the public latest version URL
#	Convert the DMG to a CDR to get rid of the license prompt
# 	Installs Jamf Connect
# 	Optional - code you can comment on to install the launch agent for the menu bar agent
#	Note - Don't install the launch agent with Google.  There's no ROPG from Google
# 		as defined in the OpenID spec, so there's no ongoing password sync with the menu bar
#	Unmount CDR
#	Delete downloaded tmp files

# HOW TO USE:
# 	Make an installer .pkg file and include this as postinstaller script
#	In the installer package, you can include things like branding images, 
#	backgrounds, logos, help files for users, etc.  The script here downloads 
#	Jamf Connect and installs it.
#
#	AUTHCHANGER NOTES: I took out the authchanger command because you should be
#	pushing your com.jamf.connect.login and com.jamf.connect configuration profiles
#	BEFORE installing this package.  See https://docs.jamf.com/jamf-connect/administrator-guide/authchanger.html
#	for all the deets on that.  You could, of course, also manually toss in some 
#	authchanger commands at the bottom of this for the lols.
	
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
	

# Vendor supplied DMG file
VendorDMG="JamfConnect.dmg"
VendorCDR="JamfConnect.cdr"

# Temp Path
TMP_PATH=/private/tmp

# Jamf Connect Mounted Volume Name
# If you wanted to get fancy and add code here to find out what the volume 
# 	mount point is automagically, go crazy baby.  Open source means change it up.
JamfConnectVOLUME=/Volumes/JamfConnect

# Jamf Connect installer package name as found in the DMG
INSTALLER_FILENAME="JamfConnect.pkg"

# Launch Agent installer package name as found in the DMG
LAUNCHAGENT_FILENAME="JamfConnectLaunchAgent.pkg"

# Change installer filename to include full path
INSTALLER_FILENAME=$(echo "$JamfConnectVOLUME/$INSTALLER_FILENAME")
# Change lauchagent filename to include full path
LAUNCHAGENT_FILENAME=$(echo "$JamfConnectVOLUME/Resources/$LAUNCHAGENT_FILENAME")

# If we're coming in from Jamf Pro, we should have been passed a target mount point.  Otherwise, assume root directory is target drive
TARGET_MOUNT=$3
if [ -z "$TARGET_MOUNT" ]; then 
	TARGET_MOUNT="/"
fi 

# Download vendor supplied DMG file into /tmp/
/usr/bin/curl https://files.jamfconnect.com/$VendorDMG -o "$TMP_PATH"/"$VendorDMG" > /dev/null

# Convert .dmg file to accept the license silently
/usr/bin/hdiutil convert -quiet "$TMP_PATH"/"$VendorDMG" -format UDTO -o "$TMP_PATH"/"$VendorCDR"

# Mount vendor supplied DMG File
/usr/bin/hdiutil attach "$TMP_PATH"/"$VendorCDR" -nobrowse -quiet

# Install Jamf Connect
/usr/sbin/installer -pkg "$INSTALLER_FILENAME" -target "$TARGET_MOUNT"

# Install the launch agent
#### GOOGLE USERS #### COMMENT THIS NEXT LINE OUT.
/usr/sbin/installer -pkg "$LAUNCHAGENT_FILENAME" -target "$TARGET_MOUNT"

# AUTHCHANGER FOR THE LOLS?
# This is where you would put your authchanger command.
# But you really should be using a config profile scoped to com.jamf.connect.authchanger
# See https://docs.jamf.com/jamf-connect/administrator-guide/authchanger.html for details
# /usr/local/bin/authchanger -reset -JamfConnect

#####################################################################
# For zero touch enrollment only!  If an enrollment computer is on a slow
# network connection, the user may be presented with a standard macOS login
# window asking for a typed user name and password.  We must kill the loginwindow
# IF and ONLY IF we're at the Setup Assistant user still.  If we kill the loginwindow
# process while a user is actually using the computer, they will be unceremoniously
# kicked out of their current session.
#####################################################################

# For macOS Big Sur - Wait until they've decided that Apple Setup is Done.

while [ ! -f "/var/db/.AppleSetupDone" ]; do
	sleep 2
done

# Determine who is the current user
loggedinuser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

# If the current logged in user is _mbsetupuser or if we're root, we must still be in Setup Assistant
if [ "$loggedinuser" == "_mbsetupuser" ] || [ "$loggedinuser" == "root" ]; 
	then
	# Once we're sure that Jamf Connect is fully installed, kill the loginwindow
	# process to trigger Jamf Connect Login to appear
	/usr/bin/killall -9 loginwindow
fi

# Unmount JamfConnect Volume
/usr/bin/hdiutil detach "$JamfConnectVOLUME"

# Remove the downloaded vendor supplied DMG file
rm -f "$TMP_PATH"/"$VendorDMG"
rm -f "$TMP_PATH"/"$VendorCDR"

exit 0
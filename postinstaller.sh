#!/bin/bash

# Generic Jamf Connect Prestage Enrollment installer package
# — SRABBITT May 22, 2020 12:52 PM

# What does it do:
#	Download latest version of Jamf Connect from the public latest version URL
#	Convert the DMG to a CDR to get rid of the license prompt
#	Get the latest version numbers from the file names in the DMG
#	If installer file name contains the word "Okta" in any combo of upper/lower case,
#		Install Jamf Connect Login, Jamf Connect Sync, run an auth changer to enable
#		Okta version of Login AND RunScript AND Notify mechanism
#	If installer file name contains the word "Google" in any combo of upper/lower case,
#		Install Jamf Connect Login, run authchanger to enable OIDC / RunScript / Notify
#	Else, Install Jamf Connect Login, Jamf Connect Verify, run Authchanger to enable
#		OIDC / RunScript / Notify
#	Unmount CDR
#	Delete downloaded tmp files
	
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
JamfConnectVOLUME=/Volumes/JamfConnect

TARGET_MOUNT=$3
if [ -z $TARGET_MOUNT]; then 
	TARGET_MOUNT="/"
fi 

# Download vendor supplied DMG file into /tmp/
/usr/bin/curl https://files.jamfconnect.com/$VendorDMG -o "$TMP_PATH"/"$VendorDMG" > /dev/null

# Convert .dmg file to accept the license silently
/usr/bin/hdiutil convert -quiet "$TMP_PATH"/"$VendorDMG" -format UDTO -o "$TMP_PATH"/"$VendorCDR"

# Mount vendor supplied DMG File
/usr/bin/hdiutil attach "$TMP_PATH"/"$VendorCDR" -nobrowse -quiet

# Get the names and paths of the current installers
cd "$JamfConnectVOLUME""/Jamf Connect Login/"
LOGIN_FILENAME=$(ls JamfConnectLogin*)
LOGIN_FILENAME=$(echo "$JamfConnectVOLUME/Jamf Connect Login/$LOGIN_FILENAME")
cd "$JamfConnectVOLUME""/Jamf Connect Sync/"
SYNC_FILENAME=$(ls JamfConnectSync*)
SYNC_FILENAME=$(echo "$JamfConnectVOLUME/Jamf Connect Sync/$SYNC_FILENAME")
cd "$JamfConnectVOLUME""/Jamf Connect Verify/"
VERIFY_FILENAME=$(ls JamfConnectVerify*)
VERIFY_FILENAME=$(echo "$JamfConnectVOLUME/Jamf Connect Verify/$VERIFY_FILENAME")
cd ~

# Install Login
/usr/sbin/installer -pkg "$LOGIN_FILENAME" -target $TARGET_MOUNT

#####################################################################
### CHECK PACKAGE NAME - see if the .pkg file has been renamed to include "okta" or "google"
### "okta" - If found, install Jamf Connect Login and Jamf Connect Sync
### "google" - If found, install ONLY Jamf Connect Login
### otherwise, assume we're installing for OIDC (Azure, ADFS, OneLogin, IBM, Ping, etc)
###		and install Jamf Connect Login and Jamf Connect Verify
#####################################################################

# Set the shell option for case insensitive
shopt -s nocasematch # OPTIONAL

### OKTA
# See if we're doing OIDC or Okta.  If package name contains "okta" in any
# combo of upper or lower case, follow Okta workflow.
if [[ $1 == *"okta"* ]]; then 
	/usr/bin/logger "Enabling Okta"
	/usr/sbin/installer -pkg "$SYNC_FILENAME" -target $TARGET_MOUNT

	# Authchanger commands are documented at 
	# https://docs.jamf.com/jamf-connect/administrator-guide/authchanger.html

	# In this example, we:
		# Reset the authchanger database with the -reset flag
		# Activate the Okta login mechanism with -Okta
		# Activate the Plugin Authentication Module (PAM) with -DefaultJCRight
		# Then, after the user has authenticated (-preAuth)
			# Show a EULA (JamfConnectLogin:EULA)
			# Run a script (JamfConnectLogin:RunScript,privileged) which can 
				# be used for calling Jamf Pro custom triggers 
				# and make changes to the messages in the Notify mech 
			# Activate the Notify mechanism (JamfConnectLogin:Notify)

	# /usr/local/bin/authchanger -reset -Okta -DefaultJCRight -preAuth JamfConnectLogin:EULA JamfConnectLogin:RunScript,privileged JamfConnectLogin:Notify
	
	# Default behavior of the Jamf Connect installer package is to only enable the IDP
	/usr/local/bin/authchanger -reset -Okta
	
### GOOGLE
else if [[ $1 == *"google"* ]]; then 
	/usr/bin/logger "Detected Google only.  Skipping install of Verify."

	# In this example, we:
			# Reset the authchanger database with the -reset flag
			# Activate the OIDC login mechanism with -OIDC
			# Activate the Plugin Authentication Module (PAM) with -DefaultJCRight
			# Then, after the user has authenticated (-preAuth)
				# Show a EULA (JamfConnectLogin:EULA)
				# Run a script (JamfConnectLogin:RunScript,privileged) which can 
					# be used for calling Jamf Pro custom triggers 
					# and make changes to the messages in the Notify mech 
				# Activate the Notify mechanism (JamfConnectLogin:Notify)

		# /usr/local/bin/authchanger -reset -OIDC -DefaultJCRight -preAuth JamfConnectLogin:EULA JamfConnectLogin:RunScript,privileged JamfConnectLogin:Notify
		
		# Default behavior of the Jamf Connect installer package is to only enable the IDP
		/usr/local/bin/authchanger -reset -OIDC

### ALL OTHER PROVIDERS
else
	/usr/bin/logger "Enabling OIDC"
	/usr/bin/logger "Adding the default right to the authorization db"
	/usr/sbin/installer -pkg "$VERIFY_FILENAME" -target $TARGET_MOUNT
	
	# In this example, we:
				# Reset the authchanger database with the -reset flag
				# Activate the OIDC login mechanism with -OIDC
				# Activate the Plugin Authentication Module (PAM) with -DefaultJCRight
				# Then, after the user has authenticated (-preAuth)
					# Show a EULA (JamfConnectLogin:EULA)
					# Run a script (JamfConnectLogin:RunScript,privileged) which can 
						# be used for calling Jamf Pro custom triggers 
						# and make changes to the messages in the Notify mech 
					# Activate the Notify mechanism (JamfConnectLogin:Notify)

	# /usr/local/bin/authchanger -reset -OIDC -DefaultJCRight -preAuth JamfConnectLogin:EULA JamfConnectLogin:RunScript,privileged JamfConnectLogin:Notify

	# Default behavior of the Jamf Connect installer package is to only enable the IDP
	/usr/local/bin/authchanger -reset -OIDC

fi
fi

#####################################################################
# For zero touch enrollment only!  If an enrollment computer is on a slow
# network connection, the user may be presented with a standard macOS login
# window asking for a typed user name and password.  We must kill the loginwindow
# IF and ONLY IF we're at the Setup Assistant user still.  If we kill the loginwindow
# process while a user is actually using the computer, they will be unceremoniously
# kicked out of their current session.
#####################################################################

# Determine who is the current user
loggedinuser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

# If the current logged in user is _mbsetupuser or if we're root, we must still be in Setup Assistant
if [ $loggedinuser == "_mbsetupuser" ] || [ $loggedinuser == "root" ]; 
	then
	# Once we're sure that Jamf Connect is fully installed, kill the loginwindow
	# process to trigger Jamf Connect Login to appear
	/usr/bin/killall -9 loginwindow
fi

# Unmount JamfConnect Volume
/usr/bin/hdiutil detach $JamfConnectVOLUME

# Remove the downloaded vendor supplied DMG file
rm -f "$TMP_PATH"/"$VendorDMG"
rm -f "$TMP_PATH"/"$VendorCDR"

exit 0
# jamf-connect-prestage-package
A postinstaller script method of installing the latest version of Jamf Connect Login and appropriate matching Verify or Sync

Note: While this installer is designed to facilitate prestage enrollment packages, it can 
also be used with a standard policy in Jamf Pro to install the latest version of Connect.

# What does it do:
	Download latest version of Jamf Connect from the public latest version URL
	Convert the DMG to a CDR to get rid of the license prompt
	Installs Jamf Connect
	OPTIONAL - Installs the Jamf Connect Launch Agent for the menu bar app.
	(Note: Don't do that if you're using Google Identity.)
	Unmount CDR
	Delete downloaded tmp files
	If the currently logged in user is _mbsetupuser OR root, that means we're at the 
		login screen or still inside Setup Assistant.  In that case, force the login
		window to reload - perfect for slow network connections and zero touch configuration.

# How it is used:

Create a package with Jamf Composer (or similar application).  You can include any sort of extras
in the package like background images, branding logos, RunScript files, etc.

Include the script as a postinstaller script.  

If you haven't read https://docs.jamf.com/jamf-connect/administrator-guide/authchanger.html
yet, check it out because you must push the configuration profiles for com.jamf.connect and 
com.jamf.connect.login OR com.jamf.connect.authchanger for it to do anything by default.

Authchanger can do things like enable Demobilization of network accounts, enabling the 
Notify mechanism to show users what you're doing to the user's machine before dropping
them into Finder, or use the RunScript mechanism to call Jamf Pro policies for a zero touch
configuration.  All of that is done with commands like 

authchanger -reset -JamfConnect -preAuth JamfConnectLogin:EULA JamfConnectLogin:RunScript,privileged JamfConnectLogin:Notify

if and only if you want to get fancy.  With 2.0 of the software, the authchanger has everything
turned on by default, but we read from com.jamf.connect.login to see if those mechs should do 
anything.  So for example, if EULAText isn't set, you never see a EULA screen.

# What is included:

postinstaller.sh - Use this script as the postinstaller script
jamf_dep.sh - A sample script used with the RunScript mechanism and the Notify mechanism to
	call Jamf Pro policies after the user has successfully logged in and Jamf Connect has
	created a user account.
ComposerSample.png - A sample image to show how to use Composer to make the package file.

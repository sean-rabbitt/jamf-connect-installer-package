# jamf-connect-prestage-package
A postinstaller script method of installing the latest version of Jamf Connect Login and appropriate matching Verify or Sync

Note: While this installer is designed to facilitate prestage enrollment packages, it can 
also be used with a standard policy in Jamf Pro to install the latest version of Connect.

# What does it do:
	Download latest version of Jamf Connect from the public latest version URL
	Convert the DMG to a CDR to get rid of the license prompt
	Get the latest version numbers from the file names in the DMG
	If installer file name contains the word "Okta" in any combo of upper/lower case,
		Install Jamf Connect Login, Jamf Connect Sync, run an auth changer to enable
		Okta version of Login AND RunScript AND Notify mechanism
	If installer file name contains the word "Google" in any combo of upper/lower case,
		Install Jamf Connect Login, run authchanger to enable OIDC / RunScript / Notify
	Else, Install Jamf Connect Login, Jamf Connect Verify, run Authchanger to enable
		OIDC / RunScript / Notify
	Unmount CDR
	Delete downloaded tmp files
	If the currently logged in user is _mbsetupuser OR root, that means we're at the 
		login screen or still inside Setup Assistant.  In that case, force the login
		window to reload - perfect for slow network connections and zero touch configuration.

How it is used:

Create a package with Jamf Composer (or similar application).  You can include any sort of extras
in the package like background images, branding logos, RunScript files, etc.

Include the script as a postinstaller script.  Be sure to change the authchanger commands to 
fit your needs.  You can read more about authchanger at:
https://docs.jamf.com/jamf-connect/administrator-guide/authchanger.html

Authchanger can do things like enable Demobilization of network accounts, enabling the 
Notify mechanism to show users what you're doing to the user's machine before dropping
them into Finder, or use the RunScript mechanism to call Jamf Pro policies for a zero touch
configuration.

What is included:

postinstaller.sh - Use this script as the postinstaller script
jamf_dep.sh - A sample script used with the RunScript mechanism and the Notify mechanism to
	call Jamf Pro policies after the user has successfully logged in and Jamf Connect has
	created a user account.
ComposerSample.png - A sample image to show how to use Composer to make the package file.
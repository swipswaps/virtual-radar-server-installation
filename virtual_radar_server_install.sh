#!/bin/bash
#
# Virtual Radar Server installation script.
# VRS Homepage:  http://www.virtualradarserver.co.uk
#
# VERY BRIEF SUMMARY OF THIS SCRIPT:
#
# This script helps the novice user to install VRS and have VRS up and running.
# With just a few keystrokes, VRS may get installed and start displaying planes on the VRS webpage.
# Operator flags, silhouette flags and a few sample aircraft photos may also be downloaded and installed.
# A sample database file consisting of more detailed information of a few planes may be downloaded and installed.
# As an option, the user may also enter the latitude and longitude of the center of the VRS webpage map.
# As an option, the user may also enter a receiver.
# A directory structure will be created for the convenience of those who wish to enhance VRS' appearance and performance.
#
# This script has been confirmed to work with VRS version 2.4.4 on Raspberry Pi OS Buster (32-bit -- Desktop & Lite), Ubuntu 20.04 and Fedora 32.
# Note that Raspberry Pi OS was recently known as Raspbian.
#
# The author of this script has nothing to do with the creation, development or support of Virtual Radar Server.
# Script credit and more information here:
#   https://github.com/mypiaware
#   https://github.com/mypiaware/virtual-radar-server-installation/blob/master/README.md


#######################################################################################################
########################################   Declare variables   ########################################
#######################################################################################################


# Declare directory and filename variables (Directories will later get created if not already existing.)
CONFIGURATIONFILENAME="Configuration.xml"            # The simple filename of VRS' configuration file.  (This value should not be changed.)
PLUGINCONFIGFILENAME="PluginsConfiguration.txt"      # The simple filename of VRS' plugin configuration file.  (This value should not be changed.)
DATABASEFILENAME="BaseStation.sqb"                   # The simple filename of VRS' database file.  (This value generally may not need to be changed.)
INSTALLERCONFIGFILENAME="InstallerConfiguration.xml" # The simple filename of the file that sets the VRS port value.  (This value should not be changed.)
ANNOUNCEMENTFILENAME="Announcement.html"             # The simple filename of the HTML used to optionally display a message at the top of the website.  (Value may be changed to any HTML filename.)
READMEFILENAME="README.txt"                          # The simple filename of the readme file to explain how to create an announcement message at the top of the website.

HOMEDIR=$( getent passwd "$USER" | cut -d: -f6 )  # Find the home directory of the user calling this script.

VRSROOTDIRECTORY="$HOMEDIR/VirtualRadarServer"        # An arbitrary directory to hold the installation and extras for VRS.
VRSINSTALLDIRECTORY="$VRSROOTDIRECTORY/Installation"  # An arbitrary directory to hold the installation of VRS.
EXTRASDIRECTORY="$VRSROOTDIRECTORY/VRS-Extras"        # An arbitrary root directory for all extra VRS files (custom web files, database file, operator flags, silhouettes.)

SHAREDIRECTORY="$HOMEDIR/.local/share/VirtualRadar"        # The location and name of the directory to hold customization files.  (This value should not be changed.)
CONFIGFILE="$SHAREDIRECTORY/$CONFIGURATIONFILENAME"        # The location and name of the main configuration file.  (This value should not be changed.)
PLUGINSCONFIGFILE="$SHAREDIRECTORY/$PLUGINCONFIGFILENAME"  # The location and name of the plugins configuration file.  (This value should not be changed.)

OPFLAGSDIRECTORY="$EXTRASDIRECTORY/OperatorFlags"    # An arbitrary directory to store the operator flag images.
PICTURESDIRECTORY="$EXTRASDIRECTORY/Pictures"        # An arbitrary directory to store photos of specific aircrafts.
SILHOUETTESDIRECTORY="$EXTRASDIRECTORY/Silhouettes"  # An arbitrary directory to store the silhouette images.
TILECACHEDIRECTORY="$EXTRASDIRECTORY/TileCache"      # An arbitrary directory to store the tile server map cached images from the Tile Server Cache Plugin.

CUSTOMCONTENTPLUGINDIRECTORY="$EXTRASDIRECTORY/CustomContent"                     # An arbitrary directory to store two directories for the Custom Content Plugin.
CUSTOMINJECTEDFILESDIRECTORY="$CUSTOMCONTENTPLUGINDIRECTORY/CustomInjectedFiles"  # An arbitrary directory to store files used by the Custom Content Plugin to inject into existing VRS web files.
CUSTOMWEBFILESDIRECTORY="$CUSTOMCONTENTPLUGINDIRECTORY/CustomWebFiles"            # An arbitrary directory to store custom VRS web files used by the Custom Content Plugin.

DATABASEMAINDIRECTORY="$EXTRASDIRECTORY/Databases"               # An arbitrary root directory to store two directories for the database file and the database backup file.
DATABASEDIRECTORY="$DATABASEMAINDIRECTORY/Database"              # An arbitrary directory to store the SQLite database file.
DATABASEBACKUPDIRECTORY="$DATABASEMAINDIRECTORY/DatabaseBackup"  # An arbitrary directory for the database file backup.

DATABASEFILE="$DATABASEDIRECTORY/$DATABASEFILENAME"                   # An arbitrary location and name for the SQLite database file.
DATABASEBACKUPSCRIPT="$DATABASEBACKUPDIRECTORY/backupvrsdb.sh"        # An arbitrary location and name of the database file backup script.
DATABASEBACKUPFILE="$DATABASEBACKUPDIRECTORY/BaseStation_BACKUP.sqb"  # An arbitrary location and name of the database file's backup file.

STARTCOMMANDDIR="/usr/local/bin"                       # The location of the universal command to start VRS.  (This value should not be changed.)
STARTCOMMANDFILENAME="vrs"                             # An arbitrary simple filename of the universal command to start VRS.
STARTCOMMAND="$STARTCOMMANDDIR/$STARTCOMMANDFILENAME"  # The full path of the VRS start command.

SERVICEDIR="/etc/systemd/system"                      # Directory to store service file to run VRS in the background.  (This value should not be changed.)
SERVICEFILENAME="vrs"                                 # An arbitrary name of the service file to run VRS in the background.
SERVICEFILE="$SERVICEDIR/${SERVICEFILENAME}.service"  # The full path of the service file to run VRS in the background.

TEMPDIR="/tmp/vrs"  # An arbitrary directory where downloaded files are kept.


# List of all possible directories that will need to be created.
VRSDIRECTORIES=(
   "$VRSROOTDIRECTORY"
   "$VRSINSTALLDIRECTORY"
   "$SHAREDIRECTORY"
   "$EXTRASDIRECTORY"
   "$CUSTOMCONTENTPLUGINDIRECTORY"
   "$CUSTOMINJECTEDFILESDIRECTORY"
   "$CUSTOMWEBFILESDIRECTORY"
   "$DATABASEMAINDIRECTORY"
   "$DATABASEDIRECTORY"
   "$DATABASEBACKUPDIRECTORY"
   "$OPFLAGSDIRECTORY"
   "$PICTURESDIRECTORY"
   "$SILHOUETTESDIRECTORY"
   "$TILECACHEDIRECTORY"
   "$TEMPDIR"
)


# Declare an array of URLs for all the VRS files.
VRSFILES=(
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.LanguagePack.tar.gz"  # Install language pack files first because the 'VirtualRadar.WebSite.resources.dll' file may be newer in the 'VirtualRadar.tar.gz' file.
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.tar.gz"
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.exe.config.tar.gz"
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.CustomContentPlugin.tar.gz"
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.DatabaseEditorPlugin.tar.gz"
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.DatabaseWriterPlugin.tar.gz"
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.TileServerCachePlugin.tar.gz"
   "http://www.virtualradarserver.co.uk/Files/VirtualRadar.WebAdminPlugin.tar.gz"
)


# Declare URLs for operator flags, silhouettes and a database file. (Change any URL if better files are found elsewhere.)
OPFLAGSURL="http://www.woodair.net/SBS/Download/LOGO.zip"
SILHOUETTESURL="http://www.kinetic.co.uk/repo/SilhouettesLogos.zip"
DATABASEURL="https://github.com/mypiaware/virtual-radar-server-installation/raw/master/Downloads/Database/BaseStation.sqb"
PICTURESURL="https://github.com/mypiaware/virtual-radar-server-installation/raw/master/Downloads/Pictures/Pictures.zip"


# Declare a default port value. (User is given a choice to change it.  If a port has already been set from a previous installation, then set the already existing port value as the default.)
DEFAULTPORT="8090"
if [ -f "$SHAREDIRECTORY/$INSTALLERCONFIGFILENAME" ]; then
   EXISTINGPORT=$(<"$SHAREDIRECTORY/$INSTALLERCONFIGFILENAME")
   if [[ $EXISTINGPORT =~ \<WebServerPort\>([[:digit:]]+)\</WebServerPort\> ]]; then
      DEFAULTPORT=${BASH_REMATCH[1]}
   fi
fi


# Parameters for the VRS command.
VRSCMD_GUI="gui"
VRSCMD_NOGUI="nogui"
VRSCMD_STARTPROCESS="startbg"
VRSCMD_STOPPROCESS="stopbg"
VRSCMD_ENABLE="enable"
VRSCMD_DISABLE="disable"
VRSCMD_WEBADMIN="webadmin"
VRSCMD_LOG="log"


# Get the local IP address of this machine.
if [[ $(hostname -I) =~ ^([[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}) ]]; then
   LOCALIP=${BASH_REMATCH[1]}
fi


# Just to give some color to some text.
BOLD_FONT='\033[1m'
BLUE_COLOR='\033[1;34m'
GREEN_COLOR='\033[1;32m'
RED_COLOR='\033[1;31m'
ORANGE_COLOR='\033[0;33m'
NO_COLOR='\033[0m'


# Function ran after nearly every command in this script to report an error if one exists.
function ERROREXIT {
   if [ $? -ne 0 ]; then
      printf "${RED_COLOR}ERROR! $2${NO_COLOR}\n"       # Print the error message.
      printf "${RED_COLOR}Error Code: $1${NO_COLOR}\n"  # Print the error code.
      exit $1
   fi
}


######################################################################################################
########################################   Begin the script   ########################################
######################################################################################################


# Check if this script is ran as root. (It should not be ran as root.)
if [[ $EUID == 0 ]]; then
   printf "Do NOT run this script as root! (Do not use 'sudo' in the command.)\n"
   exit 1
fi


# Even though this script should not be ran as root, it will occasionally need root privileges.
# Non-Raspbian operating systems will prompt user for sudo privilege here.
sudo ls &> /dev/null  # Dummy command just to get a prompt for the user's password for the sake of using sudo.


# Print welcome screen.
printf "\n ${BLUE_COLOR}Virtual Radar Server${NO_COLOR}\n"
printf " ${BLUE_COLOR}http://www.virtualradarserver.co.uk${NO_COLOR}\n\n"
printf "This script downloads & installs:\n"
printf "  * Virtual Radar Server\n"
printf "  * Mono (and VRS Mono fix)\n"
printf "  * Language Packs\n"
printf "  * Custom Content Plugin\n"
printf "  * Database Editor Plugin\n"
printf "  * Database Writer Plugin\n"
printf "  * Tile Server Cache Plugin\n"
printf "  * Web Admin Plugin\n\n"
printf "Need help with this installation script?:\n"
printf "https://github.com/mypiaware/virtual-radar-server-installation\n\n";


# Prompt user if the following sample files should be downloaded:  Operator Flags, Silhouettes, sample Pictures and a database file.
while ! [[ $DL_OPF =~ ^[YyNn]$ ]]; do printf "Download & install operator flags (airline logos)? [yn]: "; read DL_OPF; done
while ! [[ $DL_SIL =~ ^[YyNn]$ ]]; do printf "Download & install silhouettes? [yn]: ";    read DL_SIL; done
while ! [[ $DL_PIC =~ ^[YyNn]$ ]]; do printf "Download & install pictures? [yn]: ";       read DL_PIC; done
# For safety reasons, prevent any possible existing database file from getting overwritten by an possibly older database file.  It is assumed that an existing database should not be overwritten.
if [[ ! -f "$DATABASEFILE" ]]; then
   while ! [[ $DL_DB =~ ^[YyNn]$ ]]; do printf "Download & install a sample database? [yn]: "; read DL_DB; done
fi
printf "\n"


# Prompt user for a port number VRS should use.
printf "Enter a port number for the Virtual Radar Server to use.\n"
printf "(Press [ENTER] to accept the default value of %s.)\n" $DEFAULTPORT
printf "  Port Number [%s]: " $DEFAULTPORT; read VRSPORT;
until [[ $VRSPORT == "" || ( $VRSPORT =~ ^\s*([1-9][0-9]{1,4})\s*$ && $VRSPORT -le 65535 ) ]]; do printf "  Port Number [%s]: " $DEFAULTPORT; read -r VRSPORT; done
VRSPORT=${BASH_REMATCH[1]}
if [[ $VRSPORT == "" ]]; then VRSPORT=$DEFAULTPORT; fi
printf "\nPort Number Selected: ${ORANGE_COLOR}%s${NO_COLOR}\n\n" $VRSPORT


# Offer a choice for localization of the VRS webpages.
printf "Select the default language to be displayed in the VRS webpages:\n\n"
PS3='Please choose your language of preference: '
LOCALE_CHOICES=("Chinese (China)" "English (Australia)" "English (Belize)" "English (Canada)" "English (Caribbean)" "English (India)"
"English (Ireland)" "English (Jamaica)" "English (Malaysia)" "English (New Zealand)" "English (Singapore)" "English (South Africa)"
"English (Trinidad and Tobago)" "English (United Kingdom)" "English (United States)" "French (Belgium)" "French (Canada)" "French (France)"
"French (Luxembourg)" "French (Monaco)" "French (Switzerland)" "German (Germany)" "Portuguese (Brazil)" "Russian (Russia)")
select LANG_COUNTRY in "${LOCALE_CHOICES[@]}"
do
   case $LANG_COUNTRY in
      "Chinese (China)")               LOCALIZATION="zh-CN";  break;;
      "English (Australia)")           LOCALIZATION="en-AU";  break;;
      "English (Belize)")              LOCALIZATION="en-BZ";  break;;
      "English (Canada)")              LOCALIZATION="en-CA";  break;;
      "English (Caribbean)")           LOCALIZATION="en-029"; break;;
      "English (India)")               LOCALIZATION="en-IN";  break;;
      "English (Ireland)")             LOCALIZATION="en-IE";  break;;
      "English (Jamaica)")             LOCALIZATION="en-JM";  break;;
      "English (Malaysia)")            LOCALIZATION="en-MY";  break;;
      "English (New Zealand)")         LOCALIZATION="en-NZ";  break;;
      "English (Singapore)")           LOCALIZATION="en-SG";  break;;
      "English (South Africa)")        LOCALIZATION="en-ZA";  break;;
      "English (Trinidad and Tobago)") LOCALIZATION="en-TT";  break;;
      "English (United Kingdom)")      LOCALIZATION="en-GB";  break;;
      "English (United States)")       LOCALIZATION="en-US";  break;;
      "French (Belgium)")              LOCALIZATION="fr-BE";  break;;
      "French (Canada)")               LOCALIZATION="fr-CA";  break;;
      "French (France)")               LOCALIZATION="fr-FR";  break;;
      "French (Luxembourg)")           LOCALIZATION="fr-LU";  break;;
      "French (Monaco)")               LOCALIZATION="fr-MC";  break;;
      "French (Switzerland)")          LOCALIZATION="fr-CH";  break;;
      "German (Germany)")              LOCALIZATION="de-DE";  break;;
      "Portuguese (Brazil)")           LOCALIZATION="pt-BR";  break;;
      "Russian (Russia)")              LOCALIZATION="ru-RU";  break;;
   esac
done
printf "\nLocalization has been set to:  ${ORANGE_COLOR}%s${NO_COLOR}\n\n" "$LANG_COUNTRY"


# Add option for user to enter longitude & latitude coordinates of the center of the VRS webpage map.
printf "OPTIONAL: Enter longitude and latitude coordinates of the center of the map.\n"
while ! [[ $ENTER_GPS =~ ^[YyNn]$ ]]; do printf "Do you wish to enter coordinates? [yn]: "; read ENTER_GPS; done
if [[ $ENTER_GPS =~ [Yy] ]]; then
   while ! [[ $COORDINATE_LON =~ ^\s*(([-+]?180(\.0*)?))\s*$ || $COORDINATE_LON =~ ^\s*([-+]?(1?[0-7]?|[89]?)?[0-9]{1}(\.[0-9]*)?)\s*$ ]]; do printf "  Enter Longitude [-180.0 to +180.0]: "; read COORDINATE_LON; done
   COORDINATE_LON=${BASH_REMATCH[1]}
   if [[ $COORDINATE_LON =~ \.$ ]];    then COORDINATE_LON="${COORDINATE_LON}0";  fi  # Any number ending with a decimal should have a '0' appended to it.
   if ! [[ $COORDINATE_LON =~ \. ]];   then COORDINATE_LON="${COORDINATE_LON}.0"; fi  # Any number without a decimal should have a '.0' appended to it.
   if [[ $COORDINATE_LON =~ ^[0-9] ]]; then COORDINATE_LON="+${COORDINATE_LON}";  fi  # Just for the sake of temporarily printing a '+' in front of a positive number to the screen.
   while ! [[ $COORDINATE_LAT =~ ^\s*([-+]?90(\.0*)?)\s*$ || $COORDINATE_LAT =~ ^\s*([-+]?[0-8]?[0-9]{1}(\.[0-9]*)?)\s*$ ]]; do printf "  Enter Latitude  [ -90.0 to +90.0 ]: "; read COORDINATE_LAT; done
   COORDINATE_LAT=${BASH_REMATCH[1]}
   if [[ $COORDINATE_LAT =~ \.$ ]];    then COORDINATE_LAT="${COORDINATE_LAT}0";  fi  # Any number ending with a decimal should have a '0' appended to it.
   if ! [[ $COORDINATE_LAT =~ \. ]];   then COORDINATE_LAT="${COORDINATE_LAT}.0"; fi  # Any number without a decimal should have a '.0' appended to it.
   if [[ $COORDINATE_LAT =~ ^[0-9] ]]; then COORDINATE_LAT="+${COORDINATE_LAT}";  fi  # Just for the sake of temporarily printing a '+' in front of a positive number to the screen.
   # The following is just for the purpose of lining up the decimal points when printed to the screen.
   LONDEC="$(echo "$COORDINATE_LON" | grep -aob '\.' | grep -oE '[0-9]+')"
   LATDEC="$(echo "$COORDINATE_LAT" | grep -aob '\.' | grep -oE '[0-9]+')"
   if [[ $LONDEC -gt $LATDEC ]]; then
      NUMSPACES="$(($LONDEC-$LATDEC))"
      PADDEDSPACES=$(printf '%0.s ' $(seq 1 $NUMSPACES))
      COORDINATE_LAT=$PADDEDSPACES$COORDINATE_LAT
   elif [[ $LATDEC -gt $LONDEC ]]; then
      NUMSPACES="$(($LATDEC-$LONDEC))"
      PADDEDSPACES=$(printf '%0.s ' $(seq 1 $NUMSPACES))
      COORDINATE_LON=$PADDEDSPACES$COORDINATE_LON
   fi
   printf "\n"
   printf "Longitude set to: ${ORANGE_COLOR}%s${NO_COLOR}\n" "$COORDINATE_LON"
   printf "Latitude set to:  ${ORANGE_COLOR}%s${NO_COLOR}\n" "$COORDINATE_LAT"
   if [[ $COORDINATE_LON =~ ^[+]?(.+) ]]; then COORDINATE_LON=${BASH_REMATCH[1]}; fi  # Remove any '+' at the beginning because VRS does not accept the '+' symbol.
   if [[ $COORDINATE_LAT =~ ^[+]?(.+) ]]; then COORDINATE_LAT=${BASH_REMATCH[1]}; fi  # Remove any '+' at the beginning because VRS does not accept the '+' symbol.
fi
printf "\n"


# Add option for user to enter a receiver.
printf "OPTIONAL: Enter receiver information.\n"
while ! [[ $ENTER_RECEIVER =~ ^[YyNn]$ ]]; do printf "Do you wish to add a receiver? [yn]: "; read ENTER_RECEIVER; done
if [[ $ENTER_RECEIVER =~ [Yy] ]]; then
   shopt -s nocasematch  # Make REGEX case insensitive
   while true; do
      while ! [[ $RECEIVER_NAME_ENTRY =~ ^\s*(([^[:space:]]|[ ]){1,50})\s*$ ]]; do printf "  Enter Receiver Name: "; read RECEIVER_NAME_ENTRY; done
      if [[ -f "$CONFIGFILE" ]]; then
         CONFIGTEXT=$(<"$CONFIGFILE")
         if [[ $CONFIGTEXT =~ \<Receiver\>.*\<Name\>$RECEIVER_NAME_ENTRY\</Name\>.*\</Receiver\> ]]; then
            printf "${RED_COLOR}Receiver name already exists!${NO_COLOR}\n"
            RECEIVER_NAME_ENTRY=""
         else
            break;
         fi
      else
         break
      fi
   done
   shopt -u nocasematch  # Return REGEX case to sensitive
   printf "  Choose the type of data source:\n"
   printf "      1. AVR or Beast Raw Feed\n"
   printf "      2. BaseStation\n"
   printf "      3. Compressed VRS\n"
   printf "      4. Aircraft List (JSON)\n"
   printf "      5. Plane Finder Radar\n"
   printf "      6. SBS-3 Raw Feed\n"
   while ! [[ $RECEIVER_SOURCE_SELECTION =~ ^\s*([1-6])\s*$ ]]; do printf "    Enter Selection [1-6]: "; read RECEIVER_SOURCE_SELECTION; done
   RECEIVER_SOURCE_SELECTION=${BASH_REMATCH[1]}
   if [[ $RECEIVER_SOURCE_SELECTION == 1 ]]; then RECEIVER_SOURCE_ENTRY="AVR or Beast Raw Feed"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 2 ]]; then RECEIVER_SOURCE_ENTRY="BaseStation"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 3 ]]; then RECEIVER_SOURCE_ENTRY="Compressed VRS"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 4 ]]; then RECEIVER_SOURCE_ENTRY="Aircraft List (JSON)"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 5 ]]; then RECEIVER_SOURCE_ENTRY="Plane Finder Radar"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 6 ]]; then RECEIVER_SOURCE_ENTRY="SBS-3 Raw Feed"; fi
   while true; do
      while ! [[ $RECEIVER_ADDRESS_ENTRY =~ ^\s*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\s*$ ]]; do printf "  Enter Receiver IP Address: "; read RECEIVER_ADDRESS_ENTRY; done
      RECEIVER_ADDRESS_ENTRY=${BASH_REMATCH[1]}
      while ! [[ $RECEIVER_PORT_ENTRY =~ ^\s*([1-9][0-9]{1,4})\s*$ && $RECEIVER_PORT_ENTRY -le 65535 ]]; do printf "  Enter Receiver IP Port: "; read RECEIVER_PORT_ENTRY; done
      RECEIVER_PORT_ENTRY=${BASH_REMATCH[1]}
      #  This is a little sloppy because BASH REGEX can only be greedy!  But, this *should* be good enough assuming there will always be an 'Address' & 'Port' entry in this order for every receiver.
      if [[ $CONFIGTEXT =~ \<Receiver\>.*\<Address\>$RECEIVER_ADDRESS_ENTRY\</Address\>[[:space:]]*\<Port\>$RECEIVER_PORT_ENTRY\</Port\>.*\</Receiver\> ]]; then
         printf "${RED_COLOR}A receiver is already configured to use: $RECEIVER_ADDRESS_ENTRY:$RECEIVER_PORT_ENTRY${NO_COLOR}\n"
         RECEIVER_ADDRESS_ENTRY=""
         RECEIVER_PORT_ENTRY=""
      else
         break;
      fi
   done
   printf "\n"
   printf "Receiver name:         ${ORANGE_COLOR}%s${NO_COLOR}\n" "$RECEIVER_NAME_ENTRY"
   printf "Receiver source type:  ${ORANGE_COLOR}%s${NO_COLOR}\n" "$RECEIVER_SOURCE_ENTRY"
   printf "Receiver IP:           ${ORANGE_COLOR}%s${NO_COLOR}\n" "$RECEIVER_ADDRESS_ENTRY"
   printf "Receiver port:         ${ORANGE_COLOR}%s${NO_COLOR}\n" "$RECEIVER_PORT_ENTRY"
   # The "Configuration.xml" file will need the source type entered as such:
   if [[ $RECEIVER_SOURCE_SELECTION == 1 ]]; then RECEIVER_SOURCE_ENTRY="Beast"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 2 ]]; then RECEIVER_SOURCE_ENTRY="Port30003"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 3 ]]; then RECEIVER_SOURCE_ENTRY="CompressedVRS"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 4 ]]; then RECEIVER_SOURCE_ENTRY="AircraftListJson"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 5 ]]; then RECEIVER_SOURCE_ENTRY="PlaneFinder"; fi
   if [[ $RECEIVER_SOURCE_SELECTION == 6 ]]; then RECEIVER_SOURCE_ENTRY="Sbs3"; fi
fi
printf "\n"


# User only needs to press [Enter] key to start the VRS installation.
printf "No more user input necessary.\n"
printf "${GREEN_COLOR}Press [ENTER] to begin the VRS installation...${NO_COLOR}"; read -p ""
printf "\n"


#############################################################################################
#############################  Installation of VRS begins here  #############################
#############################################################################################


# VRS installation begins with the installation of Mono.
if ! which mono >/dev/null 2>&1; then
   if which apt-get >/dev/null 2>&1; then  # Install on Raspberry Pi OS (Raspbian) or Ubuntu.
      sudo apt-get update
      sudo apt-get -y install mono-complete
   elif which dnf >/dev/null 2>&1; then    # Install on Fedora.
      sudo dnf -y install mono-complete
   fi
fi


# Good time to make sure directories of interest are present (create if not already present).
for NEWDIRECTORY in "${VRSDIRECTORIES[@]}"; do
   if [ ! -d "$NEWDIRECTORY" ]; then mkdir -p "$NEWDIRECTORY"; fi;  ERROREXIT 10 "Failed to create $NEWDIRECTORY!"
done


# Download/extract files from the VRS website to install VRS and the VRS plugins.
for URL in "${VRSFILES[@]}"; do
   REGEX="\/([^/]*)$"
   [[ $URL =~ $REGEX ]]
   FILENAME=${BASH_REMATCH[1]}
   if [ ! -f "$TEMPDIR/$FILENAME" ]; then wget -P "$TEMPDIR" "$URL"; fi;  ERROREXIT 11 "Failed to download $FILENAME!"
   tar -xf "$TEMPDIR/$FILENAME" -C "$VRSINSTALLDIRECTORY";                ERROREXIT 12 "Failed to untar $FILENAME!"
done


# Function to download & extract addon files (operator flags, silhouettes, pictures, sample database file).
function UNPACK {
   local ID="$1"
   local URL="$2"
   local DIRECTORYPATH="$3"

   # Download and extract files to the appropriate directory.
   local REGEX="\/([^/]*)$"
   [[ $URL =~ $REGEX ]]
   local FILENAME=${BASH_REMATCH[1]}
   if [ ! -f "$TEMPDIR/$FILENAME" ]; then wget -P "$TEMPDIR" "$URL"; fi
   if [ $? -ne 0 ]; then printf "Failed to download %s!\n" "$FILENAME"; printf "${RED_COLOR}Press [ENTER] to continue with the VRS installation...${NO_COLOR}"; read -p ""
   else
      if [ $ID == "OperatorFlagsFolder" ]; then
         unzip -j -o -qq "$TEMPDIR/$FILENAME" "[A-Z][A-Z][A-Z].bmp" -d "$DIRECTORYPATH";  ERROREXIT 13 "Failed to unzip $FILENAME!"  # The "*.bmp" may need to be changed if a different compressed file is used.
      fi
      if [ $ID == "SilhouettesFolder" ]; then
         unzip -j -o -qq "$TEMPDIR/$FILENAME" "*.bmp" -d "$DIRECTORYPATH";  ERROREXIT 14 "Failed to unzip $FILENAME!"  # The "*.bmp" may need to be changed if a different compressed file is used.
      fi
      if [ $ID == "Pictures" ]; then
         unzip -j -o -qq "$TEMPDIR/$FILENAME" "*.*" -d "$DIRECTORYPATH";    ERROREXIT 15 "Failed to unzip $FILENAME!"
      fi
      if [ $ID == "DatabaseFileName" ]; then
         mv "$TEMPDIR/BaseStation.sqb" "$DIRECTORYPATH/$DATABASEFILENAME";  ERROREXIT 16 "Failed to move $FILENAME!"   # Be sure the downloaded file's name is actually "BaseStation.sqb".
         printf "\n"
      fi
   fi
}


# Download & extract addon files (operator flags, silhouettes, pictures, sample database file).
if [[ $DL_OPF =~ [Yy] ]]; then UNPACK "OperatorFlagsFolder" "$OPFLAGSURL"      "$OPFLAGSDIRECTORY";     fi
if [[ $DL_SIL =~ [Yy] ]]; then UNPACK "SilhouettesFolder"   "$SILHOUETTESURL"  "$SILHOUETTESDIRECTORY"; fi
if [[ $DL_PIC =~ [Yy] ]]; then UNPACK "Pictures"            "$PICTURESURL"     "$PICTURESDIRECTORY";    fi
if [[ $DL_DB  =~ [Yy] ]]; then UNPACK "DatabaseFileName"    "$DATABASEURL"     "$DATABASEDIRECTORY";    fi


# Create an initial "Configuration.xml" file (if not already existing).
if ! [ -f "$CONFIGFILE" ]; then
   touch "$CONFIGFILE";                                                                                                                             ERROREXIT 17 "Failed to create $CONFIGFILE!"
   echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"                                                                              > "$CONFIGFILE";  ERROREXIT 18 "Failed to edit $CONFIGFILE!"
   echo "<Configuration xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">" >> "$CONFIGFILE";
   echo "  <BaseStationSettings>"                                                                                                >> "$CONFIGFILE";
   echo "  </BaseStationSettings>"                                                                                               >> "$CONFIGFILE";
   echo "  <GoogleMapSettings>"                                                                                                  >> "$CONFIGFILE";
   echo "    <WebSiteReceiverId>1</WebSiteReceiverId>"                                                                           >> "$CONFIGFILE";
   echo "    <ClosestAircraftReceiverId>1</ClosestAircraftReceiverId>"                                                           >> "$CONFIGFILE";
   echo "    <FlightSimulatorXReceiverId>1</FlightSimulatorXReceiverId>"                                                         >> "$CONFIGFILE";
   echo "  </GoogleMapSettings>"                                                                                                 >> "$CONFIGFILE";
   echo "  <Receivers>"                                                                                                          >> "$CONFIGFILE";
   echo "  </Receivers>"                                                                                                         >> "$CONFIGFILE";
   echo "</Configuration>"                                                                                                       >> "$CONFIGFILE";
fi


# Function to fill in the directory/file paths in the initial "Configuration.xml" file created above (operator flags, silhouettes, pictures, sample database file).
function EDITCONFIGFILE {
   local ID="$1"
   local DIRECTORYPATH="$2"
   if grep -q "<$ID>.*</$ID>" "$CONFIGFILE"; then  # If ID already existing, modify its value.
      sed -i "s|<$ID>.*</$ID>|<$ID>$DIRECTORYPATH</$ID>|" "$CONFIGFILE";                                     ERROREXIT 19 "Failed to edit $CONFIGFILE!"
   else  # If ID not already existing, create it with the appropriate value.
      sed -i "s|<BaseStationSettings>|<BaseStationSettings>\n    <$ID>$DIRECTORYPATH</$ID>|" "$CONFIGFILE";  ERROREXIT 20 "Failed to edit $CONFIGFILE!"
   fi
}


# Fill in the paths in the "Configuration.xml" file for the addon directories/files (operator flags, silhouettes, pictures, sample database file).
EDITCONFIGFILE "PicturesFolder"      "$PICTURESDIRECTORY"
EDITCONFIGFILE "SilhouettesFolder"   "$SILHOUETTESDIRECTORY"
EDITCONFIGFILE "OperatorFlagsFolder" "$OPFLAGSDIRECTORY"
EDITCONFIGFILE "DatabaseFileName"    "$DATABASEFILE"


# If user has entered location coordinates then set these coordinate values in the "Configuration.xml" file.
if [[ $ENTER_GPS =~ [Yy] ]]; then
   # Set longitude.
   if grep -q "<InitialMapLongitude>.*</InitialMapLongitude>" "$CONFIGFILE"; then  # If InitialMapLongitude already existing, modify its value.
      sed -i "s|<InitialMapLongitude>.*</InitialMapLongitude>|<InitialMapLongitude>$COORDINATE_LON</InitialMapLongitude>|" "$CONFIGFILE"; ERROREXIT 21 "Failed to edit $CONFIGFILE!"
   else  # If InitialMapLongitude is not already existing, create it with the appropriate value.
      sed -i "s|<GoogleMapSettings>|<GoogleMapSettings>\n    <InitialMapLongitude>$COORDINATE_LON</InitialMapLongitude>|" "$CONFIGFILE";  ERROREXIT 22 "Failed to edit $CONFIGFILE!"
   fi
   # Set latitude.
   if grep -q "<InitialMapLatitude>.*</InitialMapLatitude>" "$CONFIGFILE"; then  # If InitialMapLatitude already existing, modify its value.
      sed -i "s|<InitialMapLatitude>.*</InitialMapLatitude>|<InitialMapLatitude>$COORDINATE_LAT</InitialMapLatitude>|" "$CONFIGFILE";     ERROREXIT 23 "Failed to edit $CONFIGFILE!"
   else  # If InitialMapLatitude is not already existing, create it with the appropriate value.
      sed -i "s|<GoogleMapSettings>|<GoogleMapSettings>\n    <InitialMapLatitude>$COORDINATE_LAT</InitialMapLatitude>|" "$CONFIGFILE";    ERROREXIT 24 "Failed to edit $CONFIGFILE!"
   fi
fi


# If user has chosen to enter a receiver, then create the receiver.
if [[ $ENTER_RECEIVER =~ [Yy] ]]; then
   CONFIGTEXT=$(<"$CONFIGFILE")
   # If a receiver has already been entered, then find the next largest 'UniqueId' to assign to this new receiver.
   if grep -q "<Receiver>" "$CONFIGFILE"; then
      if [[ $CONFIGTEXT =~ (\<Receivers\>.*\</Receivers\>) ]]; then
         OIFS="$IFS"
         IFS=$'\n' read -a RECEIVERS_ARRAY -d '' <<< "${BASH_REMATCH[1]}"
         IFS="$OIFS"
      fi
      RECEIVERIDS=()  # Array to hold all of the current 'UniqueID's.
      for i in "${RECEIVERS_ARRAY[@]}"; do
         if [[ $i =~ \<UniqueId\>([0-9]+)\</UniqueId\> ]]; then
            RECEIVERIDS+=(${BASH_REMATCH[1]})
         fi
      done
      MAX=${RECEIVERIDS[0]}
      for N in "${RECEIVERIDS[@]}" ; do ((N > MAX)) && MAX=$N; done
      ((MAX++))
      RECEIVER_UNIQUEID=$MAX  # This is the next largest 'UniqueId'.
   else
      RECEIVER_UNIQUEID=1
   fi
   # Enter the receiver settings.
   RECEIVER_SETTINGS=" \
     <Enabled>true</Enabled>\n \
     <UniqueId>$RECEIVER_UNIQUEID</UniqueId>\n \
     <Name>$RECEIVER_NAME_ENTRY</Name>\n \
     <DataSource>$RECEIVER_SOURCE_ENTRY</DataSource>\n \
     <Address>$RECEIVER_ADDRESS_ENTRY</Address>\n \
     <Port>$RECEIVER_PORT_ENTRY</Port>\n"
   sed -i "s|<Receivers>|<Receivers>\n    <Receiver>\n$RECEIVER_SETTINGS    </Receiver>|" "$CONFIGFILE";                                                              ERROREXIT 25 "Failed to edit $CONFIGFILE!"
   # Set three global receiver settings if not already set.
   sed -i "s|<WebSiteReceiverId>.*</WebSiteReceiverId>|<WebSiteReceiverId>$RECEIVER_UNIQUEID</WebSiteReceiverId>|" "$CONFIGFILE";                                     ERROREXIT 26 "Failed to edit $CONFIGFILE!"
   sed -i "s|<ClosestAircraftReceiverId>.*</ClosestAircraftReceiverId>|<ClosestAircraftReceiverId>$RECEIVER_UNIQUEID</ClosestAircraftReceiverId>|" "$CONFIGFILE";     ERROREXIT 27 "Failed to edit $CONFIGFILE!"
   sed -i "s|<FlightSimulatorXReceiverId>.*</FlightSimulatorXReceiverId>|<FlightSimulatorXReceiverId>$RECEIVER_UNIQUEID</FlightSimulatorXReceiverId>|" "$CONFIGFILE"; ERROREXIT 28 "Failed to edit $CONFIGFILE!"
fi


# Create a file to allow for a different port to be used by the VRS.
touch "$SHAREDIRECTORY/$INSTALLERCONFIGFILENAME";                                                                                                                                ERROREXIT 29 "Failed to create $INSTALLERCONFIGFILENAME!"
echo "<?xml version=\"1.0\" encoding=\"utf-8\" ?>"                                                                                 > "$SHAREDIRECTORY/$INSTALLERCONFIGFILENAME"; ERROREXIT 30 "Failed to edit $INSTALLERCONFIGFILENAME!"
echo "<InstallerSettings xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">" >> "$SHAREDIRECTORY/$INSTALLERCONFIGFILENAME";
echo "    <WebServerPort>$VRSPORT</WebServerPort>"                                                                                >> "$SHAREDIRECTORY/$INSTALLERCONFIGFILENAME";
echo "</InstallerSettings>"                                                                                                       >> "$SHAREDIRECTORY/$INSTALLERCONFIGFILENAME";


# Create an HTML file and an accompanying readme file to create messages that may appear at the top of the website.
if ! [ -f "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME" ]; then
   touch "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";                                                       ERROREXIT 31 "Failed to create $ANNOUNCEMENTFILENAME!"
   echo '<!--'                                              > "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";  ERROREXIT 32 "Failed to edit $ANNOUNCEMENTFILENAME!"
   echo "<div style=\""                                    >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "   color: red;"                                   >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "   text-align: center;"                           >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "   font-weight: bold;"                            >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "   font-size: 1em"                                >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "\">"                                              >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "This text will be at the top of the VRS website!" >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "</div>"                                           >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
   echo "-->"                                              >> "$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME";
fi
if ! [ -f "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME" ]; then
   touch "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";                                                                                                         ERROREXIT 33 "Failed to create $READMEFILENAME!"
   echo "Any text in the \"$ANNOUNCEMENTFILENAME\" file will be placed at the very top of the VRS web page."  > "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";  ERROREXIT 34 "Failed to edit $READMEFILENAME!"
   echo "The text could be used to provide the website visitors an announcement."                            >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo "This text will be at the top of both the desktop and mobile version of the website."                >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo ""                                                                                                   >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo "For example, the following text could be placed at the top:"                                        >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo "\"Server will perform a reboot at 12:00am (UTC).\""                                                 >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo ""                                                                                                   >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo "Because this is an HTML file, standard HTML tags may be used with the text."                        >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo "For example, the following usage of HTML tags will help enhance this text:"                         >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
   echo "<b><font color=\"red\">This text is both bold and in a red color!</font></b>"                       >> "$CUSTOMINJECTEDFILESDIRECTORY/$READMEFILENAME";
fi


# Enable & configure the Custom Content Plugin to find the ANNOUNCEMENTFILENAME file to inject into 'desktop.html' and 'mobile.html' VRS files.
# Enable & configure the Custom Content Plugin to look in the CUSTOMWEBFILESDIRECTORY directory for any custom web files.
INJECTIONFILEPATHNAME="$CUSTOMINJECTEDFILESDIRECTORY/$ANNOUNCEMENTFILENAME"
INJECTIONFILE="${INJECTIONFILEPATHNAME//\//%2f}";           ERROREXIT 35 "Failed to create the $INJECTIONFILE variable!"    # Replace '/' with '%2f' HTML character code.
INJECTIONFOLDER="${CUSTOMINJECTEDFILESDIRECTORY//\//%2f}";  ERROREXIT 36 "Failed to create the $INJECTIONFOLDER variable!"  # Replace '/' with '%2f' HTML character code.
SITEROOTFOLDER="${CUSTOMWEBFILESDIRECTORY//\//%2f}";        ERROREXIT 37 "Failed to create the $SITEROOTFOLDER variable!"   # Replace '/' with '%2f' HTML character code.
CUSTOMCONTENTTEMPLATE="\
VirtualRadar.Plugin.CustomContent.Options=%3c%3fxml+version%3d%221.0%22%3f%3e%0a\
%3cOptions+xmlns%3axsd%3d%22http%3a%2f%2fwww.w3.org%2f2001%2fXMLSchema%22+xmlns%3axsi%3d%22http%3a%2f%2fwww.w3.org%2f2001%2fXMLSchema-instance%22%3e%0a\
++%3cDataVersion%3e0%3c%2fDataVersion%3e%0a\
++%3cEnabled%3etrue%3c%2fEnabled%3e%0a\
++%3cInjectSettings%3e%0a\
++++%3cInjectSettings%3e%0a\
++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a\
++++++%3cPathAndFile%3e%2fdesktop.html%3c%2fPathAndFile%3e%0a\
++++++%3cInjectionLocation%3eBody%3c%2fInjectionLocation%3e%0a\
++++++%3cStart%3etrue%3c%2fStart%3e%0a\
++++++%3cFile%3e${INJECTIONFILE}%3c%2fFile%3e%0a\
++++%3c%2fInjectSettings%3e%0a\
++++%3cInjectSettings%3e%0a\
++++++%3cEnabled%3etrue%3c%2fEnabled%3e%0a\
++++++%3cPathAndFile%3e%2fmobile.html%3c%2fPathAndFile%3e%0a\
++++++%3cInjectionLocation%3eBody%3c%2fInjectionLocation%3e%0a\
++++++%3cStart%3etrue%3c%2fStart%3e%0a\
++++++%3cFile%3e${INJECTIONFILE}%3c%2fFile%3e%0a\
++++%3c%2fInjectSettings%3e%0a\
++%3c%2fInjectSettings%3e%0a\
++%3cDefaultInjectionFilesFolder%3e${INJECTIONFOLDER}%3c%2fDefaultInjectionFilesFolder%3e%0a\
++%3cSiteRootFolder%3e${SITEROOTFOLDER}%3c%2fSiteRootFolder%3e%0a\
++%3cResourceImagesFolder+%2f%3e%0a\
%3c%2fOptions%3e";  ERROREXIT 38 "Failed to create the CUSTOMCONTENTTEMPLATE variable!"
if ! [ -f "$PLUGINSCONFIGFILE" ]; then
   touch "$PLUGINSCONFIGFILE";  ERROREXIT 39 "Failed to create $PLUGINSCONFIGFILE!"
fi
if ! grep -q "VirtualRadar.Plugin.CustomContent.Options" "$PLUGINSCONFIGFILE"; then  # If no CustomContent setting is present at all, then create the setting from scratch.
   echo -e "$CUSTOMCONTENTTEMPLATE" >> "$PLUGINSCONFIGFILE";  ERROREXIT 40 "Failed to edit $PLUGINSCONFIGFILE!"
else
   sed -i -r "s/VirtualRadar\.Plugin\.CustomContent\.Options.*/$CUSTOMCONTENTTEMPLATE/" "$PLUGINSCONFIGFILE";  ERROREXIT 41 "Failed to edit $PLUGINSCONFIGFILE!"
fi


# Configure the Tile Server Cache Plugin to use the TILECACHEDIRECTORY directory.
TILECACHEPATH="${TILECACHEDIRECTORY//\//%2f}";  ERROREXIT 42 "Failed to create the $TILECACHEPATH variable!"  # Replace '/' with '%2f' HTML character code.
TILECACHETEMPLATE="\
VirtualRadar.Plugin.TileServerCache.Options=%7b%22DataVersion%22%3a0%2c\
%22IsPluginEnabled%22%3afalse%2c\
%22IsOfflineModeEnabled%22%3afalse%2c\
%22CacheFolderOverride%22%3a%22${TILECACHEPATH}%22%2c\
%22UseDefaultCacheFolder%22%3afalse%2c\
%22TileServerTimeoutSeconds%22%3a30%2c\
%22CacheMapTiles%22%3atrue%2c\
%22CacheLayerTiles%22%3atrue%7d";  ERROREXIT 43 "Failed to create the TILECACHETEMPLATE variable!"
if ! [ -f "$PLUGINSCONFIGFILE" ]; then
   touch "$PLUGINSCONFIGFILE";  ERROREXIT 44 "Failed to create $PLUGINSCONFIGFILE!"
fi
if ! grep -q "VirtualRadar.Plugin.TileServerCache.Options" "$PLUGINSCONFIGFILE"; then  # If no Tile Server Cache Plugin setting is present at all, then create the setting from scratch.
   echo -e "$TILECACHETEMPLATE" >> "$PLUGINSCONFIGFILE";  ERROREXIT 45 "Failed to edit $PLUGINSCONFIGFILE!"
else
   sed -i -r "s/VirtualRadar\.Plugin\.TileServerCache\.Options.*/$TILECACHETEMPLATE/" "$PLUGINSCONFIGFILE";  ERROREXIT 46 "Failed to edit $PLUGINSCONFIGFILE!"
fi


# Change global localization from 'en-GB' to a custom default localization (for example: 'en-US') set by the user at the start of this script.
cp "$VRSINSTALLDIRECTORY/Web/desktop.html"       "$CUSTOMWEBFILESDIRECTORY";            ERROREXIT 47 "Failed to copy $VRSINSTALLDIRECTORY/Web/desktop.html!"
cp "$VRSINSTALLDIRECTORY/Web/desktopReport.html" "$CUSTOMWEBFILESDIRECTORY";            ERROREXIT 48 "Failed to copy $VRSINSTALLDIRECTORY/Web/desktopReport.html!"
cp "$VRSINSTALLDIRECTORY/Web/mobile.html"        "$CUSTOMWEBFILESDIRECTORY";            ERROREXIT 49 "Failed to copy $VRSINSTALLDIRECTORY/Web//mobile.html!"
cp "$VRSINSTALLDIRECTORY/Web/mobileReport.html"  "$CUSTOMWEBFILESDIRECTORY";            ERROREXIT 50 "Failed to copy $VRSINSTALLDIRECTORY/Web/mobileReport.html!"
cp "$VRSINSTALLDIRECTORY/Web/fsx.html"           "$CUSTOMWEBFILESDIRECTORY";            ERROREXIT 51 "Failed to copy $VRSINSTALLDIRECTORY/Web/fsx.html!"
sed -i -e "s/'en-GB'/'$LOCALIZATION'/g" "$CUSTOMWEBFILESDIRECTORY/desktop.html";        ERROREXIT 52 "Failed to edit $CUSTOMWEBFILESDIRECTORY/desktop.html!"
sed -i -e "s/'en-GB'/'$LOCALIZATION'/g" "$CUSTOMWEBFILESDIRECTORY/desktopReport.html";  ERROREXIT 53 "Failed to edit $CUSTOMWEBFILESDIRECTORY/desktopReport.html!"
sed -i -e "s/'en-GB'/'$LOCALIZATION'/g" "$CUSTOMWEBFILESDIRECTORY/mobile.html";         ERROREXIT 54 "Failed to edit $CUSTOMWEBFILESDIRECTORY/mobile.html!"
sed -i -e "s/'en-GB'/'$LOCALIZATION'/g" "$CUSTOMWEBFILESDIRECTORY/mobileReport.html";   ERROREXIT 55 "Failed to edit $CUSTOMWEBFILESDIRECTORY/mobileReport.html!"
sed -i -e "s/'en-GB'/'$LOCALIZATION'/g" "$CUSTOMWEBFILESDIRECTORY/fsx.html";            ERROREXIT 56 "Failed to edit $CUSTOMWEBFILESDIRECTORY/fsx.html!"


# Create a script to help backup the database file. (A cron job can later be set to automatically run the script at any time interval.)
touch "$DATABASEBACKUPSCRIPT";                                                                     ERROREXIT 57 "Failed to create $DATABASEBACKUPSCRIPT!"
echo "#!/bin/bash"                                                     > "$DATABASEBACKUPSCRIPT";  ERROREXIT 58 "Failed to edit $DATABASEBACKUPSCRIPT!"
echo "# Use this script to routinely backup the VRS database file.\n" >> "$DATABASEBACKUPSCRIPT";
echo "mkdir -p \"$DATABASEBACKUPDIRECTORY\""                          >> "$DATABASEBACKUPSCRIPT";
echo "cp \"$DATABASEFILE\" \"$DATABASEBACKUPFILE\""                   >> "$DATABASEBACKUPSCRIPT";
echo "exit"                                                           >> "$DATABASEBACKUPSCRIPT";


# Create service file to run VRS in the background.
sudo touch $SERVICEFILE;        ERROREXIT 59 "Failed to create $SERVICEFILE!"
sudo chmod 777 "$SERVICEFILE";  ERROREXIT 60 "The 'chmod' command failed on $SERVICEFILE!"
echo "[Unit]"                                                            > "$SERVICEFILE";  ERROREXIT 61 "Failed to edit $SERVICEFILE!"
echo "Description=VRS background process"                               >> "$SERVICEFILE";
echo ""                                                                 >> "$SERVICEFILE";
echo "[Service]"                                                        >> "$SERVICEFILE";
echo "User=$USER"                                                       >> "$SERVICEFILE";
echo "ExecStart=mono \"$VRSINSTALLDIRECTORY/VirtualRadar.exe\" -nogui"  >> "$SERVICEFILE";
echo ""                                                                 >> "$SERVICEFILE";
echo "[Install]"                                                        >> "$SERVICEFILE";
echo "WantedBy=multi-user.target"                                       >> "$SERVICEFILE";
sudo chmod 755 "$SERVICEFILE";        ERROREXIT 62 "The 'chmod' command failed on $SERVICEFILE!"
sudo chown root:root "$SERVICEFILE";  ERROREXIT 63 "The 'chown' command failed on $SERVICEFILE!"
sudo systemctl daemon-reload;         ERROREXIT 64 "The 'systemctl daemon-reload' command failed"


# Find largest length of the VRS command parameters.
VRSCMD_GUI_LEN=${#VRSCMD_GUI}
VRSCMD_NOGUI_LEN=${#VRSCMD_NOGUI}
VRSCMD_STARTPROCESS_LEN=${#VRSCMD_STARTPROCESS}
VRSCMD_STOPPROCESS_LEN=${#VRSCMD_STOPPROCESS}
VRSCMD_ENABLE_LEN=${#VRSCMD_ENABLE}
VRSCMD_DISABLE_LEN=${#VRSCMD_DISABLE}
VRSCMD_WEBADMIN_LEN=${#VRSCMD_WEBADMIN}
VRSCMD_LOG_LEN=${#VRSCMD_LOG}
if [[ $VRSCMD_GUI_LEN          -gt $VRSCMD_NOGUI_LEN ]]; then ARGLENGTH=${#VRSCMD_GUI}; else ARGLENGTH=${#VRSCMD_NOGUI}; fi
if [[ $VRSCMD_STARTPROCESS_LEN -gt $ARGLENGTH        ]]; then ARGLENGTH=${#VRSCMD_STARTPROCESS}; fi
if [[ $VRSCMD_STOPPROCESS_LEN  -gt $ARGLENGTH        ]]; then ARGLENGTH=${#VRSCMD_STOPPROCESS};  fi
if [[ $VRSCMD_ENABLE_LEN       -gt $ARGLENGTH        ]]; then ARGLENGTH=${#VRSCMD_ENABLE};       fi
if [[ $VRSCMD_DISABLE_LEN      -gt $ARGLENGTH        ]]; then ARGLENGTH=${#VRSCMD_DISABLE};      fi
if [[ $VRSCMD_WEBADMIN_LEN     -gt $ARGLENGTH        ]]; then ARGLENGTH=${#VRSCMD_WEBADMIN};     fi
if [[ $VRSCMD_LOG_LEN          -gt $ARGLENGTH        ]]; then ARGLENGTH=${#VRSCMD_LOG};     fi


# Create a universal command to start VRS.
if ! [ -f "$STARTCOMMAND" ]; then sudo touch "$STARTCOMMAND"; fi;  ERROREXIT 65 "Failed to create $STARTCOMMAND!"
sudo chmod 777 "$STARTCOMMAND";                                    ERROREXIT 66 "The 'chmod' command failed on  $STARTCOMMAND!"
echo "#!/bin/bash"                                                                                                                                              > "$STARTCOMMAND";  ERROREXIT 67 "Failed to edit $STARTCOMMAND!"
echo "# Use this script as a global command to start/stop VRS."                                                                                                >> "$STARTCOMMAND";
echo ""                                                                                                                                                        >> "$STARTCOMMAND";
echo "function COMMANDHELP {"                                                                                                                                  >> "$STARTCOMMAND";
echo "   printf \"Usage: vrs -parameter\n\""                                                                                                                   >> "$STARTCOMMAND";
echo "   printf -- \"Parameters:\n\""                                                                                                                          >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Start VRS with a GUI in a GUI desktop environment\n\" \"$VRSCMD_GUI\""                                                 >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Start VRS without a GUI\n\" \"$VRSCMD_NOGUI\""                                                                         >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Start VRS as a background service\n\" \"$VRSCMD_STARTPROCESS\""                                                        >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Stop VRS if running as a background service\n\" \"$VRSCMD_STOPPROCESS\""                                               >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Allow VRS to start at every system boot\n\" \"$VRSCMD_ENABLE\""                                                        >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Disable VRS from starting at every system boot\n\" \"$VRSCMD_DISABLE\""                                                >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Create username & password for Web Admin & also start VRS\n\" \"$VRSCMD_WEBADMIN\""                                    >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  View history log of VRS running as a background service\n\" \"$VRSCMD_LOG\""                                           >> "$STARTCOMMAND";
echo "   printf -- \" -%-${ARGLENGTH}s  Display this help menu\n\" \"?\""                                                                                      >> "$STARTCOMMAND";
echo "}"                                                                                                                                                       >> "$STARTCOMMAND";
echo ""                                                                                                                                                        >> "$STARTCOMMAND";
echo "if [[ \$# -eq 1 ]]; then"                                                                                                                                >> "$STARTCOMMAND";
echo "   if [[ \$1 == \"-h\" || \$1 == \"-help\" || \$1 == \"-?\" ]]; then COMMANDHELP; exit 0"                                                                >> "$STARTCOMMAND";
echo "   elif ! [[ \$1 == \"-$VRSCMD_GUI\" || \$1 == \"-$VRSCMD_NOGUI\" || \$1 == \"-$VRSCMD_STARTPROCESS\" || \$1 == \"-$VRSCMD_STOPPROCESS\" || \$1 == \"-$VRSCMD_ENABLE\" || \$1 == \"-$VRSCMD_DISABLE\" || \$1 == \"-$VRSCMD_WEBADMIN\" || \$1 == \"-$VRSCMD_LOG\" ]]; then" >> "$STARTCOMMAND";
echo "      printf \"Invalid parameter!\n\n\"; COMMANDHELP; exit 1"                                                                                            >> "$STARTCOMMAND";
echo "   elif [[ \$1 == \"-$VRSCMD_ENABLE\" ]]; then"                                                                                                          >> "$STARTCOMMAND";
echo "      sudo systemctl enable $SERVICEFILENAME.service >/dev/null 2>&1"                                                                                    >> "$STARTCOMMAND";
echo "      if [[ \$? -ne 0 ]]; then printf \"Error trying to enable VRS at boot!\n\"; exit 2"                                                                 >> "$STARTCOMMAND";
echo "      else                    printf \"VRS enabled to start at every system boot.\n\"; fi"                                                               >> "$STARTCOMMAND";
echo "   elif [[ \$1 == \"-$VRSCMD_DISABLE\" ]]; then"                                                                                                         >> "$STARTCOMMAND";
echo "      sudo systemctl disable $SERVICEFILENAME.service >/dev/null 2>&1"                                                                                   >> "$STARTCOMMAND";
echo "      if [[ \$? -ne 0 ]]; then printf \"Error trying to disable VRS at boot!\n\"; exit 3"                                                                >> "$STARTCOMMAND";
echo "      else                    printf \"VRS disabled from starting at every system boot.\n\"; fi"                                                         >> "$STARTCOMMAND";
echo "   elif [[ \$1 == \"-$VRSCMD_STOPPROCESS\" ]]; then"                                                                                                     >> "$STARTCOMMAND";
echo "      sudo systemctl stop $SERVICEFILENAME.service"                                                                                                      >> "$STARTCOMMAND";
echo "      if [[ \$? -ne 0 ]]; then printf \"Error trying to stop VRS!\n\"; exit 4"                                                                           >> "$STARTCOMMAND";
echo "      else                    printf \"VRS has stopped.\n\"; fi"                                                                                         >> "$STARTCOMMAND";
echo "   elif [[ \$1 == \"-$VRSCMD_LOG\" ]]; then"                                                                                                             >> "$STARTCOMMAND";
echo "      journalctl -u $SERVICEFILENAME.service"                                                                                                            >> "$STARTCOMMAND";
echo "      if [[ \$? -ne 0 ]]; then printf \"Error trying to get log of VRS!\n\"; exit 5; fi"                                                                 >> "$STARTCOMMAND";
echo "   elif ! pgrep -f VirtualRadar.exe >/dev/null; then"                                                                                                    >> "$STARTCOMMAND";
echo "      if [[ \$1 == \"-$VRSCMD_GUI\" ]]; then"                                                                                                            >> "$STARTCOMMAND";
echo "         mono \"$VRSINSTALLDIRECTORY/VirtualRadar.exe\""                                                                                                 >> "$STARTCOMMAND";
echo "      elif [[ \$1 == \"-$VRSCMD_NOGUI\" ]]; then"                                                                                                        >> "$STARTCOMMAND";
echo "         mono \"$VRSINSTALLDIRECTORY/VirtualRadar.exe\" -nogui"                                                                                          >> "$STARTCOMMAND";
echo "      elif [[ \$1 == \"-$VRSCMD_STARTPROCESS\" ]]; then"                                                                                                 >> "$STARTCOMMAND";
echo "         sudo systemctl restart $SERVICEFILENAME.service"                                                                                                >> "$STARTCOMMAND";
echo "         if [[ \$? -ne 0 ]]; then printf \"Error trying to start VRS!\n\"; exit 6"                                                                       >> "$STARTCOMMAND";
echo "         else                    printf \"VRS has started as a background process.\n\"; fi"                                                              >> "$STARTCOMMAND";
echo "      elif [[ \$1 == \"-$VRSCMD_WEBADMIN\" ]]; then"                                                                                                     >> "$STARTCOMMAND";
echo "         while [[ \${#WAUSERNAME[@]} -ne 1 && WAUSERNAME[0] != \"\" ]]; do printf \"Create Web Admin username: \"; read -r -a WAUSERNAME; done"          >> "$STARTCOMMAND";
echo "         while [[ \${#WAPASSWORD[@]} -ne 1 && WAPASSWORD[0] != \"\" ]]; do printf \"Create Web Admin password: \"; read -r -a WAPASSWORD; done"          >> "$STARTCOMMAND";
echo "         printf \"\nAccess the VRS Web Admin on a local device with this URL:\n   http://%s:%s/VirtualRadar/WebAdmin/Index.html\n\n\" $LOCALIP $VRSPORT" >> "$STARTCOMMAND";
echo "         mono \"$VRSINSTALLDIRECTORY/VirtualRadar.exe\" -nogui -createAdmin:\$WAUSERNAME -password:\$WAPASSWORD"                                         >> "$STARTCOMMAND";
echo "      fi"                                                                                                                                                >> "$STARTCOMMAND";
echo "   elif pgrep -f VirtualRadar.exe >/dev/null; then"                                                                                                      >> "$STARTCOMMAND";
echo "      if [[ \$1 == \"-$VRSCMD_GUI\" || \$1 == \"-$VRSCMD_NOGUI\" || \$1 == \"-$VRSCMD_STARTPROCESS\" || \$1 == \"-$VRSCMD_WEBADMIN\" ]]; then"           >> "$STARTCOMMAND";
echo "         printf \"VRS is already running!\n\" COMMANDHELP; exit 7"                                                                                       >> "$STARTCOMMAND";
echo "      fi"                                                                                                                                                >> "$STARTCOMMAND";
echo "   else printf \"Unknown error occurred! EXIT CODE: 8\n\"; exit 8"                                                                                       >> "$STARTCOMMAND";
echo "   fi"                                                                                                                                                   >> "$STARTCOMMAND";
echo "elif [[ \$# -ge 1 ]]; then"                                                                                                                              >> "$STARTCOMMAND";
echo "   printf \"Too many parameters!\n\n\"; COMMANDHELP; exit 9"                                                                                             >> "$STARTCOMMAND";
echo "elif [[ \$# -eq 0 ]]; then"                                                                                                                              >> "$STARTCOMMAND";
echo "   printf \"Status: \";"                                                                                                                                 >> "$STARTCOMMAND";
echo "   if pgrep -f VirtualRadar.exe >/dev/null; then"                                                                                                        >> "$STARTCOMMAND";
echo "      printf \"VRS is running.\n\n\""                                                                                                                    >> "$STARTCOMMAND";
echo "   else"                                                                                                                                                 >> "$STARTCOMMAND";
echo "      printf \"VRS is not running.\n\n\""                                                                                                                >> "$STARTCOMMAND";
echo "   fi"                                                                                                                                                   >> "$STARTCOMMAND";
echo "   COMMANDHELP; exit 0"                                                                                                                                  >> "$STARTCOMMAND";
echo "else printf \"Unknown error occurred! EXIT CODE: 10\n\"; exit 10"                                                                                        >> "$STARTCOMMAND";
echo "fi"                                                                                                                                                      >> "$STARTCOMMAND";
echo ""                                                                                                                                                        >> "$STARTCOMMAND";
echo "exit 0"                                                                                                                                                  >> "$STARTCOMMAND";
sudo chmod 755 "$STARTCOMMAND";        ERROREXIT 68 "The 'chmod' command failed on  $STARTCOMMAND!"
sudo chown root:root "$STARTCOMMAND";  ERROREXIT 69 "The 'chown' command failed on  $STARTCOMMAND!"


######################################################################################################
###################################   Print helpful instructions   ###################################
######################################################################################################


printf "\n\n"
printf "${GREEN_COLOR}%s${NO_COLOR}\n"  "-----------------------"
printf "${GREEN_COLOR}HELPFUL THINGS TO KNOW:${NO_COLOR}\n"
printf "${GREEN_COLOR}%s${NO_COLOR}\n\n" "-----------------------"

printf "${ORANGE_COLOR}VRS was installed here:${NO_COLOR}  %s\n"
printf "   %s\n\n" "$VRSINSTALLDIRECTORY"

printf "${ORANGE_COLOR}All of VRS user custom files/directories may be found here:${NO_COLOR}\n"
printf "   %s\n"   "$SHAREDIRECTORY"
printf "   %s\n\n" "$EXTRASDIRECTORY"

if [ -f "$DATABASEBACKUPSCRIPT" ]; then
   printf "${ORANGE_COLOR}A cron job may be set to routinely backup the database file:${NO_COLOR}\n"
   printf "  Use this command to set up a cron job:   crontab -e\n"
   printf "  The cron job will then utilize this following command:\n"
   printf "    bash \"$DATABASEBACKUPSCRIPT\"\n\n"
   printf "${ORANGE_COLOR}The database backup file will be:${NO_COLOR}\n"
   printf "  %s\n\n" "$DATABASEBACKUPFILE"
fi

printf "${ORANGE_COLOR}To view the VRS map:${NO_COLOR}\n"
if [[ $DISPLAY == "" ]]; then
   printf "  View VRS on local network:  http://%s:%s/VirtualRadar\n\n" $LOCALIP $VRSPORT
else
   printf "  View VRS on this machine:   http://127.0.0.1:%s/VirtualRadar\n" $VRSPORT
   printf "  View VRS on local network:  http://%s:%s/VirtualRadar\n\n" $LOCALIP $VRSPORT
fi

printf "${ORANGE_COLOR}To access the optional Web Admin GUI on a local network device:${NO_COLOR}\n"
printf "  http://%s:%s/VirtualRadar/WebAdmin/Index.html\n\n" $LOCALIP $VRSPORT

printf "${ORANGE_COLOR}Use this command to start/stop VRS:${NO_COLOR}  %s\n" "$STARTCOMMANDFILENAME"
printf    "  The 'vrs' command must be used with one of the following parameters:\n"
printf -- "    -%-${ARGLENGTH}s  Start VRS with a GUI in a GUI desktop environment\n" "$VRSCMD_GUI"
printf -- "    -%-${ARGLENGTH}s  Start VRS without a GUI\n" "$VRSCMD_NOGUI"
printf -- "    -%-${ARGLENGTH}s  Start VRS as a background service\n" "$VRSCMD_STARTPROCESS"
printf -- "    -%-${ARGLENGTH}s  Stop VRS if running as a background service\n" "$VRSCMD_STOPPROCESS"
printf -- "    -%-${ARGLENGTH}s  Allow VRS to autorun at every system boot\n" "$VRSCMD_ENABLE"
printf -- "    -%-${ARGLENGTH}s  Disable VRS from autorunning at every system boot\n" "$VRSCMD_DISABLE"
printf -- "    -%-${ARGLENGTH}s  Create username & password for Web Admin & also start VRS\n" "$VRSCMD_WEBADMIN"
printf -- "    -%-${ARGLENGTH}s  View history log of VRS running as a background service\n" "$VRSCMD_LOG"
printf -- "    -%-${ARGLENGTH}s  Display the help menu\n\n" "?"

printf "${ORANGE_COLOR}More detailed information regarding this installation script here:${NO_COLOR}\n"
printf "  https://github.com/mypiaware/virtual-radar-server-installation/blob/master/README.md\n\n"

# Script ends with reminder of using the 'vrs' command.
printf "\n"
printf "${GREEN_COLOR}Virtual Radar Server installation is complete!${NO_COLOR}\n"
printf "\n"
printf "Press [ENTER] now to view the '${BOLD_FONT}vrs${NO_COLOR}' command options and exit..."; read -p ""
printf "\n\n"
eval "$STARTCOMMANDFILENAME" -?
printf "\n"

exit 0

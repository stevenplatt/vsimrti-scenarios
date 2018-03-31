#!/usr/bin/env bash
#
# ns3_installer.sh - A utility script to install ns-3 for VSimRTI.
# Ensure this file is executable via chmod a+x ns3_installer.
#
# author: VSimRTI developer team <vsimrti@fokus.fraunhofer.de>
# last updated: 07/04/2016
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

clear

umask 027

set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

trap clean_up INT

cyan="\033[01;36m"
red="\033[01;31m"
bold="\033[1m"
restore="\033[0m"

arg_quiet=false
arg_uninstall=false
arg_ns3_file=""
arg_federate_file=""
arg_integration_testing=false
arg_make_parallel=""

required_programs=( python gcc unzip tar )
required_libraries=( "libprotobuf-dev (or equal) 2.6.1" "libxml2-dev (or equal)" "libsqlite3-dev (or equal)" )

downloaded_files=""
uninstall_files="license_gplv2.txt ns-allinone run.sh"

####### configurable parameters ##########
ns3_version="3.25"
vsimrti_version="17.0"
#vsimrti_version="void"

####### automated parameters #############
ns3_version_affix="ns-allinone-$ns3_version"
ns3_version_affix_unified="ns-allinone"
ns3_short_affix="ns-$ns3_version"
ns3_short_affix_unified="ns"
working_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
federate_path="bin/fed/ns3"
ns3_installation_path=${working_directory}
ns3_scratch="${ns3_installation_path}/$ns3_version_affix/$ns3_short_affix/scratch"
ns3_source="${ns3_installation_path}/$ns3_version_affix/$ns3_short_affix/src"

####### semi automatic parameters ########
ns3_federate_url="https://www.dcaiti.tu-berlin.de/research/simulation/download/get/ns-3-patch-$vsimrti_version.zip"
#ns3_federate_url="void"
ns3_url="http://www.nsnam.org/release/$ns3_version_affix.tar.bz2"

###### more automatic parameters #########
ns3_federate_filename="$(basename "$ns3_federate_url")"
ns3_filename="$(basename "$ns3_url")"

get_arguments() {
  while [[ $# -ge 1 ]]
  do
      key="$1"
      case $key in
          -q|--quiet)
              arg_quiet=true
              ;;
	  -u|--uninstall)
              arg_uninstall=true
              ;;
          -f|--federate)
              arg_federate_file="$2"
              ns3_federate_filename="$2"
              shift #past argument
              ;;
          -s|--simulator)
              arg_ns3_file="$2"
              ns3_filename="$2"
              shift # past argument
              ;;
          -it|--integration_testing)
              arg_integration_testing=true
              arg_quiet=true
              ;;
          -j|--parallel)
              arg_make_parallel="-j $2"
              shift # past argument
              ;;
          -h|--help)
              arg_quiet=true
              print_info
              print_help
              exit 1
              ;;
        esac
     shift
  done
}

#################### Printing functions ##################

log() {
   STRING_ARG=$1
   printf "${STRING_ARG//%/\\%%}\n" ${*:2}
   return $?
}

warn() {
   log "${bold}${red}\nWARNING: $1\n${restore}" ${*:2}
}

fail() {
   log "${bold}${red}\nERROR: $1\n${restore}" ${*:2}
   clean_up
   exit 1
}

check_uninstall() {
   if $arg_uninstall; then
      log "Removing ns-3 federate"
      cd "$working_directory"
      rm -rf $uninstall_files
      exit 0
   fi
}


print_help() {
   log "\nUsage: ns3_installer.sh [options]\n"
   log "Options:\n"
   log "   -s --simulator <ns3 archive>		The script will not attempt to download NS3 but use the given argument."
   log "   -f --federate <federate archive>	The script will not attempt to download the federate archive but use the given argument."
   log "   -q --quiet				The script will not give any output but run silently instead."
   log "   -p --persistent			Do not delete NS3-archive and federate file after installation."
   log "   -h --help				Print this help\n"
   log "   -j --parallel <n>			Use n threads for compilation \n"
   log "   -u --uninstall			Remove the ns-3 federate \n"
}

print_usage() {
   log "${bold}${cyan}[$(basename "$0")] -- A ns-3 installation script for VSimRTI${restore}"
   log "\nUsage: $0 [arguments]"
   fail "Argument \""$1"\" not known."
} 

print_info() {
   log "${bold}${cyan}[$(basename "$0")] -- A ns-3 installation script for VSimRTI${restore}"
   log "\nVSimRTI developer team <vsimrti@fokus.fraunhofer.de>"
   log "\nThis shell script will download and install the NS3 network simulator version $ns3_version."
   log "\nPlease make sure you have installed the packages g++ libsqlite3-dev libxml2-dev libprotobuf-dev 2.6.1 ."
   log "\nIf there is an error (like a missing package) during the installation, the output may give hints about what went wrong.\n"
   if [ "$arg_quiet" = false ]; then
      read -p "Press any key to continue..." -n1 -s
      log "\n"
   fi
}

print_success() {
   log "${bold}\nDone! ns-3 was successfully installed.${restore}"
}

################## Checking functions #################

has() {
   return $( which $1 >/dev/null )
}

check_shell() {
   if [ -z "$BASH_VERSION" ]; then
      fail "This script requires the BASH shell"
      exit 1
   fi
}

check_required_programs()
{
   for package in $1; do
      if ! has $package; then
         fail ""$package" required, but it's not installed. Please install the package (sudo apt-get install for Ubuntu/Debian) and try again.";
      fi
   done
}

check_directory() {
   cd "$working_directory"
   federate_working_directory=`echo "$working_directory" | rev | cut -c -${#federate_path} | rev`
   if [ "$federate_working_directory" == "$federate_path" ]; then
      return
   else
      fail "This doesn't look like a VSimRTI directory. Please make sure this script is started from "$federate_path"." 
   fi
}

check_nslog() {
	if [[ ! $NS_LOG =~ .*level.* ]]; then
		log "Logging probably not correctly initialized"
	fi
}

ask_dependencies()
{
   if $arg_integration_testing || $arg_quiet; then
      return
   fi

   while  [ true ]; do
      log "Are the following dependencies installed on the system? \n"
      log "${bold}Libraries:${restore}"
      for lib in "${required_libraries[@]}"; do
        log "${bold}${cyan} $lib ${restore}"
      done
      log "\n${bold}Programs:${restore}"
      for prog in "${required_programs[@]}"; do
        log "${bold}${cyan} $prog ${restore}"
      done
      printf "\n[y/n] "
      read answer
      case $answer in
         [Yy]* ) break;;
         [Nn]* )
            log "\n${red}Please install the required dependencies before proceeding with the installation process${restore}\n"
            exit;;
         * ) echo "Allowed choices are yes or no";;
      esac
   done;
}

################### Downloading and installing ##########

download() {
   if [ ! -f "$(basename "$1")" ]; then
      basen=$(basename "$1")
      if has wget; then
         wget --no-check-certificate -q "$1" || fail "The download URL seems to have changed. File not found: "$1"";
         downloaded_files="$downloaded_files $basen"
      elif has curl; then
         curl -s -O "$1" || fail "The download URL seems to have changed. File not found: "$1"";
         downloaded_files="$downloaded_files $basen"
      else
         fail "Can't download "$1".";
      fi
   else
      warn "File $(basename "$1") already exists. Skipping download."
   fi
}


download_ns3() {
   if [ ! -z "$arg_ns3_file" ]; then
      log "NS3 given as argument"
      return
   fi
   log "Downloading NS3 from $ns3_url..."
   download "$ns3_url"
}

download_federate() {
   if [ ! -z "$arg_federate_file" ]; then
      log "federate given as argument"
      return
   fi
   log "Downloading federate from "$ns3_federate_url"..."
   download "$ns3_federate_url"
}

extract_ns3()
{
   if [ ! -d "$2/ns3_version_affix" ]; then
      arg1="$1"
      arg2="$2"
      tar --ignore-command-error -C "$arg2" -xf "$arg1"
   else
      fail "Directory in "$2" already exists." 
   fi
}

extract_ns3_federate()
{
   if [ ! -d "./src" ]; then
      arg1="$1"
      unzip --qq -o "$arg1"
   elif [ ! -d "./scratch" ]; then
      arg1="$1"
      unzip --qq -o "$arg1"
   elif [ ! -d "./patch" ]; then
      arg1="$1"
      unzip --qq -o "$arg1"
   else
      fail "Directory in "." already exists.";
   fi
}

copy_folder()
{
   if [ -d "scratch" ]; then
      cp -r scratch/* "$ns3_scratch"
   else
      fail "Directory scratch not found.";
   fi
   if [ -d "src" ]; then
      mkdir "$ns3_source/VSimRTI"
      cp -r src/VSimRTI/* "$ns3_source/VSimRTI/"
   else
      fail "Directory src not found.";
   fi
}

patch_ns3()
{
   ### copy the run file
   cp -f "patch/run.sh" "$ns3_installation_path/run.sh"
   chmod +x "$ns3_installation_path/run.sh"

   ### apply the VSimRTI patch
   patchfiles=$(find patch/ns-VERSION_patches/ -name "*.patch")
   for cur_patch in $patchfiles; do
      log "Applying patch: $cur_patch\n" 
      patch -Np1 -d "$ns3_installation_path/$ns3_version_affix/$ns3_short_affix" < "$cur_patch"
   done
}

unify_folder_name()
{
   cd "${ns3_installation_path}/"
   mv "${ns3_installation_path}/$ns3_version_affix/" "${ns3_installation_path}/$ns3_version_affix_unified/"
   mv "${ns3_installation_path}/$ns3_version_affix_unified/$ns3_short_affix" "${ns3_installation_path}/$ns3_version_affix_unified/$ns3_short_affix_unified"
   ns3_version_affix=$ns3_version_affix_unified
   ns3_short_affix=$ns3_short_affix_unified
}

uninstall()
{
   if [ -d "ns-allinone" ]; then
      rm -rf "ns-allinone"
   fi
}

clean_up()
{
   cd "$working_directory"
   #remove temporarily extracted folders and files
   if [ -d "patch" ]; then
      rm -rf "patch"
   fi
   if [ -d "scratch" ]; then
      rm -rf "scratch"
   fi
   if [ -d "src" ]; then
      rm -rf "src"
   fi
   #remove downloaded files if wanted
   if [ -z "$downloaded_files" ]; then
      return
   fi
   if [ "$arg_integration_testing" = false ]; then
      while  [ true ]; do
         log "Do you want to remove the following files and folders? ${bold}${red} $downloaded_files ${restore} \n[y/n] "
		 if $arg_quiet; then
            answer=Y
         else
            read answer
         fi
         case $answer in
            [Yy]* ) rm -rf $downloaded_files 2>/dev/null
                    break;;
            [Nn]* ) break;;
            * ) echo "Allowed choices are yes or no";;
         esac
      done;
   fi
}

build_ns3()
{
   cd "${ns3_installation_path}/$ns3_version_affix/$ns3_short_affix"
   ./waf configure --disable-python --disable-nsclick --enable-modules=VSimRTI
   ./waf build $arg_make_parallel
}

# Workaround for integration testing
set_nslog() {
	export NS_LOG="'*=level_all|prefix'"
}

##################                   #################
################## Begin script flow #################

check_shell

get_arguments $*

check_uninstall

print_info

ask_dependencies

log "Preparing installation..."
check_required_programs "${required_programs[*]}"
check_directory

download_ns3

download_federate

log "Extracting "$ns3_filename"..."
extract_ns3 "$ns3_filename" .

log "Extracting "$ns3_federate_filename"..."
extract_ns3_federate "$ns3_federate_filename"

log "Moving content..."
copy_folder

log "Applying patch for ns-3..."
patch_ns3

log "Unifying folder name"
unify_folder_name

log "Building ns-3..."
build_ns3

log "Set ns-3 debug-levels..."
set_nslog
check_nslog

log "Cleaning up..."
clean_up

print_success

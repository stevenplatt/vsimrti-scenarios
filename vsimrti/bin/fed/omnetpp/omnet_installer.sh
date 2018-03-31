#!/usr/bin/env bash
#
# omnet_installer.sh - A utility script to install OMNeT++/INET for VSimRTI.
# Ensure this file is executable via chmod a+x omnet_installer.
#
# author: VSimRTI developer team <vsimrti@fokus.fraunhofer.de>
# last updated: 05/04/2015
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

omnet_federate_url="http://www.dcaiti.tu-berlin.de/research/simulation/download/get/omnetpp-patch-17.0.zip"
#omnet_federate_url="void"
inet_src_url="http://github.com/inet-framework/inet/releases/download/v3.0.0/inet-3.0.0-src.tgz"

#arguments
arg_integration_testing=false
arg_quiet=false
arg_uninstall=false
arg_omnet_tar=""
arg_federate_patch_file=""
arg_inet_src_file=""
arg_make_parallel=""

#paths and names
omnet_dir_name_default="omnetpp-x.x"
omnet_federate_installation_path="omnetpp-federate"
patch_path="patch"
inet_installation_path="inet"
federate_path="bin/fed/omnetpp"
omnet_installation_path="../omnetpp_simulator/"
omnet_dir_name="${omnet_dir_name_default}"
omnet_src="${omnet_installation_path}/${omnet_dir_name}/src"
omnet_bin="${omnet_installation_path}/${omnet_dir_name}/bin"
omnet_lib="${omnet_installation_path}/${omnet_dir_name}/lib"
omnet_federate_filename="$(basename "$omnet_federate_url")"
patch_filename=inet.patch
inet_src_filename="$(basename "$inet_src_url")"
working_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

inet_temp=`mktemp -d`
omnet_federate_temp=`mktemp -d`

#inet configuration
disabled_inet_features=(TCP_lwIP TCP_NSC INET_examples IPv6 IPv6_examples xMIPv6 xMIPv6_examples MultiNet WiseRoute Flood RTP RTP_examples SCTP SCTP_examples DHCP DHCP_examples Ethernet Ethernet_examples PPP ExternalInterface  ExternalInterface_examples MPLS MPLS_examples OSPFv2 OSPFv2_examples BGPv4 BGPv4_examples PIM PIM_examples DYMO AODV AODV_examples GPSR RIP RIP_examples  MANET MANET_examples  mobility_examples physicalenvironment_examples Ieee802154 apskradio  wireless_examples VoIPStream VoIPStream_examples SimpleVoIP SimpleVoIP_examples HttpTools HttpTools_examples_direct HttpTools_examples_socket DiffServ DiffServ_examples InternetCloud InternetCloud_examples Ieee8021d Ieee8021d_examples TUN BMAC LMAC CSMA TCP_common TCP_INET)

#misc
required_programs=( unzip tar bison flex )
required_libraries=( "libprotobuf-dev (or equal) 2.6.1" )
downloaded_files=""

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

has() {
   return $( which $1 >/dev/null )
}

check_shell() {
   if [ -z "$BASH_VERSION" ]; then
      fail "This script requires the BASH shell"
      exit 1
   fi
}

get_arguments() {
    if [ "$#" -ge "1" ]; then
      if [ "${1:-}" == "-h" ] || [ "${1:-}" == "--help" ]; then
         print_usage
         exit 0
      else
        # note: if this is set to > 0 the /etc/hosts part is not recognized ( may be a bug )
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
                -it|--integration_testing)
                    arg_integration_testing=true
                    arg_quiet=true
                    ;;
                -s|--simulator)
                    arg_omnet_tar="$2"
                    shift # past argument
                    ;;
                -f|--federate)
                    arg_federate_patch_file="$2"
                    shift # past argument
                    ;;
		-i|--inet)
		    arg_inet_src_file="$2"
		    shift # past argument
		    ;;
		-j|--parallel)
                    arg_make_parallel="-j $2" 
                    shift # past argument
                    ;;
            esac
	    shift
        done
      fi
    fi
    
    if [ "$arg_uninstall" = false ] && [ "$arg_omnet_tar" == "" ]; then
      fail "Please provide at least the path to the omnet installer tar \n./omnet_installer.sh -s /path/to/omnetpp-src.tgz\n\nHint: Use -h or --help to list the options."
      exit 1
    fi
}

extract_omnet_dir_name() {
  if [ "$arg_omnet_tar" != "" ]; then
    arg_omnet_tar_filename="$(basename "${arg_omnet_tar}")"
    tmp_dir_name="${arg_omnet_tar_filename%-src*}"
    if [ "${arg_omnet_tar_filename}" == "${tmp_dir_name}" ]; then
      log "Warning: falling back to ${omnet_dir_name_default} as name for installation directory" 
      omnet_dir_name="${omnet_dir_name_default}"
    else
      omnet_dir_name="${tmp_dir_name}"
    fi
  fi

  omnet_src="${omnet_installation_path}/${omnet_dir_name}/src"
  omnet_bin="${omnet_installation_path}/${omnet_dir_name}/bin"
  omnet_lib="${omnet_installation_path}/${omnet_dir_name}/lib"
}

print_usage() {
   log "${bold}${cyan}[$(basename "$0")] -- An OMNeT++/INET installation script for VSimRTI${restore}"
   log "\nUsage: $0 [arguments]"
   log "\nArguments:"
   log "\n -s, --simulator <path to omnet src archive>"
   log "\n     provide the archive containing the OMNeT++ source"
   log "\n     You can obtain it from ${cyan}https://omnetpp.org/omnetpp/download/30-omnet-releases/2290-omnet-4-6-source-ide-tgz${restore}"
   log "\n -f, --federate <path to downloaded omnetpp-patch>"
   log "\n     provide the archive containing the OMNeT++-federate and patches for coupling OMNeT++ to VSimRTI"
   log "\n -i, --inet_src <path to inet source>"
   log "\n     provide the archive containing the inet source code"
   log "\n     You can obtain it from ${cyan}https://inet.omnetpp.org/Download.html${restore}"
   log "\n -q, --quiet"
   log "\n     less output, no interactions"
   log "\n -j, --parallel <number of threads>"
   log "\n     enables make to use the given number of compilation threads"
   log "\n -u, --uninstall"
   log "\n     uninstalls the OMNeT++ federate"
}

print_info() {
   log "${bold}${cyan}[$(basename "$0")] -- An OMNeT++/INET installation script for VSimRTI$restore}"
   log "\nVSimRTI developer team <vsimrti@fokus.fraunhofer.de>"
   if [ ! -f "$arg_federate_patch_file" ]; then
     log "\nThis shell script will install the OMNeT++ network simulator ($omnet_dir_name) with the INET framework (in $omnet_federate_filename from $omnet_federate_url)."
   else
     log "\nThis shell script will install the OMNeT++ network simulator ($omnet_dir_name) with the INET framework (in local $arg_federate_patch_file)."
   fi
   log "\nIf there is an error (like a missing package) during the installation, the output may give hints about what went wrong.\n"
   if [ "$arg_quiet" = false ]; then
      read -p "Press any key to continue..." -n1 -s
      log "\n"
   fi
}

# Workaround for integration testing
set_environment_variables()
{
    export PATH="${omnet_bin}:$PATH"
    export LD_LIBRARY_PATH="$omnet_lib:$inet_installation_path${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH:-}"
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

check_environment_variables() {
   if [[ ! $PATH =~ .*$omnet_bin.* ]]; then
      warn ""$omnet_bin" is not in the \$PATH environment variable.";
   fi
   if [[ ! $LD_LIBRARY_PATH =~ .*$omnet_lib.* ]]; then
      warn ""$omnet_lib" is not in the \$LD_LIBRARY_PATH environment variable.";
   fi
}

download() {
   if [ ! -f "$(basename "$1")" ]; then
      if has wget; then
         wget -q "$1" || fail "The download URL seems to have changed. File not found: "$1"";
      elif has curl; then
         curl -s -O "$1" || fail "The download URL seems to have changed. File not found: "$1"";
      else
         fail "Can't download "$1".";
      fi
   else
      warn "File $(basename "$1") already exists. Skipping download."
   fi
}

extract_omnet()
{
   arg1="$1" #omnet archive 
   arg2="$2" #destination folder - subfolder omnet_dir_name will be created
   if [ -f "$1" ]; then
      if [ -d "$2/${omnet_dir_name}" ]; then
         fail "$2/${omnet_dir_name} exists, please uninstall the existing installation before proceeding (-u or --uninstall)" 
         exit 1;
      fi
      if [ ! -d "$arg2" ]; then
         mkdir "$arg2"
      fi
      tar -C "$arg2" -xf "$arg1"
   else
      fail "OMNeT++ sources are not present!";
   fi
}

extract_inet()
{
   cd "$working_directory"
   if [ -f "$1" ]; then
      if [ -d "$working_directory/$inet_installation_path" ]; then
         fail "$working_directory/$inet_installation_path exists, please uninstall the existing installation before proceeding (-u or --uninstall)" 
         exit 1;
      fi
      tar -C "$working_directory/" -xf "$1"
   else
      fail "INET sources are not present!";
   fi
}

uninstall()
{
   cd "$working_directory"
   #Always remove temporary files
   if [ -d "$omnet_federate_installation_path" ]; then
      rm -rf "$omnet_federate_installation_path"
   fi
   if [ -d "$inet_installation_path" ]; then
      rm -rf "$inet_installation_path"
   fi
   rm -f "libINET.so" > /dev/null
   if [ -d "${omnet_installation_path}" ]; then
      while  [ true ]; do
         log "Do you want to remove ${omnet_installation_path} ?" 
         read answer
         case $answer in
            [Yy]* ) rm -rf "${omnet_installation_path}"
                    break;;
            [Nn]* ) break;;
            * ) echo "Allowed choices are yes or no";;
         esac
      done;
   fi
   #call normal cleanup to remove temporary and downloaded files
   clean_up
}

clean_up()
{
   #Always remove temporary files
   if [ -d "$omnet_federate_temp" ]; then
      rm -rf "$omnet_federate_temp"
   fi
   if [ -d "$inet_temp" ]; then
      rm -rf "$inet_temp"
   fi
   if [ -d "$patch_path" ]; then
      rm -rf "$patch_path"
   fi
   #Remove the downloaded files if wanted
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
            [Yy]* ) break;;
            [Nn]* ) return;;
            * ) echo "Allowed choices are yes or no";;
         esac
      done;
   fi
   cd "$working_directory"
   rm -rf $downloaded_files

}

configure_omnet()
{
   cd "$omnet_installation_path/${omnet_dir_name}"
   export PATH=$(pwd -L)/bin:$PATH
   NO_TCL=1 ./configure
}

build_omnet()
{
   cd "$working_directory"
   cd "$omnet_installation_path/${omnet_dir_name}"
   make $arg_make_parallel MODE=debug base
}

patch_inet()
{
   cd "$working_directory/$inet_installation_path"
   patch -p0 < "$working_directory/$patch_path/$patch_filename"
   #disable unneeded features
   for feat in "${disabled_inet_features[@]}"; do
      echo "y" | ./inet_featuretool disable "$feat" > /dev/null
   done
   make makefiles
}

build_inet()
{
   cd "$working_directory/$inet_installation_path"
   make $arg_make_parallel MODE=debug
   if [ -f "out/gcc-debug/src/libINET.so" ]; then
      cp "out/gcc-debug/src/libINET.so" "../libINET.so"  #We need the libINET only once in the main directory. This is compiled into the federate.
   else
      fail "Shared library \"libINET.so\" not found. Something went wrong while building INET."
   fi
   if [ -d "src" ]; then
      (cd "src"; tar -cf - `find . -name "*.ned" -print` | ( cd "$inet_temp" && tar xBf - ))
   else
      fail "Directory \"src\" not found. Something went wrong while building INET."
   fi
   if [ -d "$inet_temp" ]; then
        cd "$working_directory"
        cp -r "$inet_temp" .
        rm -rf "$inet_temp"
   else
      fail "Directory "$inet_temp" not found. Something went wrong while building INET."
   fi
}

build_omnet_federate()
{
   cd "$working_directory/$omnet_federate_installation_path"
   make $arg_make_parallel MODE=debug
   if [ -f "out/gcc-debug/src/omnetpp-federate" ]; then
      cp "out/gcc-debug/src/omnetpp-federate" "$omnet_federate_temp"
   else
      fail "Executable \"omnetpp-federate\" not found. Something went wrong while building the OMNeT++ federate."
   fi
   if [ -d "src" ]; then
      (cd "src"; tar -cf - `find . -name "*.ned" -print` | ( cd "$omnet_federate_temp" && tar xBf - ))
   else
      fail "Directory \"src\" not found. Something went wrong while building the OMNeT++ federate."
   fi
   if [ -d "$omnet_federate_temp" ]; then
      cd "$working_directory"
      cp -r "$omnet_federate_temp" .
      rm -rf "$omnet_federate_temp"
   else
      fail "Directory "$omnet_federate_temp" not found. Something went wrong while building OMNeT++ federate." 
   fi
   if [ -d "$omnet_federate_installation_path" ]; then
      rm -rf "$omnet_federate_installation_path"
   fi
   mv "$(basename "$omnet_federate_temp")" "$omnet_federate_installation_path"
}

deploy_inet() {
   if [ -d "$inet_installation_path" ]; then
      rm -rf "$inet_installation_path"
   fi
   mv "$(basename "$inet_temp")" "$inet_installation_path"
}

print_success() {
   log "${bold}\nDone! OMNeT++ was successfully installed.${restore}"
}

######## Preparation ########
check_shell

get_arguments $*

if [ "$arg_uninstall" = true ]; then
   log "Uninstalling..."
   uninstall
   exit 0
fi

log "Preparing installation..."
extract_omnet_dir_name

print_info

ask_dependencies

log "Setting required environment variables..."
set_environment_variables

check_required_programs "${required_programs[*]}"

check_directory

check_environment_variables

######## Downloading / extracting ########
if [ ! -f "$arg_federate_patch_file" ]; then
  log "Downloading "$omnet_federate_url"..."
  download "$omnet_federate_url"
  downloaded_files="$downloaded_files $omnet_federate_filename"

  log "Extracting "$omnet_federate_filename"..."
  unzip --qq -o "$omnet_federate_filename"
else
  log "Extracting "$arg_federate_patch_file"..."
  unzip --qq -o "$arg_federate_patch_file"
fi

if [ ! -f "$arg_inet_src_file" ]; then
  log "Downloading $inet_src_url ..."
  download "$inet_src_url"
  downloaded_files="$downloaded_files $inet_src_filename"

  log "Extracting $inet_src_filename ..."
  extract_inet $inet_src_filename 
else
  log "Extracting $arg_inet_src_file ..."
  extract_inet $arg_inet_src_file
fi

log "Extracting "$arg_omnet_tar"..."
extract_omnet "$arg_omnet_tar" "$omnet_installation_path"

######## Buliding OMNeT++ ########
log "Configuring OMNeT++..."
configure_omnet

log "Building OMNeT++..."
build_omnet

######## Building INET ########
log "Patching INET"
patch_inet

log "Building INET framework..."
build_inet

######## Building federate ########
log "Building OMNeT++ federate..."
build_omnet_federate

log "Removing unneeded files from INET"
deploy_inet

print_success

####### Cleaning up downloading and temporary files #########
log "Cleaning up..."
clean_up

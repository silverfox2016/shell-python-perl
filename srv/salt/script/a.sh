#!/bin/bash - 
#===============================================================================
#
#          FILE: a.sh
# 
#         USAGE: ./a.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 09/22/2017 01:50:07 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
env x='() { :;}; echo vulnerable' bash -c "echo this is a test"

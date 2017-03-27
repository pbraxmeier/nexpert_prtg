########################################################
# 
# Nexpert AG for use with PRTG Network Monitor
#
#
# Description:    	
#
# This bash script displays the number of file in the directory
#					
# Example:			
#
# 1. Copy script to /var/prtg/scripts
# 2. make the file executable
# 3. In PRTG Create SSH Script and select this script
# 4. Test it! Create files & delete files
#
#########################################################
#!/bin/bash
result=$(ls -1 /opt/otrs/var/spool/ | wc -l)


        echo "0:$result:$result files"


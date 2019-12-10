#!/bin/bash
#
# Dynamic ansible AWX inventory from puppetdb, outputs in JSON
#
# Dump entire list: awx-puppetdb.sh --list
# Dump single host: awx-puppetdb.sh --host fqdn.example.com
#
# The two vars you MUST update:
# 1) URL of your PuppetDB server, example:
#   PUPPETDBURL=puppetdb.example.com:8080
# 2) List of facts you want to pull from PuppetDB and shove into AWX as ansible VARIABLES (not facts), example:
# FACTS="ipaddress kernel memoryfree_mb"

ME=$( basename $0 )
TMPJSON=/tmp/.awx_inventory
PUPPETDBURL=puppetdb.example.com:8080
FACTS="ipaddress is_virtual kernel memoryfree_mb memorysize_mb operatingsystem operatingsystemmajrelease operatingsystemrelease osfamily processorcount puppetversion virtual swapfree_mb swapsize_mb"

if [[ $# -lt 1 ]]; then
  echo "Usage: ${ME} [ --list | --host fqdn.example.com ]"
  exit 1
fi

# Slurp $FACTS into an array
MYFACTS=( $FACTS )
LASTFACT=${MYFACTS[-1]}

if [[ $1 =~ host ]]; then

  MYNODE=$2
  printf "{\n" > $TMPJSON

  for f in ${MYFACTS[@]}; do

    VALUE=$( curl -s -X GET http://${PUPPETDBURL}/pdb/query/v4/nodes/${MYNODE}/facts/${f} --data-urlencode 'pretty=true' | awk -F: '$1 ~ /value/ { print $2 }' | sed 's/"//g' | tr -d ' ' )
    if [ -z "${VALUE}" ]; then
      VALUE='null'
    fi

    # Last attribute does not end with a comma in JSON
    if [[ $f = $LASTFACT ]]; then
      printf "  \"${f}\": \"${VALUE}\"\n" >> $TMPJSON
    else
      printf "  \"${f}\": \"${VALUE}\",\n" >> $TMPJSON
    fi

  done
  printf "}\n" >> $TMPJSON

  cat $TMPJSON

  exit

fi

if [[ $1 =~ list ]]; then
  # Originally used jq to parse the output, but the AWX images do not have it by default, so hack around it instead
  MYNODES=$( curl -s -X GET http://${PUPPETDBURL}/pdb/query/v4/nodes --data-urlencode 'pretty=true' | awk -F: '$1 ~ /certname/ { print $2 }' | sed 's/"//g' | sed 's/,//' | tr -d ' ' | sort )
fi

NODES=( $MYNODES )
LASTNODE=${NODES[-1]}

printf "{\n" > $TMPJSON

printf "  \"group\": {\n    \"hosts\": [\n" >> $TMPJSON

for i in ${NODES[@]}; do

  if [[ $n = $LASTNODE ]]; then
    printf "      \"${i}\"\n" >> $TMPJSON
  else
    printf "      \"${i}\",\n" >> $TMPJSON
  fi

done

printf "    ]\n  },\n" >> $TMPJSON

printf "  \"_meta\": {\n    \"hostvars\": {\n" >> $TMPJSON
for n in ${NODES[@]}; do

  printf "      \"${n}\": {\n" >> $TMPJSON

  for f in ${MYFACTS[@]}; do

    VALUE=$( curl -s -X GET http://${PUPPETDBURL}/pdb/query/v4/nodes/${n}/facts/${f} --data-urlencode 'pretty=true' | awk -F: '$1 ~ /value/ { print $2 }' | sed 's/"//g' | tr -d ' ' )
    if [ -z "${VALUE}" ]; then
      VALUE='null'
    fi

    # Example how to add an extra var based on a puppet fact. Add ansible_python_interpreter for CentOS/RHEL5.
    #if [[ $f = operatingsystemmajrelease ]] && [[ $VALUE = 5 ]]; then
    #  printf "        \"ansible_python_interpreter\": \"/usr/local/python/bin/python3.6\",\n" >> $TMPJSON
    #fi

    # Last attribute does not end with a comma in JSON
    if [[ $f = $LASTFACT ]]; then
      printf "        \"${f}\": \"${VALUE}\"\n" >> $TMPJSON
    else
      printf "        \"${f}\": \"${VALUE}\",\n" >> $TMPJSON
    fi

  done

  if [[ $n = $LASTNODE ]]; then
    printf "      }\n" >> $TMPJSON
  else
    printf "      },\n" >> $TMPJSON
  fi

done

printf "    }\n  }\n}\n" >> $TMPJSON
cat $TMPJSON
#rm -f $TMPJSON

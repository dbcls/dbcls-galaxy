#!/bin/sh

if [ $# -ne 2 ]; then
    echo "generate_tool.sh: illegal arguments"
    echo "usage: generate_tool.sh category_id tool_id" 1>&2
    exit 1
fi

if [ ! -e tools -o ! -d tools -o ! -e tool_conf.xml ]; then
    echo "Use this command at galaxy root directory." 1>&2
    exit 1
fi

gendir=`dirname $0`
tempdir=`mktemp -d /tmp/generate_files_temp.XXXXXX`

mkdir -p ${tempdir}/tools/$1\
&& ruby -I${gendir} ${gendir}/generate_files.rb $2 ${tempdir}/tools/$1\
&& cp tool_conf.xml ${tempdir}\
&& ruby -I${gendir} ${gendir}/append_to_tool_conf.rb ${tempdir}/tool_conf.xml $1 $2\
&& cp -r ${tempdir}/* ./
status=$?

rm -rf ${tempdir}
if [ ! $status -eq 0 ]; then
    echo "!!! $0 aborted !!!" 1>&2
    exit 1
fi

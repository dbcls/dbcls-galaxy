#!/bin/sh
awk '{ print "Hello " $0 "!" }' < $1 > $2

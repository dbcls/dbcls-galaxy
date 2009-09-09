#!/usr/bin/env python
#Dan Blankenberg

import sys
from galaxy import eggs
import pkg_resources; pkg_resources.require( "bx-python" )
import bx.align.maf

assert sys.version_info[:2] >= ( 2, 4 )

def __main__():
    output_name = sys.argv.pop(1)
    input_name = sys.argv.pop(1)
    species = sys.argv.pop(1)
    out = open(output_name,'w')
    count = 0
    #write interval header line
    out.write( "#chrom\tstart\tend\tstrand\n" )
    try:
        for maf in bx.align.maf.Reader( open(input_name, 'r') ):
            c = maf.get_component_by_src_start(species)
            if c is not None:
                out.write( "%s\t%i\t%i\t%s\n" % (bx.align.src_split(c.src)[-1], c.get_forward_strand_start(), c.get_forward_strand_end(), c.strand) )
                count += 1
    except Exception, e:
        print >> sys.stderr, "There was a problem processing your input: %s" % e
    out.close()
    print "%i MAF blocks converted to Genomic Intervals for species %s." % (count, species)


if __name__ == "__main__": __main__()
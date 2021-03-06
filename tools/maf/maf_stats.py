#!/usr/bin/env python
#Dan Blankenberg
"""
Reads a list of intervals and a maf. Outputs a new set of intervals with statistics appended.
"""

import sys
from galaxy import eggs
import pkg_resources; pkg_resources.require( "bx-python" )
import bx.intervals.io
from bx.bitset import BitSet
from galaxy.tools.util import maf_utilities

assert sys.version_info[:2] >= ( 2, 4 )

def __main__():
    maf_source_type = sys.argv.pop( 1 )
    input_maf_filename = sys.argv[1].strip()
    input_interval_filename = sys.argv[2].strip()
    output_filename = sys.argv[3].strip()
    dbkey = sys.argv[4].strip()
    try:
        chr_col  = int( sys.argv[5].strip() ) - 1
        start_col = int( sys.argv[6].strip() ) - 1
        end_col = int( sys.argv[7].strip() ) - 1
    except:
        print >>sys.stderr, "You appear to be missing metadata. You can specify your metadata by clicking on the pencil icon associated with your interval file."
        sys.exit()
    summary = sys.argv[8].strip()
    if summary.lower() == "true": summary = True
    else: summary = False

    mafIndexFile = "%s/maf_index.loc" % sys.argv[9]
    try:
        maf_index_filename = sys.argv[10].strip()
    except:
        maf_index_filename = None
    index = index_filename = None
    if maf_source_type == "user":
        #index maf for use here
        index, index_filename = maf_utilities.open_or_build_maf_index( input_maf_filename, maf_index_filename, species = [dbkey] )
        if index is None:
            print >>sys.stderr, "Your MAF file appears to be malformed."
            sys.exit()
    elif maf_source_type == "cached":
        #access existing indexes
        index = maf_utilities.maf_index_by_uid( input_maf_filename, mafIndexFile )
        if index is None:
            print >> sys.stderr, "The MAF source specified (%s) appears to be invalid." % ( input_maf_filename )
            sys.exit()
    else:
        print >>sys.stdout, 'Invalid source type specified: %s' % maf_source_type 
        sys.exit()
        
    out = open(output_filename, 'w')
    
    num_region = 0
    species_summary = {}
    total_length = 0
    #loop through interval file
    for num_region, region in enumerate( bx.intervals.io.NiceReaderWrapper( open( input_interval_filename, 'r' ), chrom_col = chr_col, start_col = start_col, end_col = end_col, fix_strand = True, return_header = False, return_comments = False ) ):
        src = "%s.%s" % ( dbkey, region.chrom )
        region_length = region.end - region.start
        total_length += region_length
        coverage = { dbkey: BitSet( region_length ) }
        
        for block in maf_utilities.get_chopped_blocks_for_region( index, src, region, force_strand='+' ):
            #make sure all species are known
            for c in block.components:
                spec = c.src.split( '.' )[0]
                if spec not in coverage: coverage[spec] = BitSet( region_length )
            start_offset, alignment = maf_utilities.reduce_block_by_primary_genome( block, dbkey, region.chrom, region.start )
            for i in range( len( alignment[dbkey] ) ):
                for spec, text in alignment.items():
                    if text[i] != '-':
                        coverage[spec].set( start_offset + i )
        if summary:
            #record summary
            for key in coverage.keys():
                if key not in species_summary: species_summary[key] = 0
                species_summary[key] = species_summary[key] + coverage[key].count_range()
        else:
            #print coverage for interval
            coverage_sum = coverage[dbkey].count_range()
            out.write( "%s\t%s\t%s\t%s\n" % ( "\t".join( region.fields ), dbkey, coverage_sum, region_length - coverage_sum ) )
            keys = coverage.keys()
            keys.remove( dbkey )
            keys.sort()
            for key in keys:
                coverage_sum = coverage[key].count_range()
                out.write( "%s\t%s\t%s\t%s\n" % ( "\t".join( region.fields ), key, coverage_sum, region_length - coverage_sum ) )
    if summary:
        out.write( "#species\tnucleotides\tcoverage\n" )
        for spec in species_summary:
            out.write( "%s\t%s\t%.4f\n" % ( spec, species_summary[spec], float( species_summary[spec] ) / total_length ) )
    out.close()
    print "%i regions were processed with a total length of %i." % ( num_region, total_length )
    maf_utilities.remove_temp_index_file( index_filename )

if __name__ == "__main__": __main__()

#!/usr/bin/env python
# read motif alignment file(e.g. generated from bobro2align)
# write out various matrix and score for each motif

from Bio.Seq import Seq

from Bio import motifs

import sys

def motif_output(name, seqs):
  m = motifs.create(seqs)
 
  print name
  print "%consensus"
  print m.consensus
  print "%degenerate_consensus"
  print m.degenerate_consensus


  print "%counts matrix"
  print m.counts

  print "%pwm (position weight matrix)"
  pwm = m.counts.normalize(pseudocounts=0.0)
  print pwm

  print "%pssm (position-specific scoring matrix)"
  pssm = pwm.log_odds()
  print pssm

  print "%Information content"
  mean = pssm.mean()
  print mean
  print 


if __name__ == '__main__':

  from Bio.Seq import Seq

  from Bio import motifs

  import sys
  motif = ''
  instances = []
  for line in sys.stdin:
    line = line.rstrip()
    if line.startswith('>'):
      if motif != '':
        motif_output(motif, instances)
        #print instances

      motif = line[1:]
      instances = []
    else:
      instances.append(Seq(line))






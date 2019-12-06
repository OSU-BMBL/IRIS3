#!/usr/bin/env bash

cat Some_Bobro_output | perl parse_bobro_align > A_align.txt
cat A_align.txt | perl align2uniprobe.pl | perl uniprobe2meme > A.meme


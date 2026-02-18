#!/bin/bash

module load Plink/2.0

AUTOCALL="Husain-AMD_OmniExpress_Feb2017_Passing_AUTOCALL_.FHG19"
BIRDSUITE="Husain-AMD_OmniExpress_Feb2017_Passing_BIRDSUITE_.FHG19"

out="/PHShome/jl2251/Ines/Husain-AMD"
tmp="/PHShome/jl2251/Ines/Husain-AMD/tmp"

mkdir -p ${out} ${tmp}
#Remove the header that starts with '#' and also the column names (keeps everything from line 2 onwards (skips line 1, which is the column nmae))
grep -v "^#" ~/Ines/originalFiles/Husain-AMD_OmniExpress_Feb2017.HG19.map | tail -n +2  > ${AUTOCALL}.map 
grep -v "^#" ~/Ines/originalFiles/Husain-AMD_OmniExpress_Feb2017.HG19.map | tail -n +2  > ${BIRDSUITE}.map

grep -v "^#" ~/Ines/originalFiles/Husain-AMD_OmniExpress_Feb2017_Passing_AUTOCALL_.FHG19.ped > ${AUTOCALL}.ped
grep -v "^#" ~/Ines/originalFiles/Husain-AMD_OmniExpress_Feb2017_Passing_BIRDSUITE_.FHG19.ped > ${BIRDSUITE}.ped


plink2 --pedmap ${AUTOCALL} --make-pgen --sort-vars --out "${tmp}/autocall.sorted"
plink2 --pedmap ${BIRDSUITE} --make-pgen --sort-vars --out "${tmp}/birdsuite.sorted"

plink2 --pfile "${tmp}/autocall.sorted" \
      --make-bed \
      --out "${out}/${AUTOCALL}"

plink2 --pfile "${tmp}/birdsuite.sorted" \
       --make-bed \
       --out "${out}/${BIRDSUITE}"

echo counting no. of samples and variants for autocall bed file
wc -l "${out}/${AUTOCALL}.fam"
wc -l "${out}/${AUTOCALL}.bim"
echo counting no. of samples and variants for birdsuite bed file
wc -l "${out}/${BIRDSUITE}.fam"
wc -l "${out}/${BIRDSUITE}.bim"

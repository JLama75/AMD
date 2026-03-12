#!/bin/bash
#SBATCH --job-name=CommonVar    # Job name
#SBATCH --mem=5G --nodes=1 --cpus-per-task=12       # Job memory request
#SBATCH --time=0-01:00:00
#SBATCH --output=Variants_common_%j.log   # Standard output and error log
#SBATCH --partition=long,normal,bigmem

#module load bcftools
#Output Files:
#:merged_AMD_GSA.comm_ovrlap_dir/0003.vcf
#:merged_AMD_GSA.comm_common_ids.txt

workdir="/PHShome/jl2251/Ines/Merge_Data"

filename1="AMD_GSA"
filename2="Husain_AMD_GSA"

file1="${workdir}/${filename1}.fixref.renamed.bim"
file2="${workdir}/${filename2}.fixref.renamed.bim"


C="merged_AMD_GSA.comm_"

comm -12 <(cut -f2 ${file1} | sort) <(cut -f2 ${file2} | sort) > $C"common_ids.txt"
#merged_AMD_GSA.comm_common_ids.txt
echo total no. of varaints commong among them:
wc -l $C"common_ids.txt"


file1="${workdir}/${filename1}.fixref.renamed.vcf.gz"
file2="${workdir}/${filename2}.fixref.renamed.vcf.gz"

#finding common variants between batches  
bcftools isec -c none $file1 $file2 --threads 12 -p $C"ovrlap_dir"                                    

#extracting common ids 
#0003.vcf has the common variants 
#bcftools query -f '%ID\n' $C"ovrlap_dir/0003.vcf" > $C"ovrlap.ids.txt"

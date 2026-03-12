#!/bin/bash
#SBATCH --job-name=ComputeMAF   # Job name
#SBATCH --mem=6G --nodes=1 --cpus-per-task=12       # Job memory request
#SBATCH --time=0-05:00:00
#SBATCH --output=ComputeMAF_%j.log   # Standard output and error log
#SBATCH --partition=long,normal,bigmem

#module load Bcftools
#module load  Samtools
#module load  Tabix

plink2=/PHShome/jl2251/Ines/Merge_Data/plink2/plink2
plink=/PHShome/jl2251/Ines/Merge_Data/plink1.9/plink

#Outputs
#:Check ComputeMAF.variants.log files for no. of common variants (MAF 1%)
#:merged_AMD_GSA_splitMultialleles_vcf.gz
#:merged_AMD_GSA_split.dedup_vcf.gz

#Inputs
file1="AMD_GSA"
file2="Husain_AMD_GSA"
workdir="/PHShome/jl2251/Ines/Merge_Data"
C="$workdir/merged_AMD_GSA_"
mergedFile="$workdir/merged_AMD_GSA_vcf.gz"
CommonVar="merged_AMD_GSA.comm_common_ids.txt"
sexInfo="merged.file.sex.tsv"

#To calculate how many of the variants common to the two batches are common variants (MAF>0.01)
${plink} --vcf ${mergedFile} --freq --out "${workdir}/merged_AMD_GSA_freq_out"  --threads 12 #computing MAF for all

#maf filtering 
FREQ_PATH="${workdir}/merged_AMD_GSA_freq_out.frq"
OUTPUT_PATH="merged_AMD_GSA_maf.txt"

# Extract SNPs from the frequency file that match the common IDs
grep -F -f ${CommonVar} $FREQ_PATH > "filtered_freq.txt" 

# Filter MAF > 0.01 and extract SNP column
awk '$5 > 0.01 {print $2}' "filtered_freq.txt" > $OUTPUT_PATH
echo -e "No. of common variants among the variants overlapping both the batches: " > ComputeMAF.variants.log
wc -l $OUTPUT_PATH >> ComputeMAF.variants.log

# Cleanup intermediate files
rm "filtered_freq.txt" 
echo -e "No. of variants in the merged data" >> ComputeMAF.variants.log
bcftools view -H  ${mergedFile} | wc -l >> ComputeMAF.variants.log

#Split multi allelic variants into separate rows and remove duplicated SNPs
bcftools norm -m -both ${mergedFile}  -Oz -o "${C}splitMultialleles_vcf.gz"
bcftools norm -d both "${C}splitMultialleles_vcf.gz" -Oz -o  "${C}split.dedup_vcf.gz"

echo -e "No. of variants in the merged data after removing duplicates" >> ComputeMAF.variants.log
bcftools view -H "${C}split.dedup_vcf.gz" | wc -l >> ComputeMAF.variants.log

#Now extract the overlapping variants among the two batches and make a plink file for further Variant QC steps

${plink2} --vcf "${C}split.dedup_vcf.gz" --update-sex ${sexInfo} --extract ${CommonVar} --double-id --make-bed --out "${C}CommVar"
echo -e "No. of variants in the merged data after extracting common variants" >> ComputeMAF.variants.log
wc -l "${C}CommVar.bim" >> ComputeMAF.variants.log




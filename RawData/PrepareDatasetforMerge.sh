#!/bin/bash
#SBATCH --job-name=mergeData    # Job name
#SBATCH --mem=25G --nodes=1 --cpus-per-task=12       # Job memory request
#SBATCH --time=0-02:00:00
#SBATCH --output=mergeData_%j.log   # Standard output and error log
#SBATCH --partition=long,normal,bigmem

#module load ${plink2}
#module load bcftools
#module load samtools
#module load tabix
which bgzip
which tabix

#Main Outputs
#:Husain_AMD_GSA.fixref.renamed.vcf.gz, AMD_GSA.fixref.renamed.vcf.gz
#:merged_AMD_GSA_vcf.gz


#Check the chromosome format and match it to hg19.fasta
#bcftools view -h $file1 | grep "^##contig" | sed 's/.*ID=\([^,]*\).*/\1/'
#bcftools view -h $file2 | grep "^##contig" | sed 's/.*ID=\([^,]*\).*/\1/'
#awk '{print $1}' "${file1}.bim" | sort | uniq
#awk '{print $1}' "${file2}.bim" | sort | uniq
#awk '$1=="XY"{print $1,$2,$4,$5}' "${file1}.bim" > XY_positions.txt

plink2=/PHShome/jl2251/Ines/Merge_Data/plink2/plink2

file1="/PHShome/jl2251/Ines/33112425786-6/33112425786-6"
file2="/PHShome/jl2251/Ines/Husain-AMD/Husain-AMD_OmniExpress_Feb2017_Passing_BIRDSUITE_.FHG19"
data="/PHShome/jl2251/Ines/Merge_Data/data"
workdir="/PHShome/jl2251/Ines/Merge_Data"
sex1="/PHShome/jl2251/Ines/Merge_Data/file1.sex.tsv"
sex2="/PHShome/jl2251/Ines/Merge_Data/file2.sex.tsv"

echo "$workdir"
ls -ld "$workdir"

batches=("$file1" "$file2")  # Add more as needed

for ((i=0; i<${#batches[@]}; i++)); do
    #export as vcf
    #Check the sample names (FID_IID) in vcf
    echo ${batches[i]}
    file=${batches[i]}
  	filename=$(basename "${batches[i]}")
  	echo $filename 
  	echo $file
  	if [[ "${filename}" == "33112425786-6" ]]; then
  		#keep=${keep1}
  		filename="AMD_GSA" 
  		echo subset the samples from ${filename} using samples in keep and save as vcf
  		#${plink2} --bfile $file --update-chr chr_map.txt 1 2  --match-x --sort-vars --make-pgen --out "${workdir}/tmp_${filename}"
  	  ${plink2} --bfile $file --merge-x --sort-vars --snps-only just-acgt --make-pgen --out "${workdir}/tmp_${filename}"
  	  ${plink2} --pfile "${workdir}/tmp_${filename}" --export vcf id-paste=iid --out "${workdir}/${filename}"
  		
  	elif [[ "${filename}" == "Husain-AMD_OmniExpress_Feb2017_Passing_BIRDSUITE_.FHG19" ]]; then
  		#keep=${keep2}
  		filename="Husain_AMD_GSA" #Should be MGBB_GSA_QC_4754
  		echo subset the samples from ${filename} using samples in keep and save as vcf
  		#${plink2} --bfile ${file} --split-par hg19  --export vcf id-paste=iid --out "${workdir}/${filename}"
  	  ${plink2} --bfile ${file} --export vcf id-delim="_" --snps-only just-acgt --out "${workdir}/${filename}"
  	  
  	fi
  	
  	# remove bad coordinates
  	echo removing bad co-ordinates ${filename}
    bcftools view -e 'CHROM="0" || POS=0' "${workdir}/${filename}.vcf" -Oz -o "${workdir}/${filename}.clean.vcf"

  	echo bzipping the vcf for ${filename}
  	bgzip "${workdir}/${filename}.clean.vcf" 
  	tabix -0 -p vcf "${workdir}/${filename}.clean.vcf.gz"
  
    #Check and fix REF alleles in a vcf against a reference genome
    echo fixing the ref alleles, fixing ref and alt allele swaps in the vcf using the reference genome...
  	bcftools +fixref "${workdir}/${filename}.clean.vcf.gz" -- -f "${data}/hg19.fasta" 
  	bcftools norm --check-ref s -f "${data}/hg19.fasta"  "${workdir}/${filename}.clean.vcf.gz" -Oz -o "${workdir}/${filename}.fixref.vcf.gz" 
  	echo after fixing the VCF alleles
  	bcftools +fixref "${workdir}/${filename}.fixref.vcf.gz"  -- -f "${data}/hg19.fasta" 
  	
  	tabix -0 -p vcf "${workdir}/${filename}.fixref.vcf.gz"
  	
  	if [[ "${filename}" == "AMD_GSA" ]]; then
  		echo rename the Variant IDs. This plink file will be used for detecting variants common among the two files.
  		${plink2} --vcf "${workdir}/${filename}.fixref.vcf.gz" --split-par b37 --update-sex ${sex1} --set-all-var-ids chr@:#:\$r:\$a --new-id-max-allele-len 2000 --double-id --make-bed --out "${workdir}/${filename}.fixref.renamed"
  		${plink2} --bfile "${workdir}/${filename}.fixref.renamed" --double-id --export vcf id-paste=iid --out "${workdir}/${filename}.fixref.renamed"
  	elif [[ "${filename}" == "Husain_AMD_GSA" ]]; then
  		echo rename the Variant IDs. This plink file will be used for detecting variants common among the two files.
  		${plink2} --vcf "${workdir}/${filename}.fixref.vcf.gz" --split-par b37 --update-sex ${sex2} --set-all-var-ids chr@:#:\$r:\$a --new-id-max-allele-len 2000 --double-id --make-bed --out "${workdir}/${filename}.fixref.renamed"
  		${plink2} --bfile "${workdir}/${filename}.fixref.renamed" --double-id --export vcf id-paste=iid --out "${workdir}/${filename}.fixref.renamed"
  	
  	fi
  	#${plink2} --vcf "${workdir}/${filename}.fixref.vcf.gz" --set-all-var-ids chr@:#:\$r:\$a --new-id-max-allele-len 2000 --export vcf --out "${workdir}/${filename}.fixref.renamed"
  	
  	bgzip "${workdir}/${filename}.fixref.renamed.vcf"
  	tabix -0 -p vcf "${workdir}/${filename}.fixref.renamed.vcf.gz"

done

file1="AMD_GSA"
file2="Husain_AMD_GSA"

echo removing the vcf for files: ${file1} and ${file2}...
#rm "${workdir}/${file1}.vcf.gz" "${workdir}/${file2}.vcf.gz" "${workdir}/${file1}.fixref.vcf.gz"  "${workdir}/${file2}.fixref.vcf.gz"
	
#"${workdir}/${filename}.fixref.renamed"
echo merging the zipped files using bcftools
echo "$workdir/${file1}.fixref.renamed.vcf.gz"
echo "$workdir/${file2}.fixref.renamed.vcf.gz"

bcftools merge "$workdir/${file1}.fixref.renamed.vcf.gz" "$workdir/${file2}.fixref.renamed.vcf.gz" -Oz -o "$workdir/merged_AMD_GSA_vcf.gz" --threads 12
tabix -0 -p vcf "$workdir/merged_AMD_GSA_vcf.gz"
    
echo DONE!

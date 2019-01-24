#!/bin/bash

#set paths to program directory
homedir=`pwd`
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")

#set input and output paths
file=$1
outdir=$2

fname=`basename $file`
[[ -z "$outdir" ]] && outdir=`dirname $file`
outfile="$outdir/dosage-$fname"
outinfo="$outdir/$fname.infos"

#output new header
lines=`bcftools view -h $file" | wc -l`
bcftools view -h $file | head -$((lines-1)) >> $outfile
echo "##FORMAT<ID=DS,Number=1,Type=Float,Description=\"Minor allele dosage\">" >> $outfile
bcftools view -h $file | tail -1 >> $outfile

bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%QUAL\t%FILTER\n' $file > $outinfo

echo "beginning conversion of $file"

head_count=`bcftools view -h "$file" | tail -1 | wc -w`
indivs=$((head_count-9))

#run conversion utility
$scriptpath/convert $file indivs

echo "conversion done. zipping $outfile"

#compress output
bgzip $outfile
tabix $outfile
rm $outinfo

echo "$outfile zipped and ready to go!"

echo "beginning annotation $file"

bcftools annotate -a $outfile -c FORMAT/DS $file | bgzip -c > $outfile

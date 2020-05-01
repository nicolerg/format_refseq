#!/bin/R

# fix all_lengths files to concatenate related genomes 

library(data.table)

args = commandArgs(trailingOnly = T)
allf = args[1]
wd = args[2]

setwd(wd)

all_lengths = fread(allf, sep='\t', header=F)
colnames(all_lengths) = c('header','genome_length')

#####################################################################################################################
## fix weird taxonomy strings 
#####################################################################################################################

all_lengths[, kingdom := sapply(header, function(x) unname(unlist(strsplit(gsub('.*\\|','',x), ';')))[1])]
broken = all_lengths[!kingdom %in% c('Bacteria','Eukaryota','Viruses','Archaea')]
correct = all_lengths[kingdom %in% c('Bacteria','Eukaryota','Viruses','Archaea')]

fix_header = function(x){
  accn = unname(unlist(strsplit(x,'\\|')))[1]
  tax = unname(unlist(strsplit(x,'\\|')))[2]
  if(grepl('Bacteria;',tax)){
    tax = gsub('.*Bacteria;','Bacteria;',tax)
  }else if(grepl('Viruses;',tax)){
    tax = gsub('.*Viruses;','Viruses;',tax)
  }else if(grepl('bacteri|Salmonella|Staphylococcus|Lactobacillus|Francisella|Bacteroides|Leptospira|Klebsiella|Neorhizobium',x)){
    tax = paste0('Bacteria;',tax)
  }
  new = sprintf('%s|%s',accn,tax)
  return(new)
}

if(nrow(broken) > 0){

  broken[,new_header := sapply(header, fix_header)]
  broken[,kingdom := sapply(new_header, function(x) unname(unlist(strsplit(gsub('.*\\|','',x), ';')))[1])]
  print(table(broken[,kingdom]))

  correct[,new_header := NA]
  all_lengths = rbindlist(list(correct, broken), fill=T)
}else{
  correct[,new_header := header]
  all_lengths = correct
}

#####################################################################################################################
## collapse species 
#####################################################################################################################

# get species 
all_lengths[is.na(new_header), new_header := header]
all_lengths[, species := gsub('.*;','',new_header)]
all_lengths[, species := gsub('_str\\..*','',species)]
nrow(all_lengths)
length(unique(all_lengths[,species]))
all_lengths[,accn := gsub('\\|.*','\\|', new_header)]
all_lengths[,tax := gsub('.*\\|','', new_header)]
all_lengths[,short_tax := sapply(tax, function(x) paste(head(unname(unlist(strsplit(x, ';'))), -1), collapse=';')) ]
all_lengths[,new_tax := paste0(short_tax, ';', species)]
all_lengths[,c('short_tax', 'tax', 'new_header') := NULL]

nrow(all_lengths)
length(unique(all_lengths[,new_tax]))
dup_tax = all_lengths[,new_tax][duplicated(all_lengths[,new_tax])]

all_lengths[,genome_length := as.numeric(genome_length)]
new_lengths = all_lengths[,list(genome_length=sum(genome_length),
                                kingdom=unique(kingdom),
                                accn=accn[which.max(genome_length)]),
                          by=new_tax]
nrow(new_lengths)
new_lengths[,duplicated_genome := as.numeric(new_tax %in% dup_tax)]
new_lengths[,new_header := paste0(accn,new_tax)]
table(new_lengths[,duplicated_genome])

# merge back to get original headers
all_lengths = all_lengths[,.(header, new_tax)]
all_lengths = unique(all_lengths)
new_lengths = new_lengths[,.(new_header, genome_length, new_tax, duplicated_genome)]
merged = merge(all_lengths, new_lengths, by='new_tax')
merged[,new_tax := NULL]
head(merged)
nrow(merged)
length(unique(merged[,header]))
length(unique(merged[,new_header]))

write.table(merged, 'curated_all_lengths.txt', sep='\t', col.names=T, row.names=F, quote=F)

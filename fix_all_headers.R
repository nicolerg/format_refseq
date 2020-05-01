#!/bin/R

# fix all_lengths files to concatenate related genomes 

library(data.table)

args = commandArgs(trailingOnly = T)
allf = args[1]
wd = args[2]
outfile = args[3]

setwd(wd)

orig = fread(allf, sep='\t', header=F)
nrow(orig)
# NZ_LWSE01000084.1 >ACCN:NZ_LWSE01000000|Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacterales;Enterobacteriaceae;Escherichia;Escherichia_coli
colnames(orig) = c('version','header')
all_lengths = unique(orig[,.(header)])
nrow(all_lengths)

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

# remove strain/serotype substring
truncate_strain = function(x){
  s = unname(unlist(strsplit(x,'_')))
  if(length(s)>2){
    end = tail(s, 1)
    if( gsub('[0-9]+','',end) == '' | gsub('[A-Z]+','',end) == '' ){
      s = head(s, -1)
    }
  }
  p = paste(s, collapse='_')
  return(p)
}
all_lengths[, species := sapply(species, truncate_strain)]

nrow(all_lengths)
length(unique(all_lengths[,species]))
all_lengths[,accn := gsub('\\|.*','\\|', new_header)]
all_lengths[,tax := gsub('.*\\|','', new_header)]
all_lengths[,short_tax := sapply(tax, function(x) paste(head(unname(unlist(strsplit(x, ';'))), -1), collapse=';')) ]
all_lengths[,new_tax := paste0(short_tax, ';', species)]
all_lengths[,c('short_tax', 'tax', 'new_header') := NULL]

nrow(all_lengths)
length(unique(all_lengths[,new_tax]))

new_lengths = all_lengths[,list(kingdom=unique(kingdom),
                                accn=accn[1]),
                          by=new_tax]
nrow(new_lengths)
new_lengths[,new_header := paste0(accn,new_tax)]

# merge back to get original headers
all_lengths = all_lengths[,.(header, new_tax)]
all_lengths = unique(all_lengths)
new_lengths = new_lengths[,.(new_header, new_tax)]
merged = merge(all_lengths, new_lengths, by='new_tax')
merged[,new_tax := NULL]
head(merged)
nrow(merged)
length(unique(merged[,header]))
length(unique(merged[,new_header]))

# merge back to get genome 
master = merge(orig, merged, by='header')
nrow(orig)
nrow(master)

write.table(master, outfile, sep='\t', col.names=T, row.names=F, quote=F)

#PBS -l walltime=72:00:00
#PBS -l nodes=1:ppn=16
#PBS -l mem=10G
#PBS -o log/make_db_from_refseq-o.log
#PBS -e log/make_db_from_refseq-e.log

base=/projects/oh-lab/reffiles/VirusDB.update_Anita/REFSEQ/all
/bin/bash ${base}/src/format_refseq/make_db_from_refseq.sh ${base}

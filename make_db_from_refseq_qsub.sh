#PBS -l walltime=72:00:00
#PBS -l nodes=1:ppn=16
#PBS -o log/make_db_from_refseq-o.log
#PBS -e log/make_db_from_refseq-e.log

/bin/bash src/format_refseq/make_db_from_refseq.sh $(pwd)

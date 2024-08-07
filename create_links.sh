parallel 'mkdir -p results/genomes/{} && ln -s /run/media/ebecerra/lab_WIP/GenomeDownload/bacillota/{}/{}.faa results/genomes/{}' :::: bacillota.wflow.txt
parallel 'mkdir -p results/genomes/{} && ln -s /run/media/ebecerra/lab_WIP/GenomeDownload/bacillota/{}/{}_cds.tsv results/genomes/{}' :::: bacillota.wflow.txt
parallel 'mkdir -p results/genomes/{} && ln -s /run/media/ebecerra/lab_WIP/GenomeDownload/bacillota/{}/{}.gff results/genomes/{}' :::: bacillota.wflow.txt


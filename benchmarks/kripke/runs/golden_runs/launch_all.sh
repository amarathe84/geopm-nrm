
scriptname=$1

for nnodesval in 1536 768 512 384 256 128 64;
do
    bash -x $scriptname $nnodesval
done    


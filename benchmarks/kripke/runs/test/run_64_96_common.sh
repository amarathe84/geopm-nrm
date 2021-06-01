nranks=1536
nranks_per_socket=12
tracefilepath="/g/g92/marathe1/traces/kripke_traces/test/${nnodes}/${nranks}"
rank_input="--procs 16,6,16" 
omplist="1"
sockets_per_node=2

#nestlist="ZGD"
#for nestiter in DGZ DZG GDZ GZD ZDG ZGD;
#dsetlist="8"

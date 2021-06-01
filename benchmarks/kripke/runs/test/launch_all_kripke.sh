
for nnodevals in 1536 768 512 384 256 128;
do
   nesting_test=`dir -1 ~/traces/kripke_traces/64/${nnodevals} | grep ^n | head -n 1` 
   first_run=`dir -1 ~/traces/kripke_traces/64/${nnodevals}/${nesting_test}/ | head -n 1`
   nodelist=`find ~/traces/kripke_traces/64/${nnodevals}/${nesting_test}/${first_run}/ -depth -name "rank_*" \
             | head -n 512 | xargs grep -A 1 Timestamp | grep -v Timestamp |  grep -v "\-\-" | \
             sed "s/\t/;/g" | cut -d ";" -f 2 | sort -n | bc | uniq | sed "s/^/catalyst/g" | paste -sd","`
   salloc -N 64 -t 23:59:59 -w ${nodelist} --msr-safe bash -x ./kripke_common_test.sh ${nnodevals} & 
done

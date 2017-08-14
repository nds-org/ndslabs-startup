for id in {1..50}
do
   ndslabsctl --server http://172.17.0.5:30001/api import  -f users/user$id.json
done
for id in {1..50}
do
   ndslabsctl --server https://www.cmdev.ndslabs.org/api import -f users/user$id.json
done
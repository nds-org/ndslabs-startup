for id in {1..50}
do
 
   cat etk.tmpl | sed "s/NAME/User $id/g" | sed "s/USER_ID/user$id/g" | sed "s/EMAIL/user$id@ndslabs.org/g" > users/user$id.json
done
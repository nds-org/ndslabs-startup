#!/bin/bash
 
while IFS=, read role last first email
do
    namespace=`echo $email | cut -f1 -d@`
    etcdctl mkdir /ndslabs/accounts/$namespace
    etcdctl set /ndslabs/accounts/$namespace/account "{\"id\":\"\",\"name\":\"$first $last\",\"description\":\"PI4 Bootcamp $role\",\"namespace\":\"$namespace\",\"email\":\"$email\",\"password\":\"rlFq7PGfH5sZoYk9\",\"resourceLimits\":{\"cpuMax\":0,\"cpuDefault\":0,\"memMax\":0,\"memDefault\":0,\"storageQuota\":0},\"resourceUsage\":{\"cpu\":\"\",\"memory\":\"\",\"storage\":\"\",\"cpuPct\":\"\",\"memPct\":\"\"},\"status\":\"approved\",\"token\":\"6LY7_Ek63-E3kR0zOyu4CItmqtc\",\"organization\":\"UIUC\",\"lastLogin\":1495653926,\"inactiveTimeout\":1440}"
done < users.csv
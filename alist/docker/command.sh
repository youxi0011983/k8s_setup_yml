docker exec -it alist ./alist admin
# Randomly generate a password
docker exec -it alist ./alist admin random
# Manually set a password, `NEW_PASSWORD` refers to the password you need to set
docker exec -it alist ./alist admin set NEW_PASSWORD
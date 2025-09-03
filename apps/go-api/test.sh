# health
curl -s localhost:8080/healthz

# create
curl -s -X POST localhost:8080/api/v1/items \
  -H 'Content-Type: application/json' \
  -d '{"name":"Laptop Stand","description":"Aluminium","price":1499.00}'

# list
curl -s localhost:8080/api/v1/items

# get (replace ID)
curl -s localhost:8080/api/v1/items/1

# update (partial)
curl -s -X PUT localhost:8080/api/v1/items/f6741694-17e7-46fb-a97d-29366025f1d9 \
  -H 'Content-Type: application/json' \
  -d '{"price":1299.00}'

# delete
curl -i -X DELETE localhost:8080/api/v1/items/f6741694-17e7-46fb-a97d-29366025f1d9

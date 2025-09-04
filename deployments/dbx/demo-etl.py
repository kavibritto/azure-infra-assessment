df = spark.createDataFrame([
  ("Kavi", 100),
  ("Alex", 200),
  ("Zoe", 150)
], ["name", "amount"])

df.show()

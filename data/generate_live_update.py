#!/usr/bin/env python3
# Generate a live row insert for the demo
# Writes new transactions with incremented order IDs to simulate real-time operations.

import os
import csv
import random
from datetime import datetime
from faker import Faker

# Resolve script output path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "live_orders_update.csv")

print(f"Generating live transaction updates using Faker to {OUTPUT_FILE}...")

fake = Faker()
Faker.seed()

# Start order ID from a random high number or fixed number to avoid massive duplicates
start_order_id = random.randint(5000, 10000)

updates = []
for i in range(5):
    updates.append({
        "order_id": str(start_order_id + i),
        "customer_id": str(random.randint(1000, 9999)),
        "order_date": datetime.now().strftime("%Y-%m-%d"),
        "country": fake.country(),
        "amount": f"{round(random.uniform(20.0, 500.0), 2):.2f}",
        "status": random.choice(["COMPLETED", "COMPLETED", "COMPLETED", "PENDING", "CANCELLED"]),
        "email": fake.email()
    })

# Write fields
fields = ["order_id", "customer_id", "order_date", "country", "amount", "status", "email"]

with open(OUTPUT_FILE, mode="w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    writer.writerows(updates)

print("Live update CSV successfully generated with 5 dynamic, realistic records using Faker.")

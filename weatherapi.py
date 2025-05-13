import requests
import mysql.connector
from datetime import datetime
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

API_KEY = os.getenv("API_KEY")
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")

# List of cities
cities = ["Toronto", "Montreal", "Calgary", "Ottawa", "Edmonton", 
          "Mississauga", "Winnipeg", "Vancouver", "Brampton", "Hamilton"]

# Connect to MySQL
conn = mysql.connector.connect(
    host=MYSQL_HOST,
    user=MYSQL_USER,
    password=MYSQL_PASSWORD,
    database=MYSQL_DATABASE
)
cursor = conn.cursor()

# Create table with UNIQUE constraint on 'city'
cursor.execute("""
    CREATE TABLE IF NOT EXISTS weather (
        id INT AUTO_INCREMENT PRIMARY KEY,
        city VARCHAR(50) UNIQUE,
        temperature FLOAT,
        humidity INT,
        description VARCHAR(100),
        timestamp DATETIME
    )
""")

# Loop through each city and update weather data
for city in cities:
    try:
        url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
        response = requests.get(url)
        
        if response.status_code == 200:
            data = response.json()

            if "main" in data and "weather" in data:
                temp = data["main"].get("temp", None)
                humidity = data["main"].get("humidity", None)
                weather = data["weather"][0].get("description", None)
                timestamp = datetime.now()

                # Log the data being inserted
                print(f"Inserting data for {city}: Temp={temp}, Humidity={humidity}, Weather={weather}")

                cursor.execute("""
                    INSERT INTO weather (city, temperature, humidity, description, timestamp)
                    VALUES (%s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        temperature = VALUES(temperature),
                        humidity = VALUES(humidity),
                        description = VALUES(description),
                        timestamp = VALUES(timestamp)
                """, (city, temp, humidity, weather, timestamp))

                print(f"Weather data for {city} updated at {timestamp}")
            else:
                print(f"Missing weather data for {city}")
        else:
            print(f"Error fetching data for {city}: {response.status_code}")
    except Exception as e:
        print(f"Failed to fetch or update data for {city}: {e}")

# Finalize
conn.commit()
cursor.close()
conn.close()

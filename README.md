# Bee-Link-Health-Hive-Monitor-IOT-

### 📖 Project Overview
Bee-Link Health Hive Monitor (IoT + AI) is an intelligent beekeeping system that integrates IoT sensors with machine learning to provide real-time hive health monitoring and predictive insights. The system continuously collects environmental data such as temperature, humidity, light intensity, wind, and rain, then applies trained ML models to detect anomalies, predict swarming behavior, and identify potential hive health risks.

🔹 Tech Stack
Hardware/IoT: ESP32/ESP8266 microcontrollers, BMP280 (temperature/pressure), BH1750 (light), wind and rain sensors.

Backend: Python, Firebase Admin SDK, trained ML models (.pkl files).

Frontend: Flutter (Dart), modern UI with real-time alerts, reports, and visualizations.

Cloud Integration: Firebase for secure data storage, authentication, and notifications.

Version Control: Git + GitHub with .gitignore for secure repo management.

🔹 Machine Learning & Threshold Training
Model Training: Hive health prediction models trained on historical sensor datasets.

Threshold Logic: Configurable thresholds for temperature, humidity, and activity levels to trigger alerts when conditions deviate from healthy ranges.

Swarm Prediction: ML classifiers trained to detect early signs of swarming based on sensor patterns.

Hybrid Approach: Combines rule-based thresholds with ML predictions for robust monitoring.

Continuous Improvement: Models retrained periodically with new sensor data to improve accuracy.

⚠️ Security Note
Sensitive files such as serviceAccountKey.json and Firebase configs are excluded from version control for safety.

from flask import Flask
import joblib
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, db

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': ''
})

# Load models
swarm_model = joblib.load("swarm_model.pkl")
issue_model = joblib.load("issue_model.pkl")
health_model = joblib.load("health_model.pkl")
trend_model = joblib.load("trend_model.pkl")

swarm_encoder = joblib.load("swarm_encoder.pkl")
issue_encoder = joblib.load("issue_encoder.pkl")
trend_encoder = joblib.load("trend_encoder.pkl")
scaler = joblib.load("scaler.pkl")

app = Flask(__name__)

# -------------------- Alerts --------------------
def push_alert(sensor_name, sensor_value, message=None):
    ref = db.reference('alerts').child(sensor_name)
    alert_data = {
        'sensor': sensor_name,
        'value': sensor_value,
        'timestamp': datetime.now().isoformat(),
        'status': 'alert'
    }
    if message:
        alert_data['message'] = message
    ref.set(alert_data)

def clear_alert(sensor_name):
    ref = db.reference('alerts').child(sensor_name)
    ref.delete()

# -------------------- AI Results --------------------
def push_ai_results(swarm, issue, health, trend):
    # overwrite latest result
    db.reference('ai_results').set({
        'swarmRisk': swarm,
        'issueLabel': issue,
        'healthScore': int(health),
        'trend': trend,
        'timestamp': datetime.now().isoformat()
    })

    # log into history
    history_ref = db.reference('ai_history')
    history_ref.push({
        'swarmRisk': swarm,
        'healthScore': int(health),
        'trend': trend,
        'timestamp': datetime.now().isoformat()
    })

    # ✅ limit to last 5 entries
    history_data = history_ref.get()
    if history_data and isinstance(history_data, dict):
        keys = sorted(history_data.keys(), key=lambda k: history_data[k]['timestamp'])
        if len(keys) > 5:
            for old_key in keys[:-5]:
                history_ref.child(old_key).delete()

# -------------------- Helper --------------------
def extract_value(val, default=None):
    if val is None:
        return default
    if isinstance(val, dict):
        v = val.get('value')
        if isinstance(v, (int, float)):
            return int(v)
        return default
    if isinstance(val, (int, float)):
        return int(val)
    return default

# -------------------- Per-Sensor Handlers --------------------
def handle_temperature(event):
    value = extract_value(event.data)
    if value is None: return
    if value > 36 or value < 32:
        push_alert("temperature", value)
    else:
        clear_alert("temperature")

def handle_humidity(event):
    value = extract_value(event.data)
    if value is None: return
    if value < 50 or value > 80:
        push_alert("humidity", value)
    else:
        clear_alert("humidity")

def handle_weight(event):
    value = extract_value(event.data)
    if value is None: return
    if value < 310 or value > 1500:
        push_alert("weight", value)
    else:
        clear_alert("weight")

def handle_sound(event):
    value = extract_value(event.data)
    if value is None: return
    if value > 100:
        push_alert("sound", value)
    else:
        clear_alert("sound")

def handle_air_quality(event):
    value = extract_value(event.data)
    if value is None: return
    if value > 250:
        push_alert("air_quality", value)
    else:
        clear_alert("air_quality")

def handle_lid_status(event):
    value = extract_value(event.data)
    if value is None: return
    if value < 1022:
        push_alert("lid_status", value, "Lid Open")
    else:
        clear_alert("lid_status")

# -------------------- Attach Alert Listeners --------------------
db.reference('sensors/temperature').listen(handle_temperature)
db.reference('sensors/humidity').listen(handle_humidity)
db.reference('sensors/weight').listen(handle_weight)
db.reference('sensors/sound').listen(handle_sound)
db.reference('sensors/air_quality').listen(handle_air_quality)
db.reference('sensors/lid_status').listen(handle_lid_status)

# -------------------- AI Root Listener --------------------
def process_all_sensors(event):
    print("AI listener triggered:", event.path, event.data)

    sensors = db.reference('sensors').get()
    if not sensors or not isinstance(sensors, dict):
        return

    temperature = extract_value(sensors.get('temperature'))
    humidity = extract_value(sensors.get('humidity'))
    weight = extract_value(sensors.get('weight'))
    sound = extract_value(sensors.get('sound'))
    air_quality = extract_value(sensors.get('air_quality'))

    if None in [temperature, humidity, weight, sound, air_quality]:
        return

    features = scaler.transform([[temperature, humidity, weight, sound, air_quality]])

    swarm = swarm_encoder.inverse_transform(swarm_model.predict(features))[0]
    issue = issue_encoder.inverse_transform(issue_model.predict(features))[0]
    health = int(health_model.predict(features)[0])
    trend = trend_encoder.inverse_transform(trend_model.predict(features))[0]

    print("AI prediction:", swarm, issue, health, trend)

    push_ai_results(swarm, issue, health, trend)

# Attach AI listeners to each sensor
db.reference('sensors/temperature').listen(process_all_sensors)
db.reference('sensors/humidity').listen(process_all_sensors)
db.reference('sensors/weight').listen(process_all_sensors)
db.reference('sensors/sound').listen(process_all_sensors)
db.reference('sensors/air_quality').listen(process_all_sensors)

if __name__ == "__main__":
    app.run(debug=True, use_reloader=False)

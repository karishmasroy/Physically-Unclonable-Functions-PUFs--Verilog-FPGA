import serial
import time
import csv
import random

SERIAL_PORT = "COM6"
BAUD_RATE = 115200
NUM_CRPS = 10000
SYNC_BYTE = 0x5A
OUTPUT_FILE = "Board4_Run7.csv" # Change to B for second board

def collect_8xor_crps():
    print(f"Connecting to {SERIAL_PORT}...")
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1.0)
        time.sleep(2)
        ser.reset_input_buffer()
    except:
        print("Port Error."); return

    random.seed(42)
    challenges = [f"{random.getrandbits(64):016X}" for _ in range(NUM_CRPS)]
    crp_data = []

    print("Collecting 8-XOR responses (1 bit per challenge)...")
    for i, ch_hex in enumerate(challenges):
        ser.write(bytes([SYNC_BYTE]))
        ser.write(bytes.fromhex(ch_hex))
        
        response_raw = ser.read(1)
        if response_raw:
            resp_bit = ord(response_raw) & 0x01
            crp_data.append([ch_hex, resp_bit])
        
        if (i+1) % 500 == 0:
            print(f"Progress: {i+1}/{NUM_CRPS}")

    with open(OUTPUT_FILE, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["Challenge_Hex", "Response_Bit"])
        writer.writerows(crp_data)
    
    print(f"Done! 8-XOR data saved to {OUTPUT_FILE}")
    ser.close()

if __name__ == "__main__":
    collect_8xor_crps()
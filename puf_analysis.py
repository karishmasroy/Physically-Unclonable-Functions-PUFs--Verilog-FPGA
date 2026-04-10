import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
from itertools import combinations

# ============================================================
# CONFIGURATION
# ============================================================
BOARDS = [1, 2, 3, 4]
RUNS = [1, 2, 3, 4, 5, 6, 7]
DATA_DIR = "PUF_Data"  # Put all 35 CSVs in this folder
BASE_NAME = "Board{}_Run{}.csv"

def load_all_data():
    all_data = {}
    for b in BOARDS:
        all_data[b] = {}
        for r in RUNS:
            fname = os.path.join(DATA_DIR, BASE_NAME.format(b, r))
            if os.path.exists(fname):
                df = pd.read_csv(fname)
                # Keep only Response_Bit and index it by Challenge_Hex
                all_data[b][r] = df.set_index('Challenge_Hex')['Response_Bit']
            else:
                print(f"Warning: Missing {fname}")
    return all_data

def calculate_metrics():
    data = load_all_data()
    
    # --- 1. UNIFORMITY ---
    # Average of '1's per board across all runs
    board_uniformity = {}
    for b in BOARDS:
        bits = []
        for r in RUNS:
            if r in data[b]: bits.append(data[b][r].values)
        if bits:
            board_uniformity[b] = np.mean(np.concatenate(bits))

    # --- 2. RELIABILITY (Intra-device) ---
    # 1 - (Average HD between different runs of the same board)
    board_reliability = {}
    for b in BOARDS:
        hd_scores = []
        run_pairs = list(combinations(RUNS, 2))
        for r1, r2 in run_pairs:
            if r1 in data[b] and r2 in data[b]:
                # Align challenges
                common = data[b][r1].index.intersection(data[b][r2].index)
                hd = np.mean(data[b][r1].loc[common] != data[b][r2].loc[common])
                hd_scores.append(hd)
        if hd_scores:
            board_reliability[b] = (1 - np.mean(hd_scores)) * 100

    # --- 3. UNIQUENESS (Inter-device) ---
    # HD between different boards (using Run 1 of each as the reference)
    uniqueness_scores = []
    board_pairs = list(combinations(BOARDS, 2))
    for b1, b2 in board_pairs:
        if 1 in data[b1] and 1 in data[b2]:
            common = data[b1][1].index.intersection(data[b2][1].index)
            hd = np.mean(data[b1][1].loc[common] != data[b2][1].loc[common])
            uniqueness_scores.append(hd)
    
    avg_uniqueness = np.mean(uniqueness_scores) if uniqueness_scores else 0

    # --- 4. BIT ALIASING ---
    # Probability of a bit being '1' across different devices for the same challenge
    # We take Run 1 from each board and see if they "alias" (always '1' or '0')
    aliasing_bits = []
    for b in BOARDS:
        if 1 in data[b]: aliasing_bits.append(data[b][1])
    
    # Align all boards
    combined = pd.concat(aliasing_bits, axis=1).dropna()
    bit_aliasing_per_challenge = combined.mean(axis=1)
    overall_bit_aliasing = np.mean(np.abs(bit_aliasing_per_challenge - 0.5))

    # ============================================================
    # OUTPUT REPORT
    # ============================================================
    print("\n" + "="*50)
    print("      MULTI-BOARD PUF STATISTICAL REPORT")
    print("="*50)
    
    print(f"\n[1] UNIFORMITY (Ideal: 0.5)")
    for b, u in board_uniformity.items():
        print(f"    Board {b}: {u:.4f}")

    print(f"\n[2] RELIABILITY (Ideal: 100%)")
    for b, r in board_reliability.items():
        print(f"    Board {b}: {r:.2f}%")

    print(f"\n[3] INTER-DEVICE UNIQUENESS (Ideal: 0.5)")
    print(f"    Average Uniqueness (HD_inter): {avg_uniqueness:.4f}")

    print(f"\n[4] BIT ALIASING (Ideal: 0.0)")
    print(f"    Mean Bias across devices: {overall_bit_aliasing:.4f}")

    # --- Visualization ---
    plt.figure(figsize=(12, 5))
    
    # Plot Reliability vs Uniformity
    plt.subplot(1, 2, 1)
    plt.bar(board_reliability.keys(), board_reliability.values(), color='teal')
    plt.ylim(90, 100)
    plt.title("Reliability per Board")
    plt.ylabel("Percentage (%)")

    # Plot Uniqueness Distribution
    plt.subplot(1, 2, 2)
    plt.hist(uniqueness_scores, bins=10, color='orange', edgecolor='black')
    plt.axvline(0.5, color='red', linestyle='--')
    plt.title("Inter-device HD Distribution")
    plt.xlabel("Hamming Distance")

    plt.tight_layout()
    plt.savefig("MultiBoard_Report.png")
    plt.show()

if __name__ == "__main__":
    calculate_metrics()
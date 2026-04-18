# Crypto Tracing SOP

> **Scope:** Bitcoin, Ethereum, Litecoin wallet attribution and flow analysis  
> **Workstation:** Crypto Tracing VM (10.0.20.60)  
> **Tools:** GraphSense, BlockSci, SpiderFoot, Jupyter notebooks

---

## Pre-Tracing Checklist

- [ ] Target wallet address(es) documented in TheHive case observables
- [ ] Legal authorisation for blockchain analysis confirmed
- [ ] Blockchain data sync verified: `bitcoin-cli getblockchaininfo`
- [ ] Case output directory created: `/opt/crypto/output/<CASE_ID>/`

---

## Step 1 — Initial Address Triage

```bash
CASE_ID="CHANGEME"
TARGET_ADDR="CHANGEME"
OUTPUT="/opt/crypto/output/${CASE_ID}"
mkdir -p $OUTPUT

# Quick SpiderFoot OSINT pivot on the address
/opt/crypto/spiderfoot/venv/bin/python /opt/crypto/spiderfoot/sf.py \
  -s "${TARGET_ADDR}" \
  -t BITCOIN_ADDRESS \
  -o /opt/crypto/output/${CASE_ID}/spiderfoot-${TARGET_ADDR}.json \
  -q
```

Or via SpiderFoot web UI at `http://10.0.20.60:5001`:
1. New Scan → Target: `<wallet_address>`, Type: `Bitcoin Address`
2. Modules: Enable `sfp_blockchain`, `sfp_bitcoinabuse`, `sfp_etherscan`

---

## Step 2 — Transaction Graph Analysis (BlockSci)

Open Jupyter at `http://10.0.20.60:8888` and use `bitcoin-tracing.ipynb`:

```python
import blocksci
chain = blocksci.Blockchain('/opt/crypto/data/bitcoin')

# Load target address
addr = chain.address_from_string(TARGET_ADDR)
print(f"Balance: {addr.balance()/1e8:.8f} BTC")
print(f"Transactions: {len(addr.txes.to_list())}")

# Get all connected addresses via common-input-ownership
cluster_mgr = blocksci.cluster.ClusterManager('/opt/crypto/data/clusters', chain)
cluster = cluster_mgr.cluster_with_address(addr)
print(f"Cluster size: {cluster.size()} addresses")
```

---

## Step 3 — Wallet Clustering

```python
# Export full cluster for exchange attribution
cluster_addrs = [str(a) for a in cluster.addresses.to_list()]

import pandas as pd
df = pd.DataFrame({'address': cluster_addrs})
df.to_csv(f'{OUTPUT}/cluster-{TARGET_ADDR[:8]}.csv', index=False)
print(f"Exported {len(df)} clustered addresses")
```

Cross-reference with known exchange deposit addresses:
- [WalletExplorer.com](https://www.walletexplorer.com) (no account needed)
- [OXT.me](https://oxt.me) — transaction graph visualisation
- Check `hunts/velociraptor/crypto-wallets.vql` for on-device wallet files

---

## Step 4 — Transaction Flow Tracing

```python
# Follow funds forward — where did the money go?
def trace_forward(address, depth=3, min_btc=0.001):
    results = []
    for tx in address.txes.to_list():
        for out in tx.outputs.to_list():
            if out.value / 1e8 >= min_btc:
                results.append({
                    'txid':     str(tx.hash),
                    'timestamp': str(tx.block_time),
                    'to_addr':  str(out.address) if out.address else 'unknown',
                    'value_btc': out.value / 1e8,
                    'depth':    depth
                })
    return results

flows = trace_forward(addr, depth=3)
pd.DataFrame(flows).to_csv(f'{OUTPUT}/forward-flows.csv', index=False)
```

---

## Step 5 — Exchange Attribution

Known exchange cold wallet files are in `/opt/crypto/data/exchange-wallets/`.

```bash
# Check if any clustered address is a known exchange deposit address
python3 - << 'EOF'
import json, csv

with open('/opt/crypto/data/exchange-wallets/known-exchanges.json') as f:
    known = json.load(f)

with open(f'/opt/crypto/output/${CASE_ID}/cluster-${TARGET_ADDR[:8]}.csv') as f:
    cluster = [row['address'] for row in csv.DictReader(f)]

matches = [(addr, known[addr]) for addr in cluster if addr in known]
for addr, exchange in matches:
    print(f"MATCH: {addr} → {exchange}")
EOF
```

---

## Step 6 — GraphSense Dashboard

Access GraphSense at `http://10.0.20.60:3000`:

1. Enter target address in search
2. Navigate the transaction graph visually
3. Export graph as PNG for case reporting

---

## Step 7 — Document and Report

```bash
# Hash all outputs
generate-manifest /opt/crypto/output/${CASE_ID}/

# Copy to evidence NAS
cp -r /opt/crypto/output/${CASE_ID}/ /mnt/evidence/cases/${CASE_ID}/crypto/

# Add to TheHive
# - Observables: all identified wallet addresses, exchange names, transaction IDs
# - Tags: cryptocurrency, bitcoin, exchange-attribution
# - Attach: flow diagrams, cluster CSV, GraphSense export
```

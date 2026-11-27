# ADRF revised experiments

The original contract remains unchanged. `../AutonomousDRF_v_2.1.4.sol` is the corrected implementation; the original v2.1.3 contract is the baseline for comparisons.

Run from the parent ADRF directory with Python 3.10, eth-brownie 1.21.0 (dependencies), solc 0.5.17 and Ganache 7.9.2. See `workflows/refined.yml` for the original environment and commands; it is archived as documentation, not an active workflow. Start a fresh Ganache instance for each configuration, then run `python experiments/refined.py n m 10`. Save each resulting results.json separately. The seed is 20261126. The steady_state directory contains the published aggregate measurements, regressions and SVG figures. Raw per-user records can be regenerated with the script.

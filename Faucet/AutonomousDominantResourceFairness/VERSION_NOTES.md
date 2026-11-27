# ADRF v2.1.4 — November 2026

This release corrects the original v2.1.3 implementation without changing the allocation design.

- Initialise both resource pools rather than initialising the first twice.
- Track demand epochs and scaled-demand reset epochs separately for each cyclic pool.
- Exclude stale or absent demand pools from cycle calculation, setting the cycle count to zero when no valid demands exist.
- Select the minimum scaled reciprocal of the dominant share, corresponding to the maximum dominant share.
- Require a demand in the immediately preceding epoch before permitting a claim, including exclusion of first-epoch claims.

The original v2.1.3 contract remains unchanged. The revised implementation matched exact rational PDRF allocations in all 11,800 tested user-round cases. This empirical result does not establish exact equivalence for arbitrary fixed-point inputs.

The revision, experimental scripts and manuscript review were conducted with assistance from OpenAI ChatGPT in November 2026.

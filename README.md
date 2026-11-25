# ESM and SPES/CCEP practice survey: analysis code

MATLAB code for the survey of electrical stimulation practices (functional mapping and SPES/CCEP) in stereo-EEG and subdural recordings.

## Scripts

| Script | Purpose |
|---|---|
| `ESM-SPES-CCEP-figures.m` | Generates all figures (PNG, 300 dpi) |
| `ESM-SPES-CCEP-stats.m` | Computes the numbers reported in the manuscript (counts, percentages, Table 1) and the association analyses |

## Requirements

- MATLAB R2022a or later (figure script); R2019b or later (stats script)
- Statistics and Machine Learning Toolbox (figure script only)
- [master_ColorMaps](https://github.com/sakkol/master_ColorMaps) on the MATLAB path (figure script only)

## Data

The survey export is not included because it contains identifying information. Place it in a `data/` folder next to the scripts and set `dataFile` in the Config section of each script (sheet name: `Form Responses 1`).

## Usage

1. Add `master_ColorMaps` to the MATLAB path.
2. Run `ESM-SPES-CCEP-figures.m` and `ESM-SPES-CCEP-stats.m` from the MATLAB editor, or with `run('ESM-SPES-CCEP-figures.m')` (the hyphens mean the scripts cannot be called by name alone).

Both scripts write to the same `results/` folder, which is created automatically.

```
.
├── ESM-SPES-CCEP-figures.m
├── ESM-SPES-CCEP-stats.m
├── data/       (not tracked)
└── results/    (not tracked)
```

## Outputs

- Figures: `*.png`
- `manuscript_numbers_report.txt`: full report of all numbers, in manuscript order
- `numbers_long.csv`: every tabulated count with its denominator and percentage
- `stats_region_KW.csv`, `stats_agegroup_KW.csv`, `stats_ieegvolume_spearman.csv`: association results

## Statistics

- Ordinal outcomes by region and age group: permutation Kruskal-Wallis
- Annual iEEG volume vs ESM outcomes: permutation Spearman correlation
- Benjamini-Hochberg FDR within each family of tests
- 10,000 permutations with a fixed random seed (`rngSeed`), so results are reproducible

## Citation

Manuscript is under review.

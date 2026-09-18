# Spatial parameters for a preliminary IUCN Red List assessment (Criterion B) using ConR

This repository provides an R script and an example occurrence dataset used
to calculate the spatial and population parameters required for a
preliminary conservation assessment under **Criterion B** of the IUCN Red
List Categories and Criteria.

## What this calculates

Using georeferenced occurrence records analysed in R (R Core Team) with the
package **ConR v.2.1** (Dauby et al. 2017), the script estimates:

- **Extent of Occurrence (EOO)** — convex hull method
- **Area of Occupancy (AOO)** — 2 × 2 km grid
- **Number of locations** — 10 km grid
- **Dispersal radius** used to delimit subpopulations, as a proxy for the
  species' dispersal ability (Rivers et al. 2010)
- **Number of subpopulations**
- **Degree of severe fragmentation** among subpopulations

These spatial parameters are the inputs used to perform a preliminary
conservation assessment following IUCN (2012) and the IUCN Standards and
Petitions Committee (2024) guidelines.

## What this does NOT do

This script does **not** assign a final Red List category (e.g. CR, EN,
VU, NT, LC). The parameters it outputs must be interpreted against the
thresholds and decision rules of the IUCN Red List Guidelines
(https://www.iucnredlist.org/resources/redlistguidelines) to reach a
preliminary category. That interpretation step is intentionally left to
the user/assessor.

## Files

| File | Description |
|---|---|
| `IUCN_assessment.R` | Commented R script that runs the full workflow, from reading occurrence data to summarising the spatial parameters. |
| `georeferenced_specimens.csv` | Example occurrence dataset (georeferenced records for one species). Columns: `tax` (taxon name), `voucher` (specimen/record identifier), `ddlat`/`ddlon` (decimal-degree coordinates), `source` (`original` or `estimated` coordinate). |

## Requirements

- R (≥ 4.0; developed under R v.4.4.2)
- R packages: `ConR` (development version, **not** the CRAN release —
  function names differ between versions), `sf`, `rnaturalearth`

```r
install.packages("devtools")
devtools::install_github("gdauby/ConR")   # ConR v.2.1 (development branch)
install.packages(c("sf", "rnaturalearth"))
```

## How to run

1. Keep `IUCN_assessment.R` and `georeferenced_specimens.csv` in the same folder (or an R
   Project created in that folder).
2. Open `IUCN_assessment.R` in R/RStudio and run it top to bottom.
3. The script prints/returns EOO, AOO, number of subpopulations, number of
   locations, and the severe-fragmentation result, plus a simple map of the
   EOO polygon.

## Citation

If you use this script or data, please cite:

> Vasconcelos, CC (2026). R script and example data to calculate IUCN Red List Criterion B spatial parameters using ConR.
> Zenodo. https://doi.org/10.5281/zenodo.22822017

And the underlying method/package:

> Dauby, G., Stévart, T., Droissart, V., Cosiaux, A., Deblauwe, V.,
> Simo-Droissart, M., Sosef, M.S.M., Lowry, P.P., Schatz, G.E., Gereau,
> R.E., Couvreur, T.L.P. (2017). ConR: An R package to assist large-scale
> multispecies preliminary conservation assessments using distribution
> data. *Ecology and Evolution*, 7(24), 11292–11303.
> https://doi.org/10.1002/ece3.3704
>
> Rivers, M.C., Bachman, S.P., Meagher, T.R., Lughadha, E.N., Brummitt,
> N.A. (2010). Subpopulations, locations and fragmentation: applying IUCN
> red list criteria to herbarium specimen data. *Biodiversity and
> Conservation*, 19, 2071–2085. https://doi.org/10.1007/s10531-010-9826-9
>
> IUCN Standards and Petitions Committee (2024). Guidelines for Using the
> IUCN Red List Categories and Criteria. Version 16.
> https://www.iucnredlist.org/resources/redlistguidelines

## License

Code and data are released under the Creative Commons Attribution 4.0
International license (CC BY 4.0).

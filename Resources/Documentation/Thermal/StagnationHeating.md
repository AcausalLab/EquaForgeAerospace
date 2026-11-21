---
class: EquaForgeAerospace.Thermal.StagnationHeating
keywords: [heating, Sutton-Graves, stagnation point, entry, heat shield, heat flux]
see_also: [EquaForgeVC.Thermal.HeatCapacitor, EquaForgeVC.Thermal.BodyRadiation, EquaForgeAerospace.GNC.EntryAttitude, EquaForgeAerospace.Examples.EntryHeating]
figures: [../figures/stagnation.svg]
validation: [unit.aerospace, examples.study.StarshipMission_Analysis]
page_type: block
---
## Description

How hot an entry gets. The convective heat flux into a blunt nose grows with the square root of
the air's density and the cube of the speed (Sutton and Graves). That puts the peak heating high
up, where the vehicle is still fast. The heat flow into a heat shield follows from its area and a
factor for the mean flux over it.

![Stagnation-point heating of a blunt nose](../figures/stagnation.svg)

Air of density $\rho$ arrives at speed $V$, is stopped behind the bow shock (dashed) and heats
the stagnation point at the flux $q$. The nose has radius $R_n$.

## Assumptions

The flow is hypersonic and the shock layer is in chemical equilibrium. The wall is cold compared
with the gas. Radiative heating from the shock layer, which matters above about 10 km/s, is left
out. The mean flux over the shield is a fixed share of the stagnation-point flux.

## Equations

$$q=k\sqrt{\frac{\rho}{R_n}}\,V^3,\qquad \dot Q=q\,A\,f$$

| Symbol | Meaning | Unit |
|---|---|---|
| $q$ | Heat flux at the stagnation point | W/m² |
| $k$ | Sutton–Graves constant of air, $1.7415\times10^{-4}$ | kg^0.5/m |
| $\rho,V$ | Air density and speed | kg/m³, m/s |
| $R_n$ | Effective nose radius | m |
| $A,f$ | Heated area and `shapeFactor` (mean / stagnation flux) | m², 1 |
| $\dot Q$ | Heat flow into the shield (`Q_flow`) | W |

## How to use

Drive a `Thermal.PrescribedHeatFlow` into the heat shield's `HeatCapacitor`. Let the shield
radiate to space with `BodyRadiation` and conduct inwards with a `ThermalConductor`. For a vehicle
that enters belly-first, the effective nose radius is about the body's radius.

## Validation

`unit.aerospace` checks the flux at $\rho = 10^{-4}$ kg/m³ and $V$ = 7 km/s against the formula.
The `StarshipMission_Analysis` worksheet recomputes the heating of the ship's entry from its
altitude and speed and compares it with the block. It then checks that the shield's peak
temperature stays inside the tiles' range.

## References

K. Sutton and R. A. Graves, *A General Stagnation-Point Convective-Heating Equation for
Arbitrary Gas Mixtures*, NASA TR R-376, 1971.

---
class: EquaForgeAerospace.Environment.AtmosphereUS76
keywords: [atmosphere, US76, standard atmosphere, density, pressure, temperature, speed of sound]
see_also: [EquaForgeAerospace.Environment.AirData, EquaForgeAerospace.Thermal.StagnationHeating]
figures: [../figures/us76.svg]
validation: [unit.aerospace]
page_type: block
---
## Description

The standard atmosphere of the United States (1976) from the ground to 1000 km. It gives the
density, pressure, temperature and speed of sound at a geometric altitude. Up to 86 km the air
is seven layers of constant temperature gradient. Above that the block interpolates the
tabulated density of the thermosphere on a logarithmic scale.

![Temperature and density of the standard atmosphere](../figures/us76.svg)

The temperature $T$ (K) against the altitude $h$ (km) up to 86 km, with the layers' bases
dashed, and the density $\rho$ (kg/m³, logarithmic) up to 300 km.

## Assumptions

The air is a dry ideal gas in hydrostatic equilibrium. Altitudes are geometric, converted to
geopotential altitudes for the layers. Above 86 km the temperature shown stays at its 86 km
value: the speed of sound there no longer matters for flight. The density between table points
follows straight lines in its logarithm, so its slope changes at the table's altitudes. The
block raises no events at the layer boundaries.

## Equations

$$H=\frac{r_0\,h}{r_0+h}$$

$$T=T_b+L_b\,(H-H_b),\qquad p=\begin{cases}p_b\left(\dfrac{T_b}{T}\right)^{g_0/(R L_b)},&L_b\ne0\\p_b\exp\left(-\dfrac{g_0\,(H-H_b)}{R\,T_b}\right),&L_b=0\end{cases}$$

$$\rho=\frac{p}{R\,T},\qquad a=\sqrt{1.4\,R\,T}$$

| Symbol | Meaning | Unit |
|---|---|---|
| $h,H$ | Geometric and geopotential altitude | m |
| $r_0$ | Earth radius of the geopotential, 6 356 766 m | m |
| $T_b,p_b,H_b,L_b$ | Base temperature, pressure, altitude and lapse rate of the layer | K, Pa, m, K/m |
| $R$ | Gas constant of air, 287.053 J/(kg K) | J/(kg K) |
| $g_0$ | Standard gravity | m/s² |
| $\rho,a$ | Density and speed of sound | kg/m³, m/s |

## How to use

Feed the altitude from `AirData` or `GNC.GroundTrack`. Connect `rho` and `a` back to `AirData`
for the Mach number and dynamic pressure, and `p` to the engines' ambient pressure.

## Validation

`unit.aerospace` compares the temperature, pressure and density at 0, 11, 20, 50 and 80 km with
the published table, within 0.5 %. It also checks the speed of sound at sea level, 340.29 m/s.

## References

*U.S. Standard Atmosphere, 1976*, NOAA, NASA and USAF, NOAA-S/T 76-1562, Washington, 1976.

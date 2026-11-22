---
class: EquaForgeAerospace.GNC.EntryAttitude
keywords: [entry, angle of attack, bank angle, belly flop, attitude command]
see_also: [EquaForgeAerospace.GNC.AttitudeError, EquaForgeAerospace.Aerodynamics.BodyAero, EquaForgeAerospace.Thermal.StagnationHeating]
figures: [../figures/entry.svg]
validation: [examples.model.StarVesselMission.ShipEntryLanding]
page_type: block
---
## Description

Where a vehicle should point to fly at a given angle of attack and bank angle. The nose rises
above the airspeed by `alpha`, in the plane that the `bank` angle turns about the airspeed. With
zero bank the lift points up. The belly faces the flow. Use it for a capsule or a winged
vehicle in entry, or for a belly-flop at about 90°.

![Nose and belly directions for flight at an angle of attack](../figures/entry.svg)

The airspeed direction is $\mathbf{e}_v$, and $\mathbf{n}$ is up, square to it. The nose
$\mathbf{d}$ is at the angle $\alpha$ above $\mathbf{e}_v$, and the belly reference
$\mathbf{b}$ is square to the nose, facing the flow. The bank turns both about $\mathbf{e}_v$.

## Assumptions

The airspeed is the velocity relative to the turning Earth; the wind is left out. The local
vertical must not be along the airspeed: the block is meant for flight across the air, not
straight down. Near a vertical fall, fade the bank out, as the `StarVesselMission` ship does
between Mach 2 and Mach 1.

## Equations

$$\mathbf{e}_v=\frac{\mathbf{v}-\boldsymbol{\omega}_E\times\mathbf{r}}{|\mathbf{v}-\boldsymbol{\omega}_E\times\mathbf{r}|},\qquad \mathbf{n}=\frac{\mathbf{u}-(\mathbf{u}\cdot\mathbf{e}_v)\,\mathbf{e}_v}{|\mathbf{u}-(\mathbf{u}\cdot\mathbf{e}_v)\,\mathbf{e}_v|},\qquad \mathbf{u}=\frac{\mathbf{r}}{|\mathbf{r}|}$$

$$\mathbf{n}_b=\cos\sigma\,\mathbf{n}+\sin\sigma\,\mathbf{e}_v\times\mathbf{n}$$

$$\mathbf{d}=\cos\alpha\,\mathbf{e}_v+\sin\alpha\,\mathbf{n}_b,\qquad \mathbf{b}=\sin\alpha\,\mathbf{e}_v-\cos\alpha\,\mathbf{n}_b$$

| Symbol | Meaning | Unit |
|---|---|---|
| $\mathbf{r},\mathbf{v}$ | Position and velocity, world frame | m, m/s |
| $\boldsymbol{\omega}_E$ | Rotation of the Earth | rad/s |
| $\alpha,\sigma$ | Angle of attack and bank angle (`alpha`, `bank`) | rad |
| $\mathbf{d},\mathbf{b}$ | `direction` (nose) and `rollReference` (belly) | 1 |

## How to use

Feed both outputs to an `AttitudeError`. Schedule `alpha` with the Mach number: high for heating
and drag in hypersonic flight, then the belly-flop angle lower down. Steer the downrange and
crossrange with `bank`.

## Validation

The `StarVesselMission` ship flies its entry and belly-flop with this block
(`examples.model.StarVesselMission.ShipEntryLanding`). Its worksheet checks the heating that results
against Sutton–Graves.

## References

F. J. Regan and S. M. Anandakrishnan, *Dynamics of Atmospheric Re-Entry*, AIAA, 1993.

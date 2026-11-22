---
class: EquaForgeAerospace.Aerodynamics.BodyAero
keywords: [aerodynamics, normal force, axial force, centre of pressure, cross flow, belly flop, angle of attack]
see_also: [EquaForgeAerospace.Environment.AirData, EquaForgeAerospace.Aerodynamics.Flap, EquaForgeAerospace.Aerodynamics.GridFinSet]
figures: [../figures/bodyaero.svg]
validation: [examples.model.StarVesselMission.ShipEntryLanding]
page_type: block
---
## Description

The air's force on a cylindrical vehicle at any angle of attack. The flight can be nose-first
through the climb, broadside in a belly-first fall, or tail-first in a booster's return. The
axial force comes from a table against Mach number. The normal force is the slender-body slope
at small angles plus the cross-flow drag of the body, which dominates broadside. Both act at a
centre of pressure that moves with the angle of attack. A rotary damping moment opposes pitching
and yawing.

![Forces on a slender body](../figures/bodyaero.svg)

The airspeed $\mathbf{v}$ makes the angle $\alpha_t$ with the body's axis $x_b$. The axial
force $A$ and the normal force $N$ act at the centre of pressure, $x_{cp}$ along the axis from
`frame_b`.

## Assumptions

The body is a cylinder of reference area $S$ (its cross-section) and planform $\lambda S$. The
normal force follows the Jorgensen cross-flow model. Coefficients depend on the Mach number
(axial) and the angle of attack, not on the Reynolds number. The damping moment linearises the
extra cross flow that a turning body meets along its length.

## Equations

With the cross-flow speed $V_c=\sqrt{v_y^2+v_z^2}$, its direction $(e_y,e_z)$ and the total
angle of attack, $\cos\alpha_t=v_x/V$ and $\sin\alpha_t=V_c/V$:

$$C_A=C_{A0}(M)\,k_t\cos\alpha_t\,|\cos\alpha_t|,\qquad C_N=C_{N\alpha}\sin\alpha_t\,|\cos\alpha_t|+C_{Dc}\,\lambda\sin^2\alpha_t$$

$$\mathbf{F}=-\bar{q}\,S\,(C_A,\;C_N e_y,\;C_N e_z),\qquad x_{cp}=x_{\text{nose or tail}}\cos^2\alpha_t+x_{\text{broadside}}\sin^2\alpha_t$$

$$\mathbf{M}=x_{cp}\,\mathbf{e}_x\times\mathbf{F}+\mathbf{M}_d,\qquad \mathbf{M}_d=-\bar{q}\,\frac{\sin\alpha_t}{V}\,C_{Dc}\,\lambda\,S\,\frac{L^2}{12}\begin{pmatrix}0\\(1+e_z^2)\,\omega_y-e_ye_z\,\omega_z\\(1+e_y^2)\,\omega_z-e_ye_z\,\omega_y\end{pmatrix}$$

$k_t$ is `CA_tailFactor` in tail-first flight ($\cos\alpha_t<0$) and 1 otherwise. The
nose-first or tail-first place of the centre of pressure is chosen the same way.

| Symbol | Meaning | Unit |
|---|---|---|
| $\mathbf{v},V$ | Velocity through the air in body axes, and its size | m/s |
| $\bar{q},M$ | Dynamic pressure and Mach number | Pa, 1 |
| $S$ | Reference area | m² |
| $\lambda$ | `planformRatio`: planform / reference area | 1 |
| $L$ | Length of the body, $\lambda\sqrt{4S/\pi}$ | m |
| $C_{A0},C_{N\alpha},C_{Dc}$ | Axial coefficient, normal-force slope, cross-flow drag | 1, 1/rad, 1 |
| $\omega_y,\omega_z$ | Pitch and yaw rates | rad/s |

## How to use

Place `frame_b` at the vehicle's reference frame. Feed `v_air`, `qbar` and `Mach` from
`AirData`. Pick the places of the centre of pressure from the vehicle's shape: forward of the
middle nose-first, at the middle of the planform broadside. A vehicle that must fall
belly-first stably needs its centre of mass forward of the broadside centre of pressure, or
flaps to trim it.

## Validation

The `StarVesselMission` ship falls belly-first and trims with its flaps
(`examples.model.StarVesselMission.ShipEntryLanding`). Its booster falls tail-first under grid fins
(`BoosterReturn`). No unit test compares the coefficients with wind-tunnel data: they are
illustrative and belong to the user's vehicle.

## References

L. H. Jorgensen, *Prediction of Static Aerodynamic Characteristics for Slender Bodies Alone
and with Lifting Surfaces to Very High Angles of Attack*, NASA TR R-474, 1977.

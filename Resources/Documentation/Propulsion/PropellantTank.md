---
class: EquaForgeAerospace.Propulsion.PropellantTank
keywords: [propellant tank, ullage, pressurisation, boil-off, relief valve, cryogenic, mass properties]
see_also: [EquaForgeAerospace.Propulsion.RocketEngine, EquaForgeAerospace.Propulsion.EngineCluster, EquaForgeVC.Multibody.BodiesAndFrames.MassSum3, EquaForgeAerospace.Examples.StaticFire]
figures: [../figures/tank.svg]
validation: [unit.aerospace, examples.study.StarVesselMission_Analysis]
page_type: block
---
## Description

A tank of liquid oxygen or methane in a rocket stage. The engines draw liquid from the bottom.
Pressurant gas keeps the ullage above the liquid pressurised. Heat through the wall boils
liquid off into the ullage, and the relief valve vents what the tank cannot hold. The liquid,
settled at the bottom by the thrust, is a body of its own: the tank gives its mass, centre of
mass and inertia for the stage to add to its structure.

![A propellant tank and its flows](../figures/tank.svg)

The ullage gas ($m_g$ at pressure $p$) sits above the liquid ($m_l$, level $\ell$). The flows
are the pressurant $\dot m_{\text{press}}$, the vent $\dot m_{\text{vent}}$, the outflow to the
engines $\dot m_{\text{out}}$ and the heat $\dot Q$ through the wall. The axial acceleration
$a_x$ settles the liquid.

## Assumptions

The tank is a cylinder along the vehicle's $x$ axis. The liquid is settled at its bottom by a
positive axial acceleration and stays at its boiling temperature. The ullage gas is an ideal gas
at a fixed temperature. Slosh, stratification and the warming of the gas by the wall are left
out. Below `m_residual` the engines can draw less and less: the outflow and the boil-off fade
out, so the tank never runs below zero. The tank then reports itself `empty`.

## Equations

$$\dot m_l=-f\left(\dot m_{\text{out}}+\frac{\max(\dot Q,0)}{h_{fg}}\right),\qquad f=\min\left(1,\max\left(0,\frac{m_l}{m_{\text{res}}}\right)\right)$$

$$\dot m_g=\dot m_{\text{press}}+f\,\frac{\max(\dot Q,0)}{h_{fg}}-k_v\max(0,\,p-p_{\text{relief}})$$

$$p=\frac{m_g\,R_g\,T_g}{V-m_l/\rho_l},\qquad p_{\text{outlet}}=p+\rho_l\max(a_x,0)\,\ell,\qquad \ell=\frac{m_l}{\rho_l\,\pi r^2}$$

The liquid's centre of mass is at $x_{\text{bottom}}+\ell/2$. Its inertia is that of a solid
cylinder: $\tfrac12 m_l r^2$ about the axis and $m_l(3r^2+\ell^2)/12$ across it.

| Symbol | Meaning | Unit |
|---|---|---|
| $m_l,m_g$ | Liquid and ullage gas | kg |
| $\rho_l$ | Density of the liquid | kg/m³ |
| $r,V$ | Inner radius and volume of the tank | m, m³ |
| $\ell$ | Height of the liquid | m |
| $R_g,T_g$ | Gas constant and temperature of the ullage gas | J/(kg K), K |
| $h_{fg}$ | Latent heat of vaporisation | J/kg |
| $\dot Q$ | Heat flow through the wall into the liquid (`heatPort`) | W |
| $p_{\text{relief}},k_v$ | Relief pressure and vent flow per pascal above it | Pa, kg/(s Pa) |
| $m_{\text{res}}$ | Residual that the engines cannot draw | kg |

## How to use

1. Feed the engines' oxidiser or fuel flow to `mdot_out` and the axial acceleration to
   `a_axial`. Use the `IMU`'s specific force, not the acceleration.
2. Feed a pressurant flow to `mdot_press`, for example a share of the engine flow set by a
   `PI` controller on the tank pressure.
3. Connect the wall's heat to `heatPort`, through a `ThermalConductor` or `Convection` from the
   outside air or the structure.
4. Sum the tank's `mass` with the structure in a `MassSum3`. Use `empty` to shut the engines
   down before they run dry.

## Validation

`unit.aerospace` drains a tank at 100 kg/s and checks that the liquid falls by exactly what was
drawn. The liquid fades out at the residual without going below zero, and the ullage pressure
follows the ideal-gas law in the volume that the liquid has left. The `StarVesselMission_Analysis`
worksheet closes the ascent's mass balance: the propellant drawn from the tanks matches the
engines' integrated flow.

## References

D. K. Huzel and D. H. Huang, *Modern Engineering for Design of Liquid-Propellant Rocket
Engines*, AIAA Progress in Astronautics and Aeronautics 147, 1992, chapter 5.

---
class: EquaForgeAerospace.Propulsion.Nozzle
keywords: [nozzle, thrust, exit pressure, ambient pressure, flow separation, vacuum thrust]
see_also: [EquaForgeAerospace.Propulsion.RocketEngine, EquaForgeAerospace.Environment.AtmosphereUS76]
figures: [../figures/nozzle.svg]
validation: [unit.aerospace]
page_type: block
---
## Description

The thrust of a rocket nozzle. Its vacuum thrust grows with the chamber pressure, and the ambient
pressure on the exit area is subtracted from it. A nozzle built for vacuum loses a large share
of its thrust at sea level. When the pressure at its exit falls below about a quarter of the
ambient pressure, the flow separates from the wall. The block then warns, because the side
loads of separated flow can destroy a nozzle.

![Pressures on a nozzle](../figures/nozzle.svg)

The chamber pressure $p_c$ expands through the throat to the exit pressure $p_e$ at the exit
area $A_e$. The exhaust leaves at $v_e$; the ambient pressure $p_a$ pushes on the exit plane;
the thrust $F$ points forward.

## Assumptions

The flow is choked at the throat, so the flow and the vacuum thrust are proportional to the
chamber pressure. The expansion ratio fixes $p_e/p_c$. The thrust coefficient does not change
with the throttle. The separation criterion is Schmucker's, $p_e < 0.25\,p_a$; Summerfield's
older value is 0.4.

## Equations

The momentum of the exhaust and the pressure on the exit plane give the thrust:

$$F=\dot m\,v_e+(p_e-p_a)\,A_e=F_{\text{vac}}-p_a A_e$$

With the vacuum thrust scaled by the chamber pressure, the block computes

$$F=\max\left(F_{\text{vac}}\frac{p_c}{p_{c,\text{nom}}}-p_a A_e,\;0\right),\qquad p_e=\varepsilon\,p_c$$

and warns while $p_c>0.4\,p_{c,\text{nom}}$ and $p_e<0.25\,p_a$.

| Symbol | Meaning | Unit |
|---|---|---|
| $F,F_{\text{vac}}$ | Thrust, and vacuum thrust at the nominal chamber pressure | N |
| $p_c,p_{c,\text{nom}}$ | Chamber pressure, and its nominal value | Pa |
| $p_e,p_a$ | Exit and ambient pressure | Pa |
| $A_e$ | Exit area | m² |
| $\varepsilon$ | `pe_ratio`: exit / chamber pressure | 1 |
| $\dot m,v_e$ | Mass flow and exhaust velocity | kg/s, m/s |

## How to use

Feed the chamber pressure from a `FirstOrder` lag or a combustion model, and the ambient pressure
from `AtmosphereUS76`. `RocketEngine` contains one. The warning appears once in the run's
warnings (`res.warnings` in Python), not as an error.

## Validation

`unit.aerospace` raises the ambient pressure from 0 to 1 bar and checks that the thrust falls by
exactly $p_a A_e$.

## References

R. H. Schmucker, *Flow processes in overexpanded chemical rocket nozzles*, NASA TM-77396, 1984.

G. P. Sutton and O. Biblarz, *Rocket Propulsion Elements*, 9th ed., Wiley, 2017, chapter 3.

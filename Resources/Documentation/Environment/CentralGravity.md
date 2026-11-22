---
class: EquaForgeAerospace.Environment.CentralGravity
keywords: [gravity, J2, oblateness, nodal regression, orbit, Kepler]
see_also: [EquaForgeVC.Multibody.BodiesAndFrames.FreeBody, EquaForgeAerospace.GNC.OrbitalElements, EquaForgeAerospace.Examples.OrbitPropagation]
figures: [../figures/j2.svg]
validation: [unit.aerospace]
page_type: block
---
## Description

The pull of the Earth at the frame it is connected to. It is the inverse-square attraction of
the Earth's mass plus the main effect of its flattening, the J2 term. J2 turns the planes of
orbits (nodal regression) and the lines of their apsides. The block takes the position of
`frame_a` and gives the acceleration `g` in the world frame. It puts no load on the frame.

![Gravity of the flattened Earth](../figures/j2.svg)

The Earth's centre is the world origin and its axis is the $z$ axis. The flattening, much
exaggerated here, bends $\mathbf{g}$ slightly towards the equatorial bulge. At latitude
$\varphi$, $\sin\varphi = z/r$.

## Assumptions

The field is a point mass plus the second zonal harmonic: the Earth is symmetric about its
axis and about its equator. Higher harmonics, the Moon and the Sun are left out. The field does
not depend on the Earth's rotation; J2 is symmetric about the axis.

## Equations

$$g_x=-\frac{\mu\,x}{r^3}\left(1+k\left(1-5\frac{z^2}{r^2}\right)\right),\qquad g_y=-\frac{\mu\,y}{r^3}\left(1+k\left(1-5\frac{z^2}{r^2}\right)\right)$$

$$g_z=-\frac{\mu\,z}{r^3}\left(1+k\left(3-5\frac{z^2}{r^2}\right)\right),\qquad k=\frac{3}{2}J_2\left(\frac{R_e}{r}\right)^2$$

Over each orbit, J2 turns the ascending node at the mean rate

$$\dot{\Omega}=-\frac{3}{2}\,n\,J_2\left(\frac{R_e}{p}\right)^2\cos i,\qquad n=\sqrt{\mu/a^3}$$

which is westward for a prograde orbit.

| Symbol | Meaning | Unit |
|---|---|---|
| $x,y,z$ | Position of `frame_a`, world frame | m |
| $r$ | Distance from the Earth's centre | m |
| $\mu$ | Gravitational parameter (`muEarth`) | m³/s² |
| $J_2$ | Second zonal harmonic (0: a point mass) | 1 |
| $R_e$ | Reference radius of J2 | m |
| $a,p,i$ | Semi-major axis, semi-latus rectum and inclination of the orbit | m, m, rad |

## How to use

Connect `frame_a` to a free body's frame and `g` to its gravity input. Set `J2 = 0` for Kepler
orbits. For a body near the ground, gravity still varies with altitude here; the surface value
is about 9.8 m/s².

## Validation

`unit.aerospace` flies a circular 400 km orbit at 51.6° for five periods. With `J2 = 0` the
orbit keeps its period, energy and radius to 1e-8. With J2 the node turns at the rate above,
within 2 %. The `StarVesselMission_Analysis` worksheet re-propagates the parking orbit with SciPy
under the same field.

## References

D. A. Vallado, *Fundamentals of Astrodynamics and Applications*, 4th ed., Microcosm Press,
2013, sections 8.6 and 9.6.

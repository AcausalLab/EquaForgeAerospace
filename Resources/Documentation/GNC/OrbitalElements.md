---
class: EquaForgeAerospace.GNC.OrbitalElements
keywords: [orbital elements, Kepler, semi-major axis, eccentricity, inclination, RAAN, apoapsis, periapsis]
see_also: [EquaForgeAerospace.Environment.CentralGravity, EquaForgeAerospace.GNC.GroundTrack, EquaForgeAerospace.Examples.OrbitPropagation]
figures: [../figures/orbit.svg]
validation: [unit.aerospace]
page_type: block
---
## Description

The orbit that a vehicle is on now, from its position and velocity. The block gives the orbit's
size and shape (semi-major axis, eccentricity, apoapsis and periapsis altitudes), the place of
its plane (inclination, ascending node) and the vehicle's place on it (argument of periapsis,
true anomaly). Burns change the orbit. Between burns it stays fixed, except for the slow turn of
the node and the apsides under J2.

![The classical orbital elements](../figures/orbit.svg)

The orbit's plane is tilted by $i$ from the equator. It crosses the equator going north at the
ascending node, at the angle $\Omega$ from the $x$ axis. The periapsis lies $\omega$ further on
in the plane, and the vehicle at $\mathbf{r}$ is $\nu$ beyond the periapsis. The angular
momentum $\mathbf{h}$ is normal to the plane.

## Assumptions

The elements are osculating: they describe the Kepler orbit that the vehicle would follow if
every force except the central attraction stopped now. Under J2 they oscillate a little over
each orbit about their mean values. The node and the periapsis are not defined for an equatorial
or a circular orbit; `atan2` still gives a value, which then jumps. The world frame's $x$ axis
stands for the vernal equinox.

## Equations

$$\mathbf{h}=\mathbf{r}\times\mathbf{v},\qquad E=\frac{v^2}{2}-\frac{\mu}{r},\qquad a=-\frac{\mu}{2E}$$

$$\mathbf{e}=\frac{\mathbf{v}\times\mathbf{h}}{\mu}-\frac{\mathbf{r}}{r},\qquad i=\arccos\frac{h_z}{h},\qquad \mathbf{n}=\mathbf{e}_z\times\mathbf{h},\qquad \Omega=\operatorname{atan2}(n_y,n_x)$$

$$\omega=\operatorname{atan2}\left(\frac{(\mathbf{n}\times\mathbf{e})\cdot\mathbf{h}}{h},\;\mathbf{n}\cdot\mathbf{e}\right),\qquad \nu=\operatorname{atan2}\left(\frac{(\mathbf{e}\times\mathbf{r})\cdot\mathbf{h}}{h},\;\mathbf{e}\cdot\mathbf{r}\right)$$

$$h_a=a(1+e)-R_e,\qquad h_p=a(1-e)-R_e,\qquad T=2\pi\sqrt{a^3/\mu},\qquad \sin\gamma=\frac{\mathbf{r}\cdot\mathbf{v}}{r\,v}$$

| Symbol | Meaning | Unit |
|---|---|---|
| $\mathbf{r},\mathbf{v}$ | Position and velocity, world frame | m, m/s |
| $\mathbf{h}$ | Specific angular momentum | m²/s |
| $E$ | Specific orbital energy | J/kg |
| $a,e$ | Semi-major axis (negative: a hyperbola) and eccentricity | m, 1 |
| $i,\Omega,\omega,\nu$ | Inclination, ascending node, argument of periapsis, true anomaly | rad |
| $h_a,h_p$ | Apoapsis and periapsis altitudes above $R_e$ | m |
| $T,\gamma$ | Period (0 for an open orbit) and flight-path angle | s, rad |

## How to use

Connect `vehicle` to a free body's `motion`. Watch `periapsis` during an ascent to see when the
orbit is safe. Use `apoapsis` to cut off an orbit-raising burn. The angles run from $-\pi$ to
$\pi$; unwrap them before plotting a slow drift such as the node's regression.

## Validation

`unit.aerospace` reproduces Vallado's example 2-5: $a$ = 36 127.343 km, $e$ = 0.832853,
$i$ = 87.87°, $\Omega$ = 227.89°, $\omega$ = 53.38° and $\nu$ = 92.335°, each to within 1e-4 or
better. The same suite checks the period and the node's regression on a simulated orbit.

## References

D. A. Vallado, *Fundamentals of Astrodynamics and Applications*, 4th ed., Microcosm Press,
2013, algorithm 9 (RV2COE) and example 2-5.

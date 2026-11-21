within;
package EquaForgeAerospace "Launch vehicles and spacecraft: environment, propulsion, aerodynamics, guidance, navigation and control"
  // the core library's packages, used below by their short names
  import Blocks = EquaForgeVC.Blocks;
  import Drives = EquaForgeVC.Drives;
  import Logical = EquaForgeVC.Logical;
  import Mechanics = EquaForgeVC.Mechanics;
  import Multibody = EquaForgeVC.Multibody;
  import Visualization = EquaForgeVC.Visualization;
  constant Real g0(unit = "m/s2") = 9.80665 "Standard gravity (specific impulse, load factors)";
  constant Real omegaEarth(unit = "rad/s") = 7.2921159e-5 "Rotation of the Earth";
  constant Real muEarth(unit = "m3/s2") = 3.986004418e14 "Gravitational parameter of the Earth";
  constant Real radiusEarth(unit = "m") = 6378137 "Equatorial radius of the Earth";
  constant Real J2Earth = 1.08262668e-3 "Second zonal harmonic of the Earth's gravity";

  package Functions "Positions and orientations on the Earth"
    function sitePosition "Position of a place on a spherical Earth, Earth-fixed coordinates"
      input Real latitude(unit = "rad") "Latitude";
      input Real longitude(unit = "rad") "Longitude";
      input Real altitude(unit = "m") "Height above the sphere";
      input Real radius(unit = "m") = 6378137 "Radius of the Earth";
      output Real r[3](each unit = "m") "Earth-fixed position (z: north pole, x: longitude 0)";
    algorithm
      r := (radius + altitude)*{cos(latitude)*cos(longitude), cos(latitude)*sin(longitude), sin(latitude)};
      annotation(Documentation(info = "<html><p>The Earth-fixed position of a place given by latitude, longitude and height on a sphere of the given radius: z towards the north pole, x towards longitude 0 on the equator.</p></html>"));
    end sitePosition;

    function localQ "Orientation of the local frame at a place: x up, y east, z north"
      input Real latitude(unit = "rad") "Latitude";
      input Real longitude(unit = "rad") "Longitude";
      output Real Q[4] "Quaternion of the local frame relative to the Earth-fixed frame";
    algorithm
      Q := Multibody.Frames.qmul(Multibody.Frames.planarQ({0, 0, 1}, longitude), Multibody.Frames.planarQ({0, 1, 0}, -latitude));
      annotation(Documentation(info = "<html><p>The orientation of the local frame of a place on the Earth, relative to the Earth-fixed frame: x up (away from the centre), y east, z north. A vehicle standing on its pad with its long axis up has this orientation.</p></html>"));
    end localQ;
    annotation(Documentation(info = "<html><p>Functions for places on a spherical Earth: their position and their local frame.</p></html>"));
  end Functions;

  package Environment "The Earth: its rotation, gravity, atmosphere and the places on it"
    model RotatingEarth "The Earth-fixed frame, turning about the world's z axis; the root of launch pads and towers"
      extends EquaForgeVC.Icons.Component;
      parameter Real omega(unit = "rad/s") = EquaForgeAerospace.omegaEarth "Rotation rate";
      parameter Real theta0(unit = "rad", displayUnit = "deg") = 0 "Angle of longitude 0 from the world's x axis at time 0";
      Multibody.Interfaces.Frame_b frame_b "The Earth-fixed frame" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
      Multibody.Interfaces.MotionOutput motion "Its motion, for Attachments and launch sites" annotation(Placement(transformation(origin = {0, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      Real theta(unit = "rad", displayUnit = "deg") "Angle of longitude 0 from the world's x axis";
    equation
      theta = theta0 + omega*time;
      frame_b.r_0 = zeros(3);
      frame_b.R = Multibody.Frames.planarRotation({0, 0, 1}, theta);
      frame_b.w = {0, 0, omega};
      motion.r = zeros(3);
      motion.v = zeros(3);
      motion.a = zeros(3);
      motion.Q = Multibody.Frames.planarQ({0, 0, 1}, theta);
      motion.w = {0, 0, omega};
      motion.z = zeros(3);
      annotation(Documentation(info = "<html><p>The ground of a launch: the Earth-fixed frame, which turns about the world's z axis (the north pole) once per sidereal day. The world frame itself is inertial and centred on the Earth. Launch sites, pads and towers hang from <b>frame_b</b>; the <b>motion</b> output feeds the <code>LaunchSite</code> blocks that hold vehicles on the ground.</p><h4>Equations</h4><pre>theta = theta0 + omega t\nframe_b: r = 0, R = planarRotation(z, theta), w = {0, 0, omega}</pre></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {0, 70, 140}, fillColor = {60, 130, 210}, fillPattern = FillPattern.Sphere),
          Polygon(points = {{-30, 40}, {10, 50}, {30, 20}, {0, -10}, {-20, 5}}, lineColor = {40, 120, 40}, fillColor = {70, 160, 70}, fillPattern = FillPattern.Solid),
          Line(points = {{0, 90}, {0, -90}}, color = {64, 64, 64}, pattern = LinePattern.Dash),
          Line(points = {{-40, 85}, {40, 85}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{70, 0}, {90, 0}}, color = {95, 95, 95}, thickness = 0.5)}));
    end RotatingEarth;

    model LaunchSite "A place on the turning Earth: its frame (x up, y east, z north) and its motion"
      extends EquaForgeVC.Icons.Component;
      parameter Real latitude(unit = "rad", displayUnit = "deg") = 0 "Latitude";
      parameter Real longitude(unit = "rad", displayUnit = "deg") = 0 "Longitude";
      parameter Real altitude(unit = "m") = 0 "Height above the sphere";
      parameter Real radius(unit = "m") = EquaForgeAerospace.radiusEarth "Radius of the Earth";
      parameter Real heading(unit = "rad", displayUnit = "deg") = 0 "Turn of the site frame about its x axis (up), from y east towards z north";
      Multibody.Interfaces.Frame_a frame_a "The Earth-fixed frame (RotatingEarth)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      Multibody.Interfaces.Frame_b frame_b "The site frame: x up, y east, z north (turned by heading)" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
      Multibody.Interfaces.MotionInput earth "Motion of the Earth-fixed frame (RotatingEarth)" annotation(Placement(transformation(origin = {-60, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
      Multibody.Interfaces.MotionOutput motion "Motion of the site frame" annotation(Placement(transformation(origin = {60, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      final parameter Real r_site[3](each unit = "m") = Functions.sitePosition(latitude, longitude, altitude, radius) "Earth-fixed position";
      final parameter Real Q_site[4] = Multibody.Frames.qmul(Functions.localQ(latitude, longitude), Multibody.Frames.planarQ({1, 0, 0}, heading)) "Orientation relative to the Earth-fixed frame";
    protected
      final parameter Real R_site[3, 3] = Multibody.Frames.fromQ(Q_site);
      Real Re[3, 3] "Orientation of the Earth-fixed frame";
    equation
      frame_b.r_0 = frame_a.r_0 + transpose(frame_a.R)*r_site;
      frame_b.R = R_site*frame_a.R;
      frame_b.w = R_site*frame_a.w;
      zeros(3) = frame_a.f + transpose(R_site)*frame_b.f;
      zeros(3) = frame_a.t + transpose(R_site)*frame_b.t + cross(r_site, transpose(R_site)*frame_b.f);
      Re = Multibody.Frames.fromQ(earth.Q);
      motion.r = earth.r + transpose(Re)*r_site;
      motion.v = earth.v + transpose(Re)*cross(earth.w, r_site);
      motion.a = earth.a + transpose(Re)*(cross(earth.z, r_site) + cross(earth.w, cross(earth.w, r_site)));
      motion.Q = Multibody.Frames.qmul(earth.Q, Q_site);
      motion.w = R_site*earth.w;
      motion.z = R_site*earth.z;
      annotation(Documentation(info = "<html><p>A launch pad, a landing zone or a tower base: the frame of a place on the turning Earth, with x up, y east and z north (turned about x by <b>heading</b>), and its motion. A vehicle held at the site (an <code>Attachment</code> with the site as carrier) moves with the Earth until it is released.</p><h4>Equations</h4><pre>r_site = (radius + altitude) {cos(lat) cos(lon), cos(lat) sin(lon), sin(lat)}  (Earth-fixed)\nframe_b = frame_a offset by r_site, turned by Q_site (localQ, heading)</pre><h4>How to use</h4><p>Connect frame_a and earth to a <code>RotatingEarth</code>. Hang towers and pads from frame_b; take a vehicle's carrier from an <code>Multibody.JointsAndMotions.Attachment</code> whose carrier is <b>motion</b> and whose frame_b is this frame_b.</p></html>"),
        Icon(graphics = {
          Line(points = {{-90, 0}, {-40, 0}}, color = {95, 95, 95}, thickness = 0.5),
          Polygon(points = {{-40, -60}, {40, -60}, {20, -40}, {-20, -40}}, lineColor = {95, 95, 95}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid),
          Rectangle(extent = {{-8, -40}, {8, 50}}, lineColor = {64, 64, 64}, fillColor = {230, 230, 230}, fillPattern = FillPattern.Solid),
          Polygon(points = {{-8, 50}, {0, 75}, {8, 50}}, lineColor = {64, 64, 64}, fillColor = {230, 230, 230}, fillPattern = FillPattern.Solid),
          Line(points = {{8, 0}, {90, 0}}, color = {95, 95, 95}, thickness = 0.5),
          Text(extent = {{-150, -70}, {150, -100}}, textString = "%name")}));
    end LaunchSite;

    model CentralGravity "Gravity of the Earth at a frame: a point mass and the J2 flattening term"
      extends EquaForgeVC.Icons.Component;
      parameter Real mu(unit = "m3/s2") = EquaForgeAerospace.muEarth "Gravitational parameter";
      parameter Real J2 = EquaForgeAerospace.J2Earth "Second zonal harmonic (0: a point mass)";
      parameter Real Re(unit = "m") = EquaForgeAerospace.radiusEarth "Reference radius of J2";
      Multibody.Interfaces.Frame_a frame_a "Where gravity is wanted (not loaded)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      EquaForgeVC.Interfaces.RealOutput g[3](each unit = "m/s2") "Gravitational acceleration, world frame" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
      Real r(unit = "m") "Distance from the centre of the Earth";
      Real gMagnitude(unit = "m/s2") "Size of the acceleration";
    protected
      Real k "1.5 J2 (Re/r)^2";
      Real s2 "5 (z/r)^2";
    equation
      frame_a.f = zeros(3);
      frame_a.t = zeros(3);
      r = sqrt(frame_a.r_0*frame_a.r_0);
      k = 1.5*J2*(Re/r)^2;
      s2 = 5*(frame_a.r_0[3]/r)^2;
      g = -mu/r^3*{frame_a.r_0[1]*(1 + k*(1 - s2)), frame_a.r_0[2]*(1 + k*(1 - s2)), frame_a.r_0[3]*(1 + k*(3 - s2))};
      gMagnitude = sqrt(g*g);
      annotation(Documentation(info = "<html><p>The pull of the Earth at the frame it is connected to: the inverse-square attraction of its mass and the main effect of its flattening, the J2 term, which turns the planes of orbits (nodal regression) and the lines of their apsides. The Earth's centre is the world origin and its axis the world's z axis.</p><h4>Equations</h4><pre>g = -mu/r^3 { x (1 + k (1 - 5 z^2/r^2)), y (1 + k (1 - 5 z^2/r^2)), z (1 + k (3 - 5 z^2/r^2)) }\nk = 1.5 J2 (Re/r)^2</pre><h4>How to use</h4><p>Connect frame_a to a free body's frame and the output <b>g</b> to its gravity input. Set J2 = 0 for a point mass (Kepler orbits).</p></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 70, 140}, fillColor = {60, 130, 210}, fillPattern = FillPattern.Sphere),
          Line(points = {{0, 90}, {0, 45}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{-80, -70}, {-32, -28}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{80, -70}, {32, -28}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}),
          Text(extent = {{-150, -60}, {150, -90}}, textString = "J2=%J2")}));
    end CentralGravity;

    block AtmosphereUS76 "U.S. Standard Atmosphere 1976: density, pressure, temperature and speed of sound"
      extends EquaForgeVC.Icons.Block;
      EquaForgeVC.Interfaces.RealInput h(unit = "m") "Geometric altitude" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealOutput rho(unit = "kg/m3") "Density" annotation(Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput p(unit = "Pa") "Pressure" annotation(Placement(transformation(origin = {110, 20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput T(unit = "K") "Temperature" annotation(Placement(transformation(origin = {110, -20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput a(unit = "m/s") "Speed of sound" annotation(Placement(transformation(origin = {110, -60}, extent = {{-10, -10}, {10, 10}})));
      Real H(unit = "m") "Geopotential altitude";
    protected
      constant Real R = 287.05287 "Gas constant of air (J/(kg K))";
      constant Real r0 = 6356766 "Earth radius of the geopotential (m)";
      constant Real Hb[8] = {0, 11000, 20000, 32000, 47000, 51000, 71000, 84852} "Layer bases (m)";
      constant Real Lb[7] = {-0.0065, 0, 0.001, 0.0028, 0, -0.0028, -0.002} "Lapse rates (K/m)";
      constant Real Tb[8] = {288.15, 216.65, 216.65, 228.65, 270.65, 270.65, 214.65, 186.946} "Base temperatures (K)";
      constant Real pb[8] = {101325, 22632.06, 5474.889, 868.0187, 110.9063, 66.93887, 3.956420, 0.3733835} "Base pressures (Pa)";
      constant Real hu[12] = {86000, 100000, 150000, 200000, 300000, 400000, 500000, 600000, 700000, 800000, 900000, 1000000} "Upper atmosphere: altitudes (m)";
      constant Real lnrho[12] = {log(6.958e-6), log(5.604e-7), log(2.076e-9), log(2.541e-10), log(1.916e-11), log(2.803e-12), log(5.215e-13), log(1.137e-13), log(3.070e-14), log(1.136e-14), log(5.759e-15), log(3.561e-15)} "Upper atmosphere: log of the density";
      Real hc(unit = "m") "Altitude within the tables";
      Real Tl, pl "Lower atmosphere (to 86 km)";
      Real wu[11] "Upper atmosphere: share of each interval";
    equation
      hc = noEvent(min(max(h, -5000), 1000000));
      H = r0*hc/(r0 + hc);
      Tl = noEvent(if H < Hb[2] then Tb[1] + Lb[1]*(H - Hb[1]) else if H < Hb[3] then Tb[2] else if H < Hb[4] then Tb[3] + Lb[3]*(H - Hb[3]) else if H < Hb[5] then Tb[4] + Lb[4]*(H - Hb[4]) else if H < Hb[6] then Tb[5] else if H < Hb[7] then Tb[6] + Lb[6]*(H - Hb[6]) else Tb[7] + Lb[7]*(noEvent(min(H, Hb[8])) - Hb[7]));
      pl = noEvent(if H < Hb[2] then pb[1]*(Tb[1]/Tl)^(EquaForgeAerospace.g0/(R*Lb[1])) else if H < Hb[3] then pb[2]*exp(-EquaForgeAerospace.g0*(H - Hb[2])/(R*Tb[2])) else if H < Hb[4] then pb[3]*(Tb[3]/Tl)^(EquaForgeAerospace.g0/(R*Lb[3])) else if H < Hb[5] then pb[4]*(Tb[4]/Tl)^(EquaForgeAerospace.g0/(R*Lb[4])) else if H < Hb[6] then pb[5]*exp(-EquaForgeAerospace.g0*(H - Hb[5])/(R*Tb[5])) else if H < Hb[7] then pb[6]*(Tb[6]/Tl)^(EquaForgeAerospace.g0/(R*Lb[6])) else pb[7]*(Tb[7]/Tl)^(EquaForgeAerospace.g0/(R*Lb[7])));
      for i in 1:11 loop
        wu[i] = noEvent(min(max((hc - hu[i])/(hu[i + 1] - hu[i]), 0), 1));
      end for;
      T = noEvent(if hc < hu[1] then Tl else Tb[8]);
      rho = noEvent(if hc < hu[1] then pl/(R*Tl) else exp(lnrho[1] + sum((lnrho[i + 1] - lnrho[i])*wu[i] for i in 1:11)));
      p = noEvent(if hc < hu[1] then pl else rho*R*T);
      a = sqrt(1.4*R*T);
      annotation(Documentation(info = "<html><p>The standard atmosphere of the United States (1976) from the ground to 1000 km: seven layers of constant lapse rate up to 86 km (geopotential altitude), then the tabulated density of the thermosphere, interpolated on a log scale. Above 86 km the temperature shown is the 86 km value: the speed of sound there matters no more for flight.</p><h4>Equations</h4><pre>H = r0 h / (r0 + h)\nT = T_b + L_b (H - H_b),  p = p_b (T_b/T)^(g0/(R L_b))  or  p_b exp(-g0 (H - H_b)/(R T_b))\nrho = p / (R T),  a = sqrt(1.4 R T)</pre><h4>How to use</h4><p>Feed the geometric altitude from <code>AirData</code> or a <code>GroundTrack</code>. It makes no events at the layer boundaries.</p></html>"),
        Icon(graphics = {
          Line(points = {{-70, -80}, {-70, 80}}, color = {192, 192, 192}),
          Line(points = {{-70, -80}, {70, -80}}, color = {192, 192, 192}),
          Line(points = {{60, -80}, {-20, -30}, {-20, 0}, {0, 30}, {20, 50}, {-10, 70}}, color = {0, 0, 127}, thickness = 0.5),
          Text(extent = {{-60, 90}, {90, 60}}, textString = "US76")}));
    end AtmosphereUS76;

    block AirData "Flight through the air: altitude, airspeed, Mach number, dynamic pressure and angle of attack"
      extends EquaForgeVC.Icons.Block;
      parameter Real Re(unit = "m") = EquaForgeAerospace.radiusEarth "Radius of the Earth (altitudes)";
      parameter Real omega(unit = "rad/s") = EquaForgeAerospace.omegaEarth "Rotation of the Earth (the air turns with it)";
      Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle's frame" annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}})));
      EquaForgeVC.Interfaces.RealInput wind[2](each unit = "m/s") "Wind towards east and north" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput rho(unit = "kg/m3") "Air density (AtmosphereUS76)" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
      EquaForgeVC.Interfaces.RealInput a(unit = "m/s") "Speed of sound (AtmosphereUS76)" annotation(Placement(transformation(extent = {{-140, -100}, {-100, -60}})));
      EquaForgeVC.Interfaces.RealOutput h(unit = "m") "Altitude above the sphere" annotation(Placement(transformation(origin = {110, 80}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput v_air[3](each unit = "m/s") "Velocity through the air, vehicle frame" annotation(Placement(transformation(origin = {110, 40}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput V(unit = "m/s") "Airspeed" annotation(Placement(transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput Mach "Mach number" annotation(Placement(transformation(origin = {110, -40}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput qbar(unit = "Pa") "Dynamic pressure" annotation(Placement(transformation(origin = {110, -80}, extent = {{-10, -10}, {10, 10}})));
      Real alpha(unit = "rad", displayUnit = "deg") "Angle of attack in the x-y plane of the vehicle";
      Real alphaTotal(unit = "rad", displayUnit = "deg") "Angle between the vehicle's x axis and its airspeed";
      Real v_ground[3](each unit = "m/s") "Velocity relative to the turning Earth, world frame";
      Real speedGround(unit = "m/s") "Speed relative to the Earth";
      Real flightPathAngle(unit = "rad", displayUnit = "deg") "Climb angle of the Earth-relative velocity";
    protected
      Real R[3, 3] "Vehicle orientation";
      Real up[3], east[3], north[3] "Local directions, world frame";
      Real rn(unit = "m");
    equation
      R = Multibody.Frames.fromQ(vehicle.Q);
      rn = sqrt(vehicle.r*vehicle.r);
      h = rn - Re;
      up = vehicle.r/rn;
      east = cross({0, 0, 1}, up)/noEvent(max(1e-9, sqrt(up[1]^2 + up[2]^2)));
      north = cross(up, east);
      v_ground = vehicle.v - cross({0, 0, omega}, vehicle.r);
      speedGround = sqrt(v_ground*v_ground);
      flightPathAngle = asin(noEvent(max(-1, min(1, (v_ground*up)/max(speedGround, 1e-6)))));
      v_air = R*(v_ground - wind[1]*east - wind[2]*north);
      V = sqrt(v_air*v_air);
      Mach = V/a;
      qbar = 0.5*rho*V^2;
      alpha = atan2(v_air[2], v_air[1]);
      alphaTotal = acos(noEvent(max(-1, min(1, v_air[1]/max(V, 1e-6)))));
      annotation(Documentation(info = "<html><p>How a vehicle moves through the air: the air turns with the Earth and blows with the <b>wind</b> (east and north components), so the airspeed differs from the inertial velocity by both. From the <code>AtmosphereUS76</code> values it gives the Mach number and the dynamic pressure that size every aerodynamic force, and the angles of the airspeed in the vehicle frame.</p><h4>Equations</h4><pre>h = |r| - Re\nv_ground = v - omega z x r\nv_air = R (v_ground - wind_east e - wind_north n)\nV = |v_air|, Mach = V / a, qbar = rho V^2 / 2\nalpha = atan2(v_air_y, v_air_x),  alphaTotal = acos(v_air_x / V)</pre><p>Body axes: x along the vehicle (nose), y towards the belly (down when the vehicle flies nose-first and level), z completing the right-handed frame.</p><h4>How to use</h4><p>Connect <b>vehicle</b> to a free body's motion output, <b>h</b> to the atmosphere and its density and speed of sound back to <b>rho</b> and <b>a</b>; the outputs feed <code>BodyAero</code>, flaps and fins, and the heating.</p></html>"),
        Icon(graphics = {
          Line(points = {{-80, 0}, {40, 0}}, color = {0, 0, 127}, thickness = 0.5),
          Polygon(points = {{40, 15}, {80, 0}, {40, -15}}, lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid),
          Line(points = {{-70, 40}, {30, 40}}, color = {120, 120, 120}, pattern = LinePattern.Dash),
          Line(points = {{-70, -40}, {30, -40}}, color = {120, 120, 120}, pattern = LinePattern.Dash),
          Text(extent = {{-80, 90}, {80, 55}}, textString = "q, M, α")}));
    end AirData;
    annotation(Documentation(info = "<html><p>The Earth around a launch: its rotation (<code>RotatingEarth</code>), the places on it (<code>LaunchSite</code>), its gravity with the J2 flattening term (<code>CentralGravity</code>), the standard atmosphere (<code>AtmosphereUS76</code>) and the air a vehicle flies through (<code>AirData</code>). The world frame is inertial, centred on the Earth, with z towards the north pole.</p></html>"));
  end Environment;

  package Aerodynamics "Forces of the air on a vehicle and its control surfaces"
    model BodyAero "Aerodynamic force and moment on a slender body, from nose-first flight to broadside and tail-first"
      extends EquaForgeVC.Icons.Component;
      parameter Real S(unit = "m2") = 63.6 "Reference area (cross-section)";
      parameter Real Mach_table[:] = {0, 0.8, 1.1, 1.5, 3, 6, 25} "Mach numbers of the axial coefficient table";
      parameter Real CA_table[size(Mach_table, 1)] = {0.30, 0.32, 0.55, 0.50, 0.35, 0.25, 0.22} "Axial force coefficient at zero angle of attack";
      parameter Real CA_tailFactor = 1 "Axial coefficient tail-first / nose-first (a blunt engine end first: 2 to 3)";
      parameter Real CN_alpha(unit = "1/rad") = 2.0 "Slope of the normal force coefficient at small angles";
      parameter Real CD_cross = 1.2 "Cross-flow drag coefficient of the body broadside (scaled by planformRatio)";
      parameter Real planformRatio = 7.0 "Planform area / reference area (length / diameter of a cylinder)";
      parameter Real x_cp_nose(unit = "m") = 30 "Centre of pressure for nose-first flight, along x from frame_b";
      parameter Real x_cp_tail(unit = "m") = 15 "Centre of pressure for tail-first flight";
      parameter Real x_cp_broadside(unit = "m") = 22 "Centre of pressure broadside (centre of the planform)";
      Multibody.Interfaces.Frame_b frame_b "The vehicle's frame (the reference of x_cp)" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
      EquaForgeVC.Interfaces.RealInput v_air[3](each unit = "m/s") "Velocity through the air, vehicle frame (AirData)" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
      EquaForgeVC.Interfaces.RealInput qbar(unit = "Pa") "Dynamic pressure (AirData)" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput Mach "Mach number (AirData)" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
      Real F[3](each unit = "N") "Aerodynamic force, vehicle frame";
      Real CA "Axial force coefficient";
      Real CN "Normal force coefficient";
      Real x_cp(unit = "m") "Centre of pressure along x";
      Real drag(unit = "N") "Force against the airspeed";
      Real lift(unit = "N") "Force across the airspeed";
      Real M_damp[3](each unit = "N.m") "Damping moment: the cross flow a pitching or yawing body meets along its length";
      final parameter Real length(unit = "m") = planformRatio*sqrt(4*S/EquaForgeVC.pi) "Length of the body (planform / diameter)";
    protected
      Blocks.Table1D axial(x = Mach_table, values = CA_table);
      Real V(unit = "m/s");
      Real ca, sa "cos and sin of the total angle of attack";
      Real ec[2] "Direction of the cross flow (y, z)";
      Real Vc(unit = "m/s") "Cross-flow speed";
    equation
      axial.u = Mach;
      V = noEvent(max(sqrt(v_air*v_air), 1e-6));
      ca = v_air[1]/V;
      Vc = sqrt(v_air[2]^2 + v_air[3]^2);
      sa = Vc/V;
      ec = {v_air[2], v_air[3]}/noEvent(max(Vc, 1e-6));
      CA = axial.y*noEvent(if ca >= 0 then 1 else CA_tailFactor)*ca*abs(ca);
      CN = CN_alpha*sa*abs(ca) + CD_cross*planformRatio*sa^2;
      x_cp = noEvent(if ca >= 0 then x_cp_nose else x_cp_tail)*ca^2 + x_cp_broadside*sa^2;
      F = -qbar*S*{CA, CN*ec[1], CN*ec[2]};
      // a body turning at w about y or z meets an extra cross flow w x along its length; linearised, the
      // cross-flow drag of each station then gives a moment against the turn (about the middle of the body),
      // twice as strong for stations moving along the cross flow as across it
      M_damp = -qbar*sa/V*CD_cross*planformRatio*S*length^2/12*{0, (1 + ec[2]^2)*frame_b.w[2] - ec[1]*ec[2]*frame_b.w[3], (1 + ec[1]^2)*frame_b.w[3] - ec[1]*ec[2]*frame_b.w[2]};
      frame_b.f = -F;
      frame_b.t = -cross({x_cp, 0, 0}, F) - M_damp;
      drag = -(F*v_air)/V;
      lift = sqrt(noEvent(max(F*F - drag^2, 0)));
      annotation(Documentation(info = "<html><p>The air's force on a cylindrical vehicle at any angle of attack: an axial force from a table against Mach number, and a normal force from the slender-body slope at small angles plus the cross-flow drag of the body (Jorgensen) that dominates broadside, as in a belly-flop. The force acts at a centre of pressure that moves from its nose-first place to the middle of the planform broadside and to its tail-first place in a tail-first descent.</p><h4>Equations</h4><pre>alpha_t: angle between x and the airspeed, cos = v_x / V, sin = V_cross / V\nCA = CA0(Mach) cos|cos|   (times CA_tailFactor tail-first)\nCN = CN_alpha sin |cos| + CD_cross planformRatio sin^2\nF = -qbar S {CA, CN e_y, CN e_z}     (e: direction of the cross flow)\nmoment about frame_b: {x_cp, 0, 0} x F + M_damp\nM_damp = -qbar sin/V CD_cross planformRatio S L^2/12 {0, (1 + e_z^2) w_y - e_y e_z w_z, (1 + e_y^2) w_z - e_y e_z w_y},  L = planformRatio sqrt(4 S/pi)</pre><h4>Assumptions</h4><p>A body of revolution: the force depends on the total angle of attack, not on the roll angle; Mach number changes only the axial coefficient. The coefficients are illustrative orders of magnitude, not a wind-tunnel database.</p></html>"),
        Icon(graphics = {
          Rectangle(extent = {{-70, 15}, {50, -15}}, lineColor = {95, 95, 95}, fillColor = {220, 220, 220}, fillPattern = FillPattern.Solid),
          Polygon(points = {{50, 15}, {80, 0}, {50, -15}}, lineColor = {95, 95, 95}, fillColor = {220, 220, 220}, fillPattern = FillPattern.Solid),
          Line(points = {{-90, 60}, {-20, 25}}, color = {0, 0, 127}, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{-90, 30}, {-20, -5}}, color = {0, 0, 127}, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{0, 0}, {0, 60}}, color = {200, 0, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
          Text(extent = {{-150, -30}, {150, -60}}, textString = "S=%S")}));
    end BodyAero;

    model Flap "Body flap: a plate hinged along the vehicle that catches the cross flow as it opens"
      extends EquaForgeVC.Icons.Component;
      parameter Real S(unit = "m2") = 15 "Area of the flap";
      parameter Real CN_plate = 1.8 "Normal force coefficient of the plate square to the flow";
      parameter Real hingeArm(unit = "m") = 1.5 "From the hinge line to the flap's centre of pressure";
      Multibody.Interfaces.Frame_b frame_b "At the flap's centre of pressure on the vehicle" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
      EquaForgeVC.Interfaces.RealInput delta(unit = "rad", displayUnit = "deg") "Deflection: 0 folded against the body, pi/2 fully open" annotation(Placement(transformation(origin = {0, 120}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
      EquaForgeVC.Interfaces.RealInput v_air[3](each unit = "m/s") "Velocity through the air, vehicle frame" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
      EquaForgeVC.Interfaces.RealInput qbar(unit = "Pa") "Dynamic pressure" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
      EquaForgeVC.Interfaces.RealOutput hingeMoment(unit = "N.m") "Moment of the air on the hinge, opening positive" annotation(Placement(transformation(origin = {0, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      Real F[3](each unit = "N") "Force on the vehicle, vehicle frame";
      Real N(unit = "N") "Normal force of the flap";
    protected
      Real V(unit = "m/s");
      Real s_cross "Share of the airspeed across the vehicle";
      Real e[2] "Direction of the cross flow (y, z)";
      Real exposure "Area exposed to the cross flow, 0..1";
    equation
      V = noEvent(max(sqrt(v_air*v_air), 1e-6));
      s_cross = sqrt(v_air[2]^2 + v_air[3]^2)/V;
      e = {v_air[2], v_air[3]}/noEvent(max(sqrt(v_air[2]^2 + v_air[3]^2), 1e-6));
      exposure = sin(noEvent(min(max(delta, 0), EquaForgeVC.pi/2)));
      N = qbar*S*CN_plate*exposure*s_cross^2;
      F = -N*{0, e[1], e[2]};
      frame_b.f = -F;
      frame_b.t = zeros(3);
      hingeMoment = -N*hingeArm*cos(noEvent(min(max(delta, 0), EquaForgeVC.pi/2)));
      annotation(Documentation(info = "<html><p>A flap of the kind a vehicle steers with in a belly-first descent: folded against the body it catches no air; opened by <b>delta</b> it presents its area to the cross flow and pushes the vehicle at its place. Opening the forward flaps more than the aft ones pitches the vehicle up; left against right rolls and yaws it.</p><h4>Equations</h4><pre>N = qbar S CN_plate sin(delta) sin^2(alpha_t)\nF = -N e_cross          (at frame_b)\nhinge moment = -N hingeArm cos(delta)   (the air folds the flap back)</pre><h4>How to use</h4><p>Place frame_b at the flap with a <code>RigidBodyFrame</code>; drive delta from an actuator and feed the actuator the hinge moment.</p></html>"),
        Icon(graphics = {
          Rectangle(extent = {{-80, -20}, {80, -40}}, lineColor = {95, 95, 95}, fillColor = {220, 220, 220}, fillPattern = FillPattern.Solid),
          Polygon(points = {{-40, -20}, {40, -20}, {20, 50}, {-20, 50}}, lineColor = {60, 60, 60}, fillColor = {80, 80, 80}, fillPattern = FillPattern.Solid),
          Line(points = {{-90, 70}, {-40, 40}}, color = {0, 0, 127}, arrow = {Arrow.None, Arrow.Filled}),
          Text(extent = {{-150, -50}, {150, -80}}, textString = "S=%S")}));
    end Flap;

    model GridFinSet "Four grid fins around a vehicle's end: pitch, yaw and roll control in a tail-first descent"
      extends EquaForgeVC.Icons.Component;
      parameter Real S(unit = "m2") = 5 "Area of one fin";
      parameter Real CN_delta(unit = "1/rad") = 3.0 "Normal force coefficient per radian of fin deflection";
      parameter Real CA_fin = 1.0 "Axial force coefficient of one fin (its drag)";
      parameter Real radius(unit = "m") = 6 "Distance of the fins' centres from the axis";
      parameter Real hingeArm(unit = "m") = 0.3 "From the fin's axis to its centre of pressure";
      Multibody.Interfaces.Frame_b frame_b "At the fins' station on the axis" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
      EquaForgeVC.Interfaces.RealInput delta[4](each unit = "rad", each displayUnit = "deg") "Deflection of fins 1..4 (at 0, 90, 180, 270 deg about x from y)" annotation(Placement(transformation(origin = {0, 120}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
      EquaForgeVC.Interfaces.RealInput qbar(unit = "Pa") "Dynamic pressure" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealOutput hingeMoment[4](each unit = "N.m") "Moment of the air on each fin's hinge" annotation(Placement(transformation(origin = {0, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      Real F[3](each unit = "N") "Total force, vehicle frame";
      Real M[3](each unit = "N.m") "Total moment about frame_b";
    protected
      final parameter Real phi[4] = {0, EquaForgeVC.pi/2, EquaForgeVC.pi, 3*EquaForgeVC.pi/2};
      Real Ff[4, 3] "Force of each fin";
      Real p[4, 3] "Place of each fin";
    equation
      for k in 1:4 loop
        p[k] = {0, radius*cos(phi[k]), radius*sin(phi[k])};
        // the fin's normal force is tangential: across the radius at its place
        Ff[k] = qbar*S*{CA_fin, -CN_delta*delta[k]*sin(phi[k]), CN_delta*delta[k]*cos(phi[k])};
        hingeMoment[k] = -qbar*S*CN_delta*delta[k]*hingeArm;
      end for;
      F = {sum(Ff[k, 1] for k in 1:4), sum(Ff[k, 2] for k in 1:4), sum(Ff[k, 3] for k in 1:4)};
      // p_k has no x component: p x F = {p_y F_z - p_z F_y, p_z F_x, -p_y F_x}
      M = {sum(p[k, 2]*Ff[k, 3] - p[k, 3]*Ff[k, 2] for k in 1:4), sum(p[k, 3]*Ff[k, 1] for k in 1:4), sum(-p[k, 2]*Ff[k, 1] for k in 1:4)};
      frame_b.f = -F;
      frame_b.t = -M;
      annotation(Documentation(info = "<html><p>The lattice fins at the top of a booster that falls tail-first: each fin turns about its radial axis and its force acts across that axis, so opposite fins turned the same way roll the vehicle and turned oppositely pitch or yaw it. Their drag pushes along the axis. The air flows along the vehicle (tail-first), so the force follows the fin's deflection and the dynamic pressure; the sign of x depends on the direction of flight, here taken as tail-first (the drag towards +x).</p><h4>Equations</h4><pre>fin k at angle phi_k: place p_k = {0, r cos phi_k, r sin phi_k}\nF_k = qbar S {CA_fin, -CN_delta delta_k sin phi_k, CN_delta delta_k cos phi_k}\nM = sum p_k x F_k,  hinge_k = -qbar S CN_delta delta_k hingeArm</pre></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-30, 30}, {30, -30}}, lineColor = {95, 95, 95}, fillColor = {220, 220, 220}, fillPattern = FillPattern.Solid),
          Rectangle(extent = {{-80, 10}, {-40, -10}}, lineColor = {60, 60, 60}, fillColor = {120, 120, 120}, fillPattern = FillPattern.CrossDiag),
          Rectangle(extent = {{40, 10}, {80, -10}}, lineColor = {60, 60, 60}, fillColor = {120, 120, 120}, fillPattern = FillPattern.CrossDiag),
          Rectangle(extent = {{-10, 80}, {10, 40}}, lineColor = {60, 60, 60}, fillColor = {120, 120, 120}, fillPattern = FillPattern.CrossDiag),
          Rectangle(extent = {{-10, -40}, {10, -80}}, lineColor = {60, 60, 60}, fillColor = {120, 120, 120}, fillPattern = FillPattern.CrossDiag)}));
    end GridFinSet;
    annotation(Documentation(info = "<html><p>The air on a vehicle: the body (<code>BodyAero</code>), its flaps (<code>Flap</code>) and grid fins (<code>GridFinSet</code>). They take the airspeed and the dynamic pressure from <code>Environment.AirData</code> and act on the vehicle's frame. Body axes: x along the vehicle, y towards its belly.</p></html>"));
  end Aerodynamics;

  package Propulsion "Propellant tanks, turbopumps, engines and engine clusters"
    model PropellantTank "Cryogenic propellant tank: liquid, ullage gas, boil-off and venting; the liquid's mass properties"
      extends EquaForgeVC.Icons.Component;
      parameter Real rho_l(unit = "kg/m3") = 1141 "Density of the liquid (oxygen 1141, methane 422)";
      parameter Real radius(unit = "m") = 4.5 "Inner radius";
      parameter Real length(unit = "m") = 30 "Length of the cylindrical volume";
      parameter Real x_bottom(unit = "m") = 0 "Place of the tank's bottom (its outlet) along the vehicle's x axis";
      parameter Real m_start(unit = "kg") = 1e6 "Liquid at the start";
      parameter Real p_start(unit = "Pa") = 3e5 "Ullage pressure at the start";
      parameter Real T_gas(unit = "K") = 250 "Temperature of the ullage gas (warm pressurant)";
      parameter Real R_gas(unit = "J/(kg.K)") = 259.8 "Gas constant of the ullage gas (oxygen 259.8, methane 518.3)";
      parameter Real T_sat(unit = "K") = 90 "Temperature of the boiling liquid (oxygen 90, methane 112)";
      parameter Real h_fg(unit = "J/kg") = 2.13e5 "Latent heat of vaporisation (oxygen 2.13e5, methane 5.1e5)";
      parameter Real p_relief(unit = "Pa") = 4.5e5 "Pressure at which the relief valve opens";
      parameter Real k_vent(unit = "kg/(s.Pa)") = 1e-4 "Relief flow per pascal above p_relief";
      parameter Real m_residual(unit = "kg") = 1000 "Liquid the engines cannot draw: below it the outflow fades and the tank counts as empty";
      final parameter Real V_tank(unit = "m3") = EquaForgeVC.pi*radius^2*length "Volume";
      EquaForgeVC.Interfaces.RealInput mdot_out(unit = "kg/s") "Liquid the engines draw" annotation(Placement(transformation(extent = {{-140, 40}, {-100, 80}})));
      EquaForgeVC.Interfaces.RealInput mdot_press(unit = "kg/s") "Pressurant gas fed to the ullage" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput a_axial(unit = "m/s2") "Specific force along the vehicle's x axis (what settles the liquid at the bottom)" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Thermal.HeatPort heatPort "Heat into the liquid through the wall (boils it off)" annotation(Placement(transformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput p(unit = "Pa") "Ullage pressure" annotation(Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput p_outlet(unit = "Pa") "Pressure at the outlet: ullage plus the column of liquid" annotation(Placement(transformation(origin = {110, 20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput m(unit = "kg") "Liquid in the tank" annotation(Placement(transformation(origin = {110, -20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.BooleanOutput empty "Below the residual" annotation(Placement(transformation(origin = {110, -60}, extent = {{-10, -10}, {10, 10}})));
      Multibody.Interfaces.MassPropertiesOutput mass "The liquid as a body: settled at the bottom" annotation(Placement(transformation(origin = {0, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      Real m_l(unit = "kg", start = m_start, fixed = true, nominal = 1e5) "Liquid";
      Real m_g(unit = "kg", start = p_start*(V_tank - m_start/rho_l)/(R_gas*T_gas), fixed = true) "Ullage gas";
      Real level(unit = "m") "Height of the liquid";
      Real V_u(unit = "m3") "Ullage volume";
      Real mdot_drawn(unit = "kg/s") "Liquid that leaves (less than asked for near empty)";
      Real mdot_boil(unit = "kg/s") "Boil-off";
      Real mdot_vent(unit = "kg/s") "Gas vented by the relief valve";
    equation
      assert(m_start/rho_l < V_tank, "PropellantTank: the liquid does not fit (m_start/rho_l > the tank's volume)");
      level = m_l/(rho_l*EquaForgeVC.pi*radius^2);
      V_u = noEvent(max(V_tank - m_l/rho_l, 1e-3*V_tank));
      p = m_g*R_gas*T_gas/V_u;
      p_outlet = p + rho_l*noEvent(max(a_axial, 0))*level;
      mdot_drawn = mdot_out*noEvent(min(1, max(0, m_l/m_residual)));
      // near empty the wall's heat boils less and less (it warms the gas, which is not modelled)
      mdot_boil = noEvent(max(heatPort.Q_flow, 0))/h_fg*noEvent(min(1, max(0, m_l/m_residual)));
      mdot_vent = k_vent*noEvent(max(p - p_relief, 0));
      der(m_l) = -mdot_drawn - mdot_boil;
      der(m_g) = mdot_press + mdot_boil - mdot_vent;
      heatPort.T = T_sat;
      m = m_l;
      empty = m_l < m_residual;
      mass.m = m_l;
      mass.r_CM = {x_bottom + level/2, 0, 0};
      mass.I = {0.5*m_l*radius^2, m_l*(3*radius^2 + level^2)/12, m_l*(3*radius^2 + level^2)/12, 0, 0, 0};
      annotation(Documentation(info = "<html><p>A tank of liquid oxygen or methane in a rocket stage. The engines draw liquid from the bottom; pressurant gas keeps the ullage above it pressurised; heat through the wall boils liquid off into the ullage, and the relief valve vents what the tank cannot hold. The liquid, settled at the bottom by the thrust, is a body of its own whose mass, centre of mass and inertia the stage adds to its structure.</p><h4>Equations</h4><pre>der(m_l) = -(mdot_out + Q/h_fg) f(m_l),  f = min(1, m_l / m_residual)\nder(m_g) = mdot_press + Q/h_fg f(m_l) - k_vent max(0, p - p_relief)\np = m_g R T_gas / (V - m_l/rho_l),   p_outlet = p + rho_l a_x level\nlevel = m_l / (rho_l pi r^2),  centre of mass at x_bottom + level/2</pre><h4>Assumptions</h4><p>A cylindrical tank along the vehicle's x axis, the liquid settled at its bottom (positive axial acceleration) and at its boiling temperature, the ullage gas an ideal gas at a fixed temperature. Slosh and stratification are left out.</p><h4>How to use</h4><p>Feed the engines' propellant flow to <b>mdot_out</b>, a pressurant flow (a share of the engine flow, set by a pressure controller) to <b>mdot_press</b> and the vehicle's specific force to <b>a_axial</b>; connect the wall's heat to <b>heatPort</b>. Add <b>mass</b> to the stage's mass properties.</p></html>"),
        Icon(graphics = {
          Rectangle(extent = {{-50, 90}, {50, -90}}, lineColor = {64, 64, 64}, fillColor = {235, 235, 235}, fillPattern = FillPattern.Solid, radius = 20),
          Rectangle(extent = {{-50, 10}, {50, -90}}, lineColor = {0, 90, 160}, fillColor = {120, 180, 235}, fillPattern = FillPattern.Solid, radius = 20),
          Line(points = {{-40, 10}, {40, 10}}, color = {0, 90, 160}),
          Line(points = {{0, -90}, {0, -100}}, color = {64, 64, 64}),
          Text(extent = {{-40, 70}, {40, 30}}, textString = "p"),
          Text(extent = {{-150, -120}, {150, -150}}, textString = "%name")}));
    end PropellantTank;

    model TurbopumpLoad "Centrifugal pump on a turbopump shaft: head and absorbed torque grow with the square of the speed"
      extends EquaForgeVC.Icons.Component;
      parameter Real w_nominal(unit = "rad/s") = 3000 "Speed at the nominal point";
      parameter Real dp_nominal(unit = "Pa") = 4e7 "Pressure rise at the nominal speed";
      parameter Real P_nominal(unit = "W") = 5e7 "Shaft power at the nominal speed";
      EquaForgeVC.Interfaces.Flange flange "Shaft" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      EquaForgeVC.Interfaces.RealOutput dp(unit = "Pa") "Pressure rise" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
      Real w(unit = "rad/s") "Speed";
      Real tau(unit = "N.m") "Torque the pump absorbs";
      Real power(unit = "W") "Shaft power";
    equation
      w = der(flange.phi);
      tau = P_nominal/w_nominal*(w/w_nominal)*abs(w/w_nominal);
      flange.tau = tau;
      dp = dp_nominal*(w/w_nominal)^2;
      power = tau*w;
      annotation(Documentation(info = "<html><p>The pump of a turbopump as a load on its shaft: by the affinity laws its pressure rise grows with the square of the speed and the power it absorbs with the cube, so the torque grows with the square.</p><h4>Equations</h4><pre>tau = P_nom/w_nom (w/w_nom) |w/w_nom|,  dp = dp_nom (w/w_nom)^2</pre><h4>How to use</h4><p>Put it on the shaft (an <code>Inertia</code>) that the turbine (a <code>Torque</code>) drives.</p></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-60, 60}, {60, -60}}, lineColor = {64, 64, 64}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid),
          Line(points = {{0, 0}, {40, 30}}, color = {64, 64, 64}, thickness = 0.5),
          Line(points = {{0, 0}, {-10, 50}}, color = {64, 64, 64}, thickness = 0.5),
          Line(points = {{0, 0}, {-45, -20}}, color = {64, 64, 64}, thickness = 0.5),
          Line(points = {{0, 0}, {20, -45}}, color = {64, 64, 64}, thickness = 0.5),
          Line(points = {{-90, 0}, {-60, 0}}, color = {64, 64, 64})}));
    end TurbopumpLoad;

    block Nozzle "Thrust of a nozzle from the chamber and ambient pressures; flow separation warning"
      extends EquaForgeVC.Icons.Block;
      parameter Real F_vac(unit = "N") = 2.65e6 "Thrust in vacuum at the nominal chamber pressure";
      parameter Real pc_nominal(unit = "Pa") = 3e7 "Nominal chamber pressure";
      parameter Real A_e(unit = "m2") = 1.5 "Exit area";
      parameter Real pe_ratio = 2.2e-3 "Exit pressure / chamber pressure (set by the expansion ratio)";
      EquaForgeVC.Interfaces.RealInput pc(unit = "Pa") "Chamber pressure" annotation(Placement(transformation(extent = {{-140, 40}, {-100, 80}})));
      EquaForgeVC.Interfaces.RealInput p_amb(unit = "Pa") "Ambient pressure" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealOutput F(unit = "N") "Thrust" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
      Real p_e(unit = "Pa") "Exit pressure";
    equation
      F = noEvent(max(F_vac*pc/pc_nominal - p_amb*A_e, 0));
      p_e = pe_ratio*pc;
      assert(not (pc > 0.4*pc_nominal and p_e < 0.25*p_amb), "Nozzle: the flow separates inside the nozzle (exit pressure below 25 % of ambient)", AssertionLevel.warning);
      annotation(Documentation(info = "<html><p>The thrust of a rocket nozzle: its vacuum thrust, which grows with the chamber pressure, less the ambient pressure on its exit area. A vacuum-optimised nozzle at sea level loses a large share of its thrust, and when the pressure at its exit falls below about a quarter of the ambient pressure the flow separates from its wall (Schmucker; Summerfield gives 40 % for older nozzles): a warning, as the side loads can destroy it.</p><h4>Equations</h4><pre>F = F_vac pc/pc_nominal - p_amb A_e\np_e = pe_ratio pc,  separation when p_e &lt; 0.25 p_amb</pre></html>"),
        Icon(graphics = {
          Polygon(points = {{-60, 20}, {-20, 10}, {60, 60}, {60, -60}, {-20, -10}, {-60, -20}}, lineColor = {64, 64, 64}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid),
          Line(points = {{60, 40}, {90, 50}}, color = {230, 120, 0}),
          Line(points = {{60, 0}, {95, 0}}, color = {230, 120, 0}),
          Line(points = {{60, -40}, {90, -50}}, color = {230, 120, 0})}));
    end Nozzle;

    model RocketEngine "Liquid rocket engine: turbopump shaft, chamber and nozzle; thrust from the throttle and the ambient pressure"
      extends EquaForgeVC.Icons.Component;
      parameter Real F_vac(unit = "N") = 2.65e6 "Vacuum thrust at full throttle";
      parameter Real Isp_vac(unit = "s") = 350 "Vacuum specific impulse";
      parameter Real A_e(unit = "m2") = 1.5 "Nozzle exit area";
      parameter Real pe_ratio = 2.2e-3 "Exit pressure / chamber pressure";
      parameter Real pc_nominal(unit = "Pa") = 3e7 "Chamber pressure at full throttle";
      parameter Real MR = 3.6 "Mixture ratio: oxidiser / fuel mass flow";
      parameter Real throttleMin = 0.4 "Lowest throttle while running";
      parameter Real w_nominal(unit = "rad/s") = 3000 "Turbopump speed at full throttle";
      parameter Real J_shaft(unit = "kg.m2") = 3 "Inertia of the turbopump shaft";
      parameter Real P_pump(unit = "W") = 5e7 "Pump power at full throttle";
      parameter Real d_bearing(unit = "N.m.s/rad") = 0.5 "Bearing and seal friction";
      parameter Real tauTurbineMax(unit = "N.m") = 3.5e4 "Largest turbine torque";
      parameter Real kSpeed(unit = "N.m.s/rad") = 60 "Speed controller gain";
      parameter Real TiSpeed(unit = "s") = 0.2 "Speed controller integral time";
      parameter Real T_chamber(unit = "s") = 0.05 "Lag of the chamber pressure";
      final parameter Real mdot_nominal(unit = "kg/s") = F_vac/(Isp_vac*EquaForgeAerospace.g0) "Propellant flow at full throttle";
      EquaForgeVC.Interfaces.RealInput throttle "Thrust command, throttleMin..1" annotation(Placement(transformation(extent = {{-140, 40}, {-100, 80}})));
      EquaForgeVC.Interfaces.BooleanInput on "Running" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput p_amb(unit = "Pa") "Ambient pressure" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealOutput F(unit = "N") "Thrust" annotation(Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput mdot(unit = "kg/s") "Propellant flow" annotation(Placement(transformation(origin = {110, 20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput mdot_ox(unit = "kg/s") "Oxidiser flow" annotation(Placement(transformation(origin = {110, -20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput mdot_fuel(unit = "kg/s") "Fuel flow" annotation(Placement(transformation(origin = {110, -60}, extent = {{-10, -10}, {10, 10}})));
      Real Isp(unit = "s") "Delivered specific impulse";
      Real pc(unit = "Pa") "Chamber pressure";
      Blocks.Limiter throttleLimit(uMax = 1, uMin = throttleMin, generateEvent = false) annotation(Placement(transformation(origin = {-70, 60}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Switch running "Running: the throttle; shut down: the speed it has (the controller then rests)" annotation(Placement(transformation(origin = {-40, 40}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Gain speedShare(k = 1/w_nominal) annotation(Placement(transformation(origin = {-70, 20}, extent = {{-6, -6}, {6, 6}})));
      Blocks.Switch turbineValve "Closed at shutdown: the turbine no longer drives the shaft" annotation(Placement(transformation(origin = {35, 60}, extent = {{-6, -6}, {6, 6}})));
      Blocks.Constant noTorque(k = 0) annotation(Placement(transformation(origin = {15, 75}, extent = {{-5, -5}, {5, 5}})));
      Blocks.Gain speedRef(k = w_nominal) annotation(Placement(transformation(origin = {-10, 40}, extent = {{-10, -10}, {10, 10}})));
      Blocks.PI speedControl(k = kSpeed, Ti = TiSpeed, yMax = tauTurbineMax, yMin = 0) annotation(Placement(transformation(origin = {20, 40}, extent = {{-10, -10}, {10, 10}})));
      Mechanics.Torque turbine annotation(Placement(transformation(origin = {50, 40}, extent = {{-10, -10}, {10, 10}})));
      Mechanics.Inertia shaft(J = J_shaft) annotation(Placement(transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}})));
      Mechanics.RotationalDamper bearings(d = d_bearing) annotation(Placement(transformation(origin = {20, -20}, extent = {{-10, -10}, {10, 10}})));
      TurbopumpLoad pump(w_nominal = w_nominal, P_nominal = P_pump) annotation(Placement(transformation(origin = {80, 0}, extent = {{-10, -10}, {10, 10}})));
      Mechanics.SpeedSensor speed annotation(Placement(transformation(origin = {50, -40}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Gain flowRatio(k = pc_nominal/w_nominal) "Pump flow follows its speed" annotation(Placement(transformation(origin = {-40, -40}, extent = {{-10, -10}, {10, 10}})));
      Blocks.BooleanSwitch mainValves "Closed at cutoff: no more flow into the chamber, whatever the pumps still turn" annotation(Placement(transformation(origin = {-40, -70}, extent = {{-10, -10}, {10, 10}})));
      Blocks.FirstOrder chamber(T = T_chamber) annotation(Placement(transformation(origin = {-10, -40}, extent = {{-10, -10}, {10, 10}})));
      Nozzle nozzle(F_vac = F_vac, pc_nominal = pc_nominal, A_e = A_e, pe_ratio = pe_ratio) annotation(Placement(transformation(origin = {20, -70}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(throttle, throttleLimit.u);
      connect(throttleLimit.y, running.u1);
      connect(on, running.u2);
      connect(speed.w, speedShare.u);
      connect(speedShare.y, running.u3);
      connect(running.y, speedRef.u);
      connect(speedRef.y, speedControl.u_s);
      connect(speedControl.y, turbineValve.u1);
      connect(on, turbineValve.u2);
      connect(noTorque.y, turbineValve.u3);
      connect(turbineValve.y, turbine.tau);
      connect(turbine.flange, shaft.flange_a);
      connect(shaft.flange_b, pump.flange);
      connect(shaft.flange_a, bearings.flange);
      connect(shaft.flange_a, speed.flange);
      connect(speed.w, speedControl.u_m);
      connect(speed.w, flowRatio.u);
      connect(flowRatio.y, mainValves.on);
      connect(on, mainValves.u);
      connect(mainValves.y, chamber.u);
      connect(chamber.y, nozzle.pc);
      connect(p_amb, nozzle.p_amb);
      pc = chamber.y;
      mdot = mdot_nominal*noEvent(max(pc, 0))/pc_nominal;
      F = nozzle.F;
      mdot_ox = mdot*MR/(1 + MR);
      mdot_fuel = mdot/(1 + MR);
      Isp = F/(noEvent(max(mdot, 1e-6))*EquaForgeAerospace.g0);
      annotation(Documentation(info = "<html><p>A pump-fed liquid rocket engine. The throttle sets the speed of the turbopump; a speed controller sets the turbine torque that drives the shaft against the pump and its bearings; the pump's flow follows its speed and fills the chamber, whose pressure follows with a lag; the nozzle turns the chamber pressure into thrust, less the ambient pressure on its exit. The delivered specific impulse falls at low altitude, most for a vacuum nozzle.</p><h4>Equations</h4><pre>w_ref = w_nom clamp(throttle, throttleMin, 1)   while on; shut down: w_ref = w, the turbine valve closed\nJ der(w) = tau_turbine - tau_pump(w) - d w,  tau_turbine = PI(w_ref - w)\nT_c der(pc) + pc = pc_nom w / w_nom   (main valves open while on, else 0)\nmdot = mdot_nom pc/pc_nom,  F = F_vac pc/pc_nom - p_amb A_e\nmdot_ox = mdot MR/(1 + MR),  mdot_fuel = mdot/(1 + MR)</pre><h4>Assumptions</h4><p>One shaft stands for the engine's turbopumps; the combustion efficiency and the mixture ratio do not change with the throttle. The start and shutdown transients follow the shaft and the chamber lag only.</p><h4>How to use</h4><p>Drive <b>throttle</b> and <b>on</b> from the flight computer and <b>p_amb</b> from the atmosphere; draw the flows from the tanks. An <code>EngineCluster</code> uses one engine for a ring of identical ones.</p></html>"),
        Icon(graphics = {
          Rectangle(extent = {{-40, 80}, {40, 20}}, lineColor = {64, 64, 64}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid),
          Polygon(points = {{-30, 20}, {30, 20}, {15, 0}, {-15, 0}}, lineColor = {64, 64, 64}, fillColor = {150, 150, 150}, fillPattern = FillPattern.Solid),
          Polygon(points = {{-15, 0}, {15, 0}, {50, -70}, {-50, -70}}, lineColor = {64, 64, 64}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid),
          Polygon(points = {{-45, -70}, {45, -70}, {20, -100}, {-20, -100}}, lineColor = {230, 120, 0}, fillColor = {255, 190, 60}, fillPattern = FillPattern.Solid),
          Text(extent = {{-150, 120}, {150, 90}}, textString = "%name")}));
    end RocketEngine;

    model EngineCluster "A ring of identical engines on a gimbal: thrust, flows and an engine out"
      extends EquaForgeVC.Icons.Component;
      parameter Integer N(min = 1) = 3 "Engines in the ring";
      parameter Real ringRadius(unit = "m") = 1.5 "Radius of the ring";
      parameter Real failedAngle(unit = "rad", displayUnit = "deg") = 0 "Place of the engine that may fail, about x from y";
      parameter Real F_vac(unit = "N") = 2.65e6 "Vacuum thrust of one engine";
      parameter Real Isp_vac(unit = "s") = 350 "Vacuum specific impulse";
      parameter Real A_e(unit = "m2") = 1.5 "Exit area of one nozzle";
      parameter Real pe_ratio = 2.2e-3 "Exit pressure / chamber pressure";
      parameter Real MR = 3.6 "Mixture ratio";
      parameter Real throttleMin = 0.4 "Lowest throttle while running";
      Multibody.Interfaces.Frame_b frame_b "The gimbal point on the vehicle; thrust along its +x axis" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
      EquaForgeVC.Interfaces.RealInput throttle "Thrust command, throttleMin..1" annotation(Placement(transformation(extent = {{-140, 60}, {-100, 100}})));
      EquaForgeVC.Interfaces.BooleanInput on "Running" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
      EquaForgeVC.Interfaces.RealInput gimbal[2](each unit = "rad", each displayUnit = "deg") "Gimbal angles: about the vehicle's y axis, about its z axis" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.BooleanInput failed "One engine out" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
      EquaForgeVC.Interfaces.RealInput p_amb(unit = "Pa") "Ambient pressure" annotation(Placement(transformation(extent = {{-140, -100}, {-100, -60}})));
      EquaForgeVC.Interfaces.RealOutput thrust(unit = "N") "Thrust of the ring" annotation(Placement(transformation(origin = {-60, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      EquaForgeVC.Interfaces.RealOutput mdot_ox(unit = "kg/s") "Oxidiser flow of the ring" annotation(Placement(transformation(origin = {0, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      EquaForgeVC.Interfaces.RealOutput mdot_fuel(unit = "kg/s") "Fuel flow of the ring" annotation(Placement(transformation(origin = {60, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      Integer running "Engines running";
      Real F[3](each unit = "N") "Thrust vector, vehicle frame";
      Real mdot(unit = "kg/s") "Propellant flow of the ring";
      RocketEngine engine(F_vac = F_vac, Isp_vac = Isp_vac, A_e = A_e, pe_ratio = pe_ratio, MR = MR, throttleMin = throttleMin) "One of the ring's engines" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
    protected
      Real shift[3](each unit = "m") "Thrust centre with an engine out";
    equation
      connect(throttle, engine.throttle);
      connect(on, engine.on);
      connect(p_amb, engine.p_amb);
      running = if failed then N - 1 else N;
      thrust = running*engine.F;
      mdot = running*engine.mdot;
      mdot_ox = running*engine.mdot_ox;
      mdot_fuel = running*engine.mdot_fuel;
      F = thrust*{cos(gimbal[1])*cos(gimbal[2]), cos(gimbal[1])*sin(gimbal[2]), -sin(gimbal[1])};
      shift = if failed and N > 1 then -ringRadius/(N - 1)*{0, cos(failedAngle), sin(failedAngle)} else zeros(3);
      frame_b.f = -F;
      frame_b.t = -cross(shift, F);
      annotation(Documentation(info = "<html><p>A ring of <b>N</b> identical engines that gimbal together: one <code>RocketEngine</code> stands for each of them. Their thrust points along the gimbal frame's x axis, turned by the two gimbal angles; with an engine out (<b>failed</b>) the ring gives N - 1 times the thrust of one engine, and its centre moves away from the failed engine, which turns the vehicle.</p><h4>Equations</h4><pre>n = N (or N - 1 failed),  thrust = n F_engine,  flows = n flows_engine\nF = thrust {cos d1 cos d2, cos d1 sin d2, -sin d1}\nengine out: thrust centre at -r/(N - 1) {0, cos phi, sin phi}</pre><h4>How to use</h4><p>Put frame_b at the gimbal point with a <code>RigidBodyFrame</code> from the vehicle's frame; for a ring that does not gimbal feed zeros to <b>gimbal</b>.</p></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {95, 95, 95}, fillColor = {235, 235, 235}, fillPattern = FillPattern.Solid),
          Ellipse(extent = {{-15, 55}, {15, 25}}, lineColor = {64, 64, 64}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid),
          Ellipse(extent = {{-50, 5}, {-20, -25}}, lineColor = {64, 64, 64}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid),
          Ellipse(extent = {{20, 5}, {50, -25}}, lineColor = {64, 64, 64}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid),
          Ellipse(extent = {{-15, -30}, {15, -60}}, lineColor = {200, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
          Text(extent = {{-150, 120}, {150, 90}}, textString = "%name N=%N")}));
    end EngineCluster;
    annotation(Documentation(info = "<html><p>What pushes a rocket: propellant tanks with their pressurisation and boil-off (<code>PropellantTank</code>), pump-fed engines built from a turbopump shaft, a chamber and a nozzle (<code>RocketEngine</code>, <code>TurbopumpLoad</code>, <code>Nozzle</code>) and rings of engines on a gimbal (<code>EngineCluster</code>).</p></html>"));
  end Propulsion;

  package Actuators "Actuators that move gimbals, flaps and fins"
    model ElectromechanicalActuator "Electromechanical actuator: a position servo, a screw or gear and the surface it moves against its air load"
      extends EquaForgeVC.Icons.Component;
      parameter Boolean detailed = true "The servo's motor and its current, speed and position loops; false: their response as a second-order lag (long runs)" annotation(Evaluate = true);
      parameter Real ratio = 200 "Motor turns per turn of the surface (screw and gear)";
      parameter Real J_load(unit = "kg.m2") = 500 "Inertia of the surface (engine, flap) about its hinge";
      parameter Real angleMax(unit = "rad", displayUnit = "deg") = 0.26 "Travel each way";
      parameter Real angleMin(unit = "rad", displayUnit = "deg") = -angleMax "Travel the other way";
      parameter Real Kpp(unit = "1/s") = 20 "Position loop gain of the servo";
      parameter Real Imax(unit = "A") = 100 "Current limit of the motor";
      parameter Real Umax(unit = "V") = 400 "Supply voltage";
      parameter Real k_motor(unit = "N.m/A") = 1.0 "Motor torque constant";
      parameter Real J_motor(unit = "kg.m2") = 0.01 "Rotor inertia of the motor";
      parameter Real R_motor(unit = "Ohm") = 0.05 "Winding resistance";
      final parameter Real J_reflected(unit = "kg.m2") = J_motor + J_load/ratio^2 "Inertia the motor turns";
      final parameter Real Kpw(unit = "A.s/rad") = 4*Kpp*J_reflected/k_motor "Speed loop four times as fast as the position loop";
      parameter Real rateMax(unit = "rad/s") = 0.7*Umax/(k_motor*ratio) "Fastest the surface is asked to move (below the motor's no-load speed)";
      EquaForgeVC.Interfaces.RealInput command(unit = "rad", displayUnit = "deg") "Commanded angle of the surface" annotation(Placement(transformation(extent = {{-140, 40}, {-100, 80}})));
      EquaForgeVC.Interfaces.RealInput loadTorque(unit = "N.m") "Torque of the air (or the thrust) on the surface" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealOutput angle(unit = "rad", displayUnit = "deg") "Angle of the surface" annotation(Placement(transformation(origin = {110, 40}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput current(unit = "A") "Motor current" annotation(Placement(transformation(origin = {110, -40}, extent = {{-10, -10}, {10, 10}})));
      Real power(unit = "W") "Electrical power drawn";
      Blocks.Limiter travel(uMax = angleMax, uMin = angleMin, generateEvent = false) annotation(Placement(transformation(origin = {-70, 60}, extent = {{-10, -10}, {10, 10}})));
      Blocks.SlewRateLimiter slew(rising = rateMax, Td = 0.25/Kpp, generateEvent = false) "Keeps the servo out of its voltage and current limits" annotation(Placement(transformation(origin = {-55, 30}, extent = {{-8, -8}, {8, 8}})));
      Blocks.Gain toMotor(k = ratio) if detailed "Motor angle for the surface angle" annotation(Placement(transformation(origin = {-40, 60}, extent = {{-10, -10}, {10, 10}})));
      Drives.PositionServo servo(Kpp = Kpp, Imax = Imax, Umax = Umax, Jload = J_load/ratio^2, kMotor = k_motor, JMotor = J_motor, RMotor = R_motor, LMotor = 2.5e-4, Kpi = 0.25, Tii = 0.005, Kpw = Kpw, Tiw = 1/Kpp) if detailed annotation(Placement(transformation(origin = {-10, 60}, extent = {{-10, -10}, {10, 10}})));
      Mechanics.IdealGear screw(ratio = ratio) if detailed annotation(Placement(transformation(origin = {30, 60}, extent = {{-10, -10}, {10, 10}})));
      Mechanics.Torque air if detailed annotation(Placement(transformation(origin = {60, 20}, extent = {{-10, -10}, {10, 10}})));
      Mechanics.AngleSensor sensor if detailed annotation(Placement(transformation(origin = {60, 60}, extent = {{-10, -10}, {10, 10}})));
      Blocks.SecondOrder response(w = Kpp, D = 0.9) if not detailed "The closed servo loops as a second-order lag" annotation(Placement(transformation(origin = {-10, -20}, extent = {{-10, -10}, {10, 10}})));
    protected
      EquaForgeVC.Interfaces.RealOutput i_motor(unit = "A") "Motor current, from the servo or from the torque the lag needs";
      EquaForgeVC.Interfaces.RealOutput p_motor(unit = "W");
    equation
      connect(command, travel.u);
      connect(travel.y, slew.u);
      connect(slew.y, toMotor.u);
      connect(toMotor.y, servo.phiRef);
      connect(servo.flange, screw.flange_a);
      connect(screw.flange_b, sensor.flange);
      connect(screw.flange_b, air.flange);
      connect(loadTorque, air.tau);
      connect(sensor.phi, angle);
      connect(servo.current, i_motor);
      connect(slew.y, response.u);
      connect(response.y, angle);
      if detailed then
        p_motor = servo.motor.v*servo.motor.i;
      else
        // the torque the lag needs, through the ratio: J_reflected accelerates the motor, the load pushes back
        i_motor = (J_reflected*ratio*der(response.yd) - loadTorque/ratio)/k_motor;
        p_motor = abs(k_motor*i_motor*ratio*response.yd) + R_motor*i_motor^2;
      end if;
      current = i_motor;
      power = p_motor;
      annotation(Documentation(info = "<html><p>The electric actuators that swivel the engines of a rocket and move its flaps and fins: a servo motor in position control (<code>Drives.PositionServo</code>, a DC motor with current, speed and position loops) turns a screw or gear of ratio <b>ratio</b> that moves the surface; the surface's inertia is felt at the motor through the ratio, and the air load (or the thrust's moment on a gimbal) pushes back. The command is limited to the travel and slewed at most at <b>rateMax</b>, below the motor's no-load speed, so the servo stays out of its voltage and current limits.</p><h4>Equations</h4><pre>reference = slew(clamp(command, angleMin, angleMax)),  slew rate at most rateMax\ndetailed: motor angle reference = ratio reference, surface angle = motor angle / ratio\n          speed loop gain Kpw = 4 Kpp (J_motor + J_load/ratio^2) / k_motor\nreduced:  der(der(angle)) = Kpp^2 (reference - angle) - 1.8 Kpp der(angle)\n          i = (J_reflected ratio der(der(angle)) - load/ratio) / k_motor</pre><p>With <b>detailed</b> = false the closed loops become a second-order lag at the position loop's bandwidth and the current follows from the torque it needs: the same response for a run of hours, without the motor's microsecond electrics. The saturating inner loops of the detailed servo can switch faster than any step a solver takes when it is driven hard.</p><h4>How to use</h4><p>Feed the commanded angle and the load (a <code>Flap</code>'s hinge moment); read the angle, the motor current and the power drawn from the bus.</p></html>"),
        Icon(graphics = {
          Rectangle(extent = {{-80, 30}, {0, -30}}, lineColor = {0, 0, 0}, fillColor = {0, 110, 200}, fillPattern = FillPattern.HorizontalCylinder),
          Rectangle(extent = {{0, 10}, {80, -10}}, lineColor = {64, 64, 64}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Forward),
          Text(extent = {{-80, 20}, {0, -20}}, textString = "M", textColor = {255, 255, 255}),
          Text(extent = {{-150, -40}, {150, -70}}, textString = "i=%ratio")}));
    end ElectromechanicalActuator;
    annotation(Documentation(info = "<html><p>Actuators of flight control surfaces and engine gimbals, built from the drive, mechanics and signal blocks.</p></html>"));
  end Actuators;

  package GNC "Guidance, navigation and control: orbits, ground tracks, sensors, steering and landing"
    block OrbitalElements "Classical orbital elements of a position and velocity"
      extends EquaForgeVC.Icons.Block;
      parameter Real mu(unit = "m3/s2") = EquaForgeAerospace.muEarth "Gravitational parameter";
      parameter Real Re(unit = "m") = EquaForgeAerospace.radiusEarth "Radius for apoapsis and periapsis altitudes";
      Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle (position and velocity, world frame)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      EquaForgeVC.Interfaces.RealOutput apoapsis(unit = "m") "Altitude of the apoapsis" annotation(Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput periapsis(unit = "m") "Altitude of the periapsis" annotation(Placement(transformation(origin = {110, 20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput inclination(unit = "rad", displayUnit = "deg") "Inclination" annotation(Placement(transformation(origin = {110, -20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput energy(unit = "J/kg") "Specific orbital energy" annotation(Placement(transformation(origin = {110, -60}, extent = {{-10, -10}, {10, 10}})));
      Real a(unit = "m") "Semi-major axis (negative: hyperbola)";
      Real e "Eccentricity";
      Real raan(unit = "rad", displayUnit = "deg") "Right ascension of the ascending node";
      Real argPeriapsis(unit = "rad", displayUnit = "deg") "Argument of periapsis";
      Real trueAnomaly(unit = "rad", displayUnit = "deg") "True anomaly";
      Real period(unit = "s") "Orbital period (0 for an open orbit)";
      Real h[3](each unit = "m2/s") "Specific angular momentum";
      Real flightPathAngle(unit = "rad", displayUnit = "deg") "Angle of the velocity above the local horizontal";
    protected
      Real rn(unit = "m"), vn(unit = "m/s"), hn(unit = "m2/s");
      Real ev[3] "Eccentricity vector";
      Real nv[3] "Line of nodes";
      Real nn;
    equation
      rn = sqrt(vehicle.r*vehicle.r);
      vn = sqrt(vehicle.v*vehicle.v);
      h = cross(vehicle.r, vehicle.v);
      hn = sqrt(h*h);
      energy = vn^2/2 - mu/rn;
      a = -mu/(2*noEvent(if abs(energy) > 1e-9 then energy else -1e-9));
      ev = cross(vehicle.v, h)/mu - vehicle.r/rn;
      e = sqrt(ev*ev);
      inclination = acos(noEvent(max(-1, min(1, h[3]/max(hn, 1e-9)))));
      nv = {-h[2], h[1], 0};
      nn = sqrt(nv[1]^2 + nv[2]^2);
      raan = atan2(nv[2], nv[1]);
      argPeriapsis = atan2((cross(nv, ev)*h)/max(hn, 1e-9), nv*ev);
      trueAnomaly = atan2((cross(ev, vehicle.r)*h)/max(hn, 1e-9), ev*vehicle.r);
      apoapsis = noEvent(if energy < 0 then a*(1 + e) - Re else 1e12);
      periapsis = a*(1 - e) - Re;
      period = noEvent(if energy < 0 then 2*EquaForgeVC.pi*sqrt(a^3/mu) else 0);
      flightPathAngle = asin(noEvent(max(-1, min(1, (vehicle.r*vehicle.v)/(max(rn*vn, 1e-9))))));
      annotation(Documentation(info = "<html><p>The orbit a vehicle is on now, from its position and velocity: its size and shape (semi-major axis, eccentricity, apoapsis and periapsis altitudes), the place of its plane (inclination, ascending node) and the vehicle's place on it (argument of periapsis, true anomaly). Burns change the orbit; between them it stays, apart from the slow turn of the node and the apsides by J2.</p><h4>Equations</h4><pre>h = r x v,  energy = v^2/2 - mu/r,  a = -mu / (2 energy)\ne = (v x h)/mu - r/|r|,  i = acos(h_z/|h|)\nnode n = z x h,  RAAN = atan2(n_y, n_x)\napoapsis = a (1 + e) - Re,  periapsis = a (1 - e) - Re</pre><p>The angles of the node and of the periapsis are not defined for an equatorial or a circular orbit; atan2 still gives a value.</p></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-80, 50}, {80, -50}}, lineColor = {0, 0, 127}),
          Ellipse(extent = {{-25, 15}, {5, -15}}, lineColor = {0, 70, 140}, fillColor = {60, 130, 210}, fillPattern = FillPattern.Sphere),
          Ellipse(extent = {{60, 30}, {76, 14}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
          Text(extent = {{-90, -55}, {90, -90}}, textString = "a e i")}));
    end OrbitalElements;

    block GroundTrack "The point under the vehicle on the turning Earth, and the way to a target"
      extends EquaForgeVC.Icons.Block;
      parameter Real Re(unit = "m") = EquaForgeAerospace.radiusEarth "Radius of the Earth";
      parameter Real omega(unit = "rad/s") = EquaForgeAerospace.omegaEarth "Rotation of the Earth";
      parameter Real theta0(unit = "rad") = 0 "Angle of longitude 0 at time 0 (as RotatingEarth)";
      parameter Real latTarget(unit = "rad", displayUnit = "deg") = 0 "Latitude of the target";
      parameter Real lonTarget(unit = "rad", displayUnit = "deg") = 0 "Longitude of the target";
      Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      EquaForgeVC.Interfaces.RealOutput latitude(unit = "rad", displayUnit = "deg") "Geocentric latitude" annotation(Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput longitude(unit = "rad", displayUnit = "deg") "Longitude" annotation(Placement(transformation(origin = {110, 20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput altitude(unit = "m") "Height above the sphere" annotation(Placement(transformation(origin = {110, -20}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput distance(unit = "m") "Great-circle distance to the target along the ground" annotation(Placement(transformation(origin = {110, -60}, extent = {{-10, -10}, {10, 10}})));
      Real bearing(unit = "rad", displayUnit = "deg") "Direction of the target from the point below, from north towards east";
      Real r_ecef[3](each unit = "m") "Earth-fixed position";
    protected
      Real theta;
      Real c "cos of the central angle to the target";
    equation
      theta = theta0 + omega*time;
      r_ecef = Multibody.Frames.planarRotation({0, 0, 1}, theta)*vehicle.r;
      altitude = sqrt(r_ecef*r_ecef) - Re;
      latitude = asin(noEvent(max(-1, min(1, r_ecef[3]/(altitude + Re)))));
      longitude = atan2(r_ecef[2], r_ecef[1]);
      c = noEvent(max(-1, min(1, sin(latitude)*sin(latTarget) + cos(latitude)*cos(latTarget)*cos(lonTarget - longitude))));
      distance = Re*acos(c);
      bearing = atan2(sin(lonTarget - longitude)*cos(latTarget), cos(latitude)*sin(latTarget) - sin(latitude)*cos(latTarget)*cos(lonTarget - longitude));
      annotation(Documentation(info = "<html><p>Where on the Earth a vehicle is: the latitude and longitude of the point below it, which trace its ground track as the Earth turns under its orbit, and the distance and bearing along the ground to a target (a landing site).</p><h4>Equations</h4><pre>r_ecef = planarRotation(z, theta0 + omega t) r\nlat = asin(z/|r|), lon = atan2(y, x)\ndistance = Re acos(sin lat sin lat_t + cos lat cos lat_t cos(lon_t - lon))</pre></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {0, 70, 140}, fillColor = {200, 225, 245}, fillPattern = FillPattern.Solid),
          Line(points = {{-70, -20}, {-30, 20}, {10, 30}, {50, 0}, {70, -30}}, color = {200, 0, 0}, thickness = 0.5, smooth = Smooth.Bezier),
          Ellipse(extent = {{44, 6}, {56, -6}}, lineColor = {200, 0, 0}, fillColor = {200, 0, 0}, fillPattern = FillPattern.Solid)}));
    end GroundTrack;

    block IMU "Inertial measurement unit: specific force and angular rate in the vehicle frame, with lags"
      extends EquaForgeVC.Icons.Block;
      parameter Real T_accel(unit = "s") = 0.02 "Lag of the accelerometers";
      parameter Real T_gyro(unit = "s") = 0.01 "Lag of the gyros";
      Multibody.Interfaces.MotionInput vehicle "Motion of the frame the unit is on" annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}})));
      EquaForgeVC.Interfaces.RealInput g[3](each unit = "m/s2") "Gravity, world frame" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealOutput specificForce[3](each unit = "m/s2") "Measured specific force (acceleration less gravity), vehicle frame" annotation(Placement(transformation(origin = {110, 40}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput rate[3](each unit = "rad/s") "Measured angular rate, vehicle frame" annotation(Placement(transformation(origin = {110, -40}, extent = {{-10, -10}, {10, 10}})));
      Real loadFactor "Specific force in units of g0";
    protected
      Real R[3, 3];
      Real f_true[3](each unit = "m/s2");
    initial equation
      specificForce = f_true "the sensors start settled";
      rate = vehicle.w;
    equation
      R = Multibody.Frames.fromQ(vehicle.Q);
      f_true = R*(vehicle.a - g);
      for k in 1:3 loop
        T_accel*der(specificForce[k]) + specificForce[k] = f_true[k];
        T_gyro*der(rate[k]) + rate[k] = vehicle.w[k];
      end for;
      loadFactor = sqrt(specificForce*specificForce)/EquaForgeAerospace.g0;
      annotation(Documentation(info = "<html><p>What the accelerometers and gyros of a flight computer measure: the specific force (the acceleration less gravity, which no accelerometer feels) and the angular rate, both in the vehicle's axes, each through a first-order lag. The lag also keeps a controller that reads the acceleration from closing an algebraic loop with the forces it commands.</p><h4>Equations</h4><pre>T_a der(f) + f = R (a - g)\nT_g der(w_m) + w_m = w</pre></html>"),
        Icon(graphics = {
          Rectangle(extent = {{-50, 50}, {50, -50}}, lineColor = {64, 64, 64}, fillColor = {230, 230, 230}, fillPattern = FillPattern.Solid),
          Line(points = {{0, 0}, {40, 0}}, color = {200, 0, 0}, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{0, 0}, {0, 40}}, color = {0, 150, 0}, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{0, 0}, {-28, -28}}, color = {0, 0, 200}, arrow = {Arrow.None, Arrow.Filled})}));
    end IMU;

    block AttitudeError "Turn that brings the vehicle's axes onto a commanded direction and roll reference"
      extends EquaForgeVC.Icons.Block;
      Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle" annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}})));
      EquaForgeVC.Interfaces.RealInput direction[3] "Where the vehicle's x axis should point, world frame (any length)" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput rollReference[3] "Where its y axis (belly) should point as far as it can, world frame" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealOutput error[3](each unit = "rad") "Turn about the vehicle's axes that aligns it (small-angle rotation vector)" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
      Real angle(unit = "rad", displayUnit = "deg") "Angle between the x axis and the commanded direction";
    protected
      Real R[3, 3] "Vehicle";
      Real Rt[3, 3] "Target";
      Real xt[3], yt[3], zt[3];
      Real C[3, 3] "Target in vehicle coordinates";
      Real s "Sine of the pointing error";
      Real axis[2] "Axis of the pointing turn, about y and z";
    equation
      R = Multibody.Frames.fromQ(vehicle.Q);
      xt = direction/noEvent(max(sqrt(direction*direction), 1e-12));
      zt = cross(xt, rollReference)/noEvent(max(sqrt(cross(xt, rollReference)*cross(xt, rollReference)), 1e-12));
      yt = cross(zt, xt);
      Rt = {xt, yt, zt};
      C = R*transpose(Rt);
      // pointing: turn the x axis onto x_t (its vehicle coordinates are C[:, 1]) about x × x_t by the whole angle;
      // the small bias about z gives a turn axis even when the vehicle points exactly the other way
      s = sqrt(C[2, 1]^2 + C[3, 1]^2 + 1e-16);
      angle = atan2(s, C[1, 1]);
      axis = {-C[3, 1], C[2, 1] + 0.05*(1 - C[1, 1])};
      error[2:3] = angle/sqrt(axis*axis + 1e-16)*axis;
      // roll about x, faded out while the pointing error is large
      error[1] = atan2(C[3, 2] - C[2, 3], C[2, 2] + C[3, 3] + 2*(1 - C[1, 1]));
      annotation(Documentation(info = "<html><p>The pointing error of an attitude controller: the target attitude has its x axis along <b>direction</b> (a thrust or a nose direction) and its y axis as near <b>rollReference</b> as possible; the output is the rotation, about the vehicle's own axes, that would bring the vehicle onto it. It is exact for small errors and keeps its full size up to a turn of half a revolution, where a small bias about z picks the turn axis.</p><h4>Equations</h4><pre>x_t = d/|d|, z_t = x_t x r/|x_t x r|, y_t = z_t x x_t,  R_t = {x_t, y_t, z_t}\nC = R R_t',  theta = atan2(sqrt(C21^2 + C31^2), C11)\nerror_yz = theta a/|a|,  a = {-C31, C21 + 0.05 (1 - C11)}\nerror_x = atan2(C32 - C23, C22 + C33 + 2 (1 - C11))</pre><h4>How to use</h4><p>Feed the error to one controller per axis (<code>PID</code>) whose outputs are moments (gimbal, flaps, thrusters).</p></html>"),
        Icon(graphics = {
          Line(points = {{-60, -60}, {60, 20}}, color = {0, 0, 127}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{-60, -60}, {30, 60}}, color = {200, 0, 0}, pattern = LinePattern.Dash, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{30, -5}, {38, 18}, {20, 40}}, color = {64, 64, 64}, smooth = Smooth.Bezier, arrow = {Arrow.None, Arrow.Filled})}));
    end AttitudeError;

    block LocalDirection "A direction given by elevation and azimuth at the vehicle's place, in world coordinates"
      extends EquaForgeVC.Icons.Block;
      Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle (its position sets up, east and north)" annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}})));
      EquaForgeVC.Interfaces.RealInput elevation(unit = "rad", displayUnit = "deg") "Angle above the local horizontal" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput azimuth(unit = "rad", displayUnit = "deg") "From north towards east" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealOutput d[3] "Unit vector, world frame" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
      Real up[3], east[3], north[3];
    equation
      up = vehicle.r/sqrt(vehicle.r*vehicle.r);
      east = cross({0, 0, 1}, up)/noEvent(max(1e-9, sqrt(up[1]^2 + up[2]^2)));
      north = cross(up, east);
      d = sin(elevation)*up + cos(elevation)*(sin(azimuth)*east + cos(azimuth)*north);
      annotation(Documentation(info = "<html><p>Turns a pitch programme into a direction: <b>elevation</b> above the local horizon and <b>azimuth</b> from north towards east, at the place the vehicle is now. 90 deg elevation is straight up; 0 deg elevation at azimuth 90 deg is due east along the horizon.</p><h4>Equations</h4><pre>d = sin(el) up + cos(el) (sin(az) east + cos(az) north)</pre></html>"),
        Icon(graphics = {
          Line(points = {{-70, -50}, {70, -50}}, color = {120, 120, 120}),
          Line(points = {{-50, -50}, {40, 40}}, color = {0, 0, 127}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{0, -50}, {5, -30}, {-2, -12}}, color = {64, 64, 64}, smooth = Smooth.Bezier),
          Text(extent = {{-80, 90}, {80, 55}}, textString = "el, az")}));
    end LocalDirection;

    block VelocityDirection "Direction of the velocity relative to the turning Earth: prograde or retrograde"
      extends EquaForgeVC.Icons.Block;
      parameter Boolean retrograde = false "Against the velocity (a braking burn)" annotation(Evaluate = true);
      parameter Boolean inertial = false "The inertial velocity instead of the Earth-relative one (orbital burns)" annotation(Evaluate = true);
      parameter Real omega(unit = "rad/s") = EquaForgeAerospace.omegaEarth "Rotation of the Earth";
      Multibody.Interfaces.MotionInput vehicle annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      EquaForgeVC.Interfaces.RealOutput d[3] "Unit vector, world frame" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
    protected
      Real v[3](each unit = "m/s");
    equation
      v = if inertial then vehicle.v else vehicle.v - cross({0, 0, omega}, vehicle.r);
      d = (if retrograde then -1 else 1)*v/noEvent(max(sqrt(v*v), 1e-6));
      annotation(Documentation(info = "<html><p>Where the vehicle is going: the unit vector of its velocity relative to the turning Earth (or of its inertial velocity), or against it. A gravity turn flies along it; a braking or landing burn points the thrust against it; orbital burns use the inertial velocity.</p></html>"),
        Icon(graphics = {
          Line(points = {{-70, -40}, {-20, 0}, {30, 20}, {70, 25}}, color = {120, 120, 120}, smooth = Smooth.Bezier),
          Line(points = {{-20, 0}, {50, 35}}, color = {0, 0, 127}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled})}));
    end VelocityDirection;

    block EntryAttitude "Attitude for flight at an angle of attack and a bank angle: nose direction and belly reference"
      extends EquaForgeVC.Icons.Block;
      parameter Real omega(unit = "rad/s") = EquaForgeAerospace.omegaEarth "Rotation of the Earth (the air turns with it)";
      Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle" annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}})));
      EquaForgeVC.Interfaces.RealInput alpha(unit = "rad", displayUnit = "deg") "Angle of attack: the nose above the airspeed" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput bank(unit = "rad", displayUnit = "deg") "Bank: turn of the lift about the airspeed, from up" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealOutput direction[3] "Where the nose (x) should point, world frame" annotation(Placement(transformation(origin = {110, 40}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput rollReference[3] "Where the belly (y) should point, world frame" annotation(Placement(transformation(origin = {110, -40}, extent = {{-10, -10}, {10, 10}})));
    protected
      Real v[3](each unit = "m/s"), e_v[3], up[3], n[3], n_b[3];
    equation
      v = vehicle.v - cross({0, 0, omega}, vehicle.r);
      e_v = v/noEvent(max(sqrt(v*v), 1e-6));
      up = vehicle.r/sqrt(vehicle.r*vehicle.r);
      n = (up - (up*e_v)*e_v)/noEvent(max(sqrt((up - (up*e_v)*e_v)*(up - (up*e_v)*e_v)), 1e-9));
      n_b = cos(bank)*n + sin(bank)*cross(e_v, n);
      direction = cos(alpha)*e_v + sin(alpha)*n_b;
      rollReference = sin(alpha)*e_v - cos(alpha)*n_b;
      annotation(Documentation(info = "<html><p>Where a vehicle should point to fly at an angle of attack: its nose above the airspeed by <b>alpha</b>, in the plane that the <b>bank</b> angle turns about the airspeed (0: the lift points up). The belly faces the flow. A capsule or a winged vehicle in entry, a belly-flop at alpha = 90 deg.</p><h4>Equations</h4><pre>e_v: airspeed direction (Earth-relative),  n: up, square to e_v
n_b = cos(bank) n + sin(bank) e_v x n
nose = cos(alpha) e_v + sin(alpha) n_b,  belly = sin(alpha) e_v - cos(alpha) n_b</pre><h4>How to use</h4><p>Feed both outputs to an <code>AttitudeError</code>.</p></html>"),
        Icon(graphics = {
          Line(points = {{-70, -30}, {70, -30}}, color = {120, 120, 120}, arrow = {Arrow.None, Arrow.Filled}),
          Polygon(points = {{-50, -40}, {40, 30}, {55, 15}, {-35, -55}}, lineColor = {64, 64, 64}, fillColor = {220, 220, 220}, fillPattern = FillPattern.Solid),
          Line(points = {{-10, -30}, {0, -18}, {5, -5}}, color = {0, 0, 127}, smooth = Smooth.Bezier),
          Text(extent = {{-80, 90}, {80, 55}}, textString = "α, bank")}));
    end EntryAttitude;

    block ImpactPointPredictor "Where a vehicle on a ballistic arc would come down, and how far that is from a target"
      extends EquaForgeVC.Icons.Block;
      parameter Real mu(unit = "m3/s2") = EquaForgeAerospace.muEarth "Gravitational parameter";
      parameter Real Re(unit = "m") = EquaForgeAerospace.radiusEarth "Radius of the Earth";
      parameter Real omega(unit = "rad/s") = EquaForgeAerospace.omegaEarth "Rotation of the Earth";
      parameter Real theta0(unit = "rad") = 0 "Angle of longitude 0 at time 0";
      parameter Real latTarget(unit = "rad", displayUnit = "deg") = 0 "Target latitude";
      parameter Real lonTarget(unit = "rad", displayUnit = "deg") = 0 "Target longitude";
      Multibody.Interfaces.MotionInput vehicle annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      EquaForgeVC.Interfaces.RealOutput rangeToGo(unit = "m") "Ground distance of the impact point from the target, positive while it lies on the vehicle's side of the target" annotation(Placement(transformation(origin = {110, 40}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput timeToImpact(unit = "s") "Time of flight to the ground" annotation(Placement(transformation(origin = {110, -40}, extent = {{-10, -10}, {10, 10}})));
      Real latImpact(unit = "rad", displayUnit = "deg"), lonImpact(unit = "rad", displayUnit = "deg");
      Real crossRange(unit = "m") "Distance of the impact point across the line from the target to the vehicle";
    protected
      Real rn, vn, hn, energy, a, p, e, nu0, nuImp, E0, Eimp, M0, Mimp, n;
      Real h[3], ev[3], P[3], Qv[3], r_imp[3], r_kepler[3], r_imp_ecef[3], t_target[3], r_now_ecef[3], u_back[3], e_imp[3];
      Real c, tKepler;
      Boolean down "At or below the surface: the impact point is where the vehicle is";
    equation
      rn = sqrt(vehicle.r*vehicle.r);
      vn = sqrt(vehicle.v*vehicle.v);
      h = cross(vehicle.r, vehicle.v);
      hn = noEvent(max(sqrt(h*h), 1e-6));
      energy = vn^2/2 - mu/rn;
      a = -mu/(2*noEvent(min(energy, -1e-3)));
      p = hn^2/mu;
      ev = cross(vehicle.v, h)/mu - vehicle.r/rn;
      e = noEvent(max(sqrt(ev*ev), 1e-9));
      P = ev/e;
      Qv = cross(h, P)/hn;
      nu0 = atan2(vehicle.r*Qv, vehicle.r*P);
      // the impact is where r = Re on the way down: cos(nu) = (p/Re - 1)/e, the descending branch
      c = noEvent(max(-1, min(1, (p/Re - 1)/e)));
      nuImp = 2*EquaForgeVC.pi - acos(c);
      r_kepler = Re*(cos(nuImp)*P + sin(nuImp)*Qv);
      down = noEvent(rn <= Re + 1);
      r_imp = if down then Re*vehicle.r/rn else r_kepler;
      // time of flight from the eccentric anomalies (Kepler)
      E0 = 2*atan(sqrt(noEvent(max(1 - e, 1e-12)/(1 + e)))*tan(nu0/2));
      Eimp = 2*atan(sqrt(noEvent(max(1 - e, 1e-12)/(1 + e)))*tan(nuImp/2));
      n = sqrt(mu/a^3);
      M0 = E0 - e*sin(E0);
      Mimp = Eimp - e*sin(Eimp);
      tKepler = noEvent(mod(Mimp - M0, 2*EquaForgeVC.pi))/n;
      timeToImpact = if down then 0 else tKepler;
      r_imp_ecef = Multibody.Frames.planarRotation({0, 0, 1}, theta0 + omega*(time + timeToImpact))*r_imp;
      latImpact = asin(noEvent(max(-1, min(1, r_imp_ecef[3]/Re))));
      lonImpact = atan2(r_imp_ecef[2], r_imp_ecef[1]);
      t_target = Functions.sitePosition(latTarget, lonTarget, 0, Re)/Re;
      // the ground line from the target towards the vehicle (now), and the impact point on it
      r_now_ecef = Multibody.Frames.planarRotation({0, 0, 1}, theta0 + omega*time)*vehicle.r;
      u_back = (r_now_ecef - (r_now_ecef*t_target)*t_target)/noEvent(max(sqrt((r_now_ecef - (r_now_ecef*t_target)*t_target)*(r_now_ecef - (r_now_ecef*t_target)*t_target)), 1e-6));
      e_imp = r_imp_ecef/Re;
      rangeToGo = Re*atan2(e_imp*u_back, e_imp*t_target);
      crossRange = Re*asin(noEvent(max(-1, min(1, e_imp*cross(t_target, u_back)))));
      annotation(Documentation(info = "<html><p>The instantaneous impact point: where a vehicle coasting from here, in vacuum on its Kepler arc, would meet the Earth's surface, carried round by the Earth's rotation during the fall, and where that is from a target: along the ground line from the target towards the vehicle (<b>rangeToGo</b>, positive on the vehicle's side, whichever way it flies) and across it. A booster's boostback burn runs until the impact point has come back to its landing site (range to go 0 or a little past it, as drag will shorten the fall).</p><h4>Equations</h4><pre>conic from r, v: p = h^2/mu, e, perifocal axes P, Q\nimpact: r(nu) = p/(1 + e cos nu) = Re on the descending branch\ntime of flight from Kepler's equation, impact point turned by omega t_f into Earth-fixed axes
rangeToGo = Re atan2(e_imp . u, e_imp . e_target),  u: from the target towards the vehicle</pre><h4>Assumptions</h4><p>No drag, a spherical Earth; the arc must come down (a sub-orbital trajectory).</p></html>"),
        Icon(graphics = {
          Line(points = {{-80, -60}, {-40, 30}, {10, 50}, {50, 10}, {70, -60}}, color = {0, 0, 127}, thickness = 0.5, smooth = Smooth.Bezier),
          Line(points = {{-90, -60}, {90, -60}}, color = {120, 120, 120}),
          Line(points = {{60, -40}, {75, -70}}, color = {200, 0, 0}, thickness = 0.5),
          Line(points = {{60, -70}, {75, -40}}, color = {200, 0, 0}, thickness = 0.5)}));
    end ImpactPointPredictor;

    block PoweredDescent "Landing burn: when to light the engines and how hard to brake for a soft touchdown"
      extends EquaForgeVC.Icons.Block;
      parameter Real h_target(unit = "m") = 0 "Height at which the vehicle should stop";
      parameter Real v_touch(unit = "m/s") = 1 "Sink rate at the target height";
      parameter Real margin = 0.8 "Share of the full thrust the burn plans to use (the rest is margin)";
      parameter Real k_v(unit = "1/s") = 1 "Gain of the sink rate tracking";
      parameter Boolean timeToGo = true "Lateral guidance that nulls offset and drift at touchdown (false: the k_p, k_d law)" annotation(Evaluate = true);
      parameter Real k_p(unit = "1/s2") = 0.01 "Lateral guidance: acceleration per metre of offset from the target";
      parameter Real k_d(unit = "1/s") = 0.2 "Lateral guidance: acceleration per m/s of sideways speed (keep the attitude loop's gimbal gain times thrust/weight below 1)";
      parameter Real tiltMax(unit = "rad", displayUnit = "deg") = 0.25 "Largest tilt of the thrust from the vertical";
      parameter Real h_upright(unit = "m") = 100 "Below this height the allowed tilt shrinks to zero at the target: a vertical touchdown";
      parameter Real v_lateralMax(unit = "m/s") = EquaForgeVC.inf "k_p, k_d law: fastest sideways speed it asks for (a far offset is closed at this speed, not by a lunge)";
      parameter Real h_hold(unit = "m") = 0"Below this height the lateral guidance fades out the offset and only stops the drift: a tall vehicle touches down without sideways speed wherever it is (0: never)";
      parameter Real t_goMin(unit = "s") = 2"Shortest time to go of the lateral guidance: its bandwidth, about sqrt(6)/t_go, must stay well below the attitude loop's";
      parameter Boolean usePlanInput = false "Plan the braking with the deceleration aPlan (what the engines that finish the landing can give) instead of margin aMax - g" annotation(Evaluate = true);
      Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle" annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}})));
      Multibody.Interfaces.MotionInput target "Motion of the landing point (a LaunchSite)" annotation(Placement(transformation(origin = {0, -110}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
      EquaForgeVC.Interfaces.RealInput h(unit = "m") "Height above the landing site" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
      EquaForgeVC.Interfaces.RealInput aMax(unit = "m/s2") "Acceleration of full thrust now (thrust / mass)" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
      EquaForgeVC.Interfaces.RealInput aPlan(unit = "m/s2") if usePlanInput "Deceleration the braking plans with (net of gravity)" annotation(Placement(transformation(origin = {-60, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
      EquaForgeVC.Interfaces.BooleanOutput ignite "The planned burn would just stop the vehicle at the target: light the engines" annotation(Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput throttle "Thrust command (share of full thrust)" annotation(Placement(transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput v_ref(unit = "m/s") "Planned sink rate at this height" annotation(Placement(transformation(origin = {110, -40}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Interfaces.RealOutput direction[3] "Thrust direction that steers over the target, world frame" annotation(Placement(transformation(origin = {110, -80}, extent = {{-10, -10}, {10, 10}})));
      Real sinkRate(unit = "m/s") "Downward speed relative to the ground";
      Real offset(unit = "m") "Horizontal distance from the target";
      Real stoppingHeight(unit = "m") "Height needed to stop at the planned deceleration";
    protected
      constant Real g = EquaForgeAerospace.g0;
      Real up[3];
      Real aNet(unit = "m/s2") "Planned deceleration";
      Real dr[3], dv[3] "Position and velocity relative to the target, world frame";
      Real a_h[3] "Commanded sideways acceleration";
      Real a_hn "Its size";
      Real cosTilt "Cosine of the vehicle's tilt from the vertical";
      Real tiltAllowed(unit = "rad") "Tilt the lateral guidance may use now";
      Real t_go(unit = "s") "Time to touchdown, from the vertical plan";
      Real holdShare "Weight of the offset in the lateral guidance: 1 high up, fading to 0 below h_hold";
      Real v_cmd_raw[3](each unit = "m/s"), v_cmd[3](each unit = "m/s") "Sideways speed the k_p, k_d law asks for, before and after its limit";
      Real a_thrust(unit = "m/s2") "Thrust acceleration the tilt acts with";
      EquaForgeVC.Interfaces.RealInput aPlanned(unit = "m/s2") "The planned deceleration";
    equation
      connect(aPlan, aPlanned);
      if not usePlanInput then
        aPlanned = margin*aMax - g;
      end if;
      up = vehicle.r/sqrt(vehicle.r*vehicle.r);
      dr = vehicle.r - target.r;
      dv = vehicle.v - target.v;
      t_go = noEvent(max(2*max(h - h_target, 0)/max(sinkRate + v_touch, 1), t_goMin));
      holdShare = if h_hold > 0 then noEvent(min(1, max(h - h_target, 0)/h_hold)) else 1;
      // k_p, k_d law as a speed command from the offset, no faster than v_lateralMax, and its tracking
      v_cmd_raw = -k_p/max(k_d, 1e-9)*holdShare*(dr - (dr*up)*up);
      v_cmd = v_cmd_raw*noEvent(min(1, v_lateralMax/max(sqrt(v_cmd_raw*v_cmd_raw), 1e-9)));
      a_h = if timeToGo then -6*holdShare*(dr - (dr*up)*up)/t_go^2 - 4*(dv - (dv*up)*up)/t_go else -k_d*((dv - (dv*up)*up) - v_cmd);
      a_thrust = noEvent(max(margin*aMax, g));
      a_hn = sqrt(a_h*a_h);
      offset = sqrt((dr - (dr*up)*up)*(dr - (dr*up)*up));
      tiltAllowed = tiltMax*noEvent(min(1, max(h - h_target, 0)/h_upright));
      direction = up + a_h/a_thrust*noEvent(min(1, tan(tiltAllowed)*a_thrust/max(a_hn, 1e-9)));
      // the vehicle's x axis (its thrust) against the vertical
      cosTilt = 2*(vehicle.Q[1]^2 + vehicle.Q[4]^2 - 0.5)*up[1] + 2*(vehicle.Q[1]*vehicle.Q[2] + vehicle.Q[3]*vehicle.Q[4])*up[2] + 2*(vehicle.Q[1]*vehicle.Q[3] - vehicle.Q[2]*vehicle.Q[4])*up[3];
      sinkRate = -(vehicle.v - cross({0, 0, EquaForgeAerospace.omegaEarth}, vehicle.r))*up;
      aNet = noEvent(max(aPlanned, 0.5));
      stoppingHeight = noEvent(max(sinkRate, 0))^2/(2*aNet);
      // at least 0.1 m to go: at rest at the target the relation stays quiet instead of flickering on noise
      ignite = stoppingHeight >= noEvent(max(h - h_target, 0.1));
      v_ref = sqrt(v_touch^2 + 2*aNet*noEvent(max(h - h_target, 0)));
      throttle = noEvent(min(max((g + aNet + k_v*(sinkRate - v_ref))/(noEvent(max(aMax, 0.1))*noEvent(max(cosTilt, 0.5))), 0), 1));
      annotation(Documentation(info = "<html><p>The guidance of a propulsive landing (a hover-slam): the burn starts when the height that braking at a planned share of full thrust needs equals the height left, and the throttle then tracks the sink rate that would bring the vehicle to <b>v_touch</b> exactly at the target height. The margin left in the thrust absorbs errors of drag, mass and timing.</p><h4>Equations</h4><pre>a = margin aMax - g\nignite when v^2/(2 a) &gt;= h - h_target\nv_ref(h) = sqrt(v_touch^2 + 2 a (h - h_target))\nthrottle = (g + a + k_v (v - v_ref)) / (aMax cos(tilt))
a_side = -6 s dr_h / t_go^2 - 4 dv_h / t_go,  t_go = max(2 (h - h_target) / (v + v_touch), t_goMin)
   (or -k_d (dv_h - v_cmd),  v_cmd = -(k_p/k_d) s dr_h, its size at most v_lateralMax)
s = min(1, (h - h_target) / h_hold)   (1 when h_hold = 0)
direction = up + a_side / (margin aMax),  its tilt at most the tilt allowed
tilt allowed = tiltMax min(1, (h - h_target) / h_upright)</pre><p>The <b>direction</b> output tilts the thrust to null the horizontal offset and speed relative to the <b>target</b> (the pad's motion, which turns with the Earth); feed it to an <code>AttitudeError</code>.</p><p>With <b>usePlanInput</b> the planned deceleration <i>a</i> comes from the <b>aPlan</b> input instead: a vehicle that brakes on several engines and lands on fewer plans with what the last engines can give, while the throttle still divides by the full thrust of the engines running now.</p></html>"),
        Icon(graphics = {
          Line(points = {{-70, 80}, {-50, 20}, {-20, -30}, {0, -50}}, color = {0, 0, 127}, thickness = 0.5, smooth = Smooth.Bezier),
          Rectangle(extent = {{-10, -40}, {10, -70}}, lineColor = {64, 64, 64}, fillColor = {230, 230, 230}, fillPattern = FillPattern.Solid),
          Polygon(points = {{-8, -70}, {8, -70}, {0, -90}}, lineColor = {230, 120, 0}, fillColor = {255, 190, 60}, fillPattern = FillPattern.Solid),
          Line(points = {{-80, -90}, {80, -90}}, color = {120, 120, 120})}));
    end PoweredDescent;
    annotation(Documentation(info = "<html><p>The flight computer's view: where the vehicle is and which orbit it is on (<code>OrbitalElements</code>, <code>GroundTrack</code>), what its sensors measure (<code>IMU</code>), where it should point (<code>LocalDirection</code>, <code>VelocityDirection</code>, <code>EntryAttitude</code>, <code>AttitudeError</code>), where it would come down (<code>ImpactPointPredictor</code>) and how it lands (<code>PoweredDescent</code>).</p></html>"));
  end GNC;

  package Thermal "Heat of flight through the atmosphere"
    block StagnationHeating "Convective heat flux at the stagnation point of a blunt body (Sutton and Graves)"
      extends EquaForgeVC.Icons.Block;
      parameter Real noseRadius(unit = "m") = 4.5 "Effective nose radius";
      parameter Real k(unit = "kg^0.5/m") = 1.7415e-4 "Sutton-Graves constant of air";
      parameter Real area(unit = "m2") = 100 "Area the flux heats";
      parameter Real shapeFactor = 0.4 "Mean flux over the area / stagnation-point flux";
      EquaForgeVC.Interfaces.RealInput rho(unit = "kg/m3") "Air density" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
      EquaForgeVC.Interfaces.RealInput V(unit = "m/s") "Airspeed" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
      EquaForgeVC.Interfaces.RealOutput Q_flow(unit = "W") "Heat flow into the area" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
      Real q(unit = "W/m2") "Heat flux at the stagnation point";
    equation
      q = k*sqrt(noEvent(max(rho, 0))/noseRadius)*abs(V)^3;
      Q_flow = q*area*shapeFactor;
      annotation(Documentation(info = "<html><p>How hot entry gets: the convective heat flux into a blunt nose grows with the square root of the density and the cube of the speed (Sutton and Graves), which puts the peak heating high up, where the vehicle is still fast. The heat flow into a heat shield follows with its area and a factor for the mean flux over it.</p><h4>Equations</h4><pre>q = k sqrt(rho / R_n) V^3,   k = 1.7415e-4 kg^0.5/m (air)\nQ = q area shapeFactor</pre><h4>How to use</h4><p>Drive a <code>Thermal.PrescribedHeatFlow</code> into the heat shield's <code>HeatCapacitor</code>; let it radiate with <code>BodyRadiation</code> to space and conduct inwards with a <code>ThermalConductor</code>.</p><h4>References</h4><p>K. Sutton, R. A. Graves, A General Stagnation-Point Convective-Heating Equation for Arbitrary Gas Mixtures, NASA TR R-376, 1971.</p></html>"),
        Icon(graphics = {
          Ellipse(extent = {{-20, 60}, {100, -60}}, lineColor = {64, 64, 64}, fillColor = {230, 230, 230}, fillPattern = FillPattern.Solid),
          Line(points = {{-90, 40}, {-25, 20}}, color = {230, 80, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{-90, 0}, {-25, 0}}, color = {230, 80, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
          Line(points = {{-90, -40}, {-25, -20}}, color = {230, 80, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
          Text(extent = {{-150, -70}, {150, -100}}, textString = "Rn=%noseRadius")}));
    end StagnationHeating;
    annotation(Documentation(info = "<html><p>Aerodynamic heating of a vehicle entering the atmosphere; the heat it brings goes into the lumped models of <code>EquaForgeVC.Thermal</code>.</p></html>"));
  end Thermal;

  package Examples "Demonstrations of the aerospace blocks"
    model OrbitPropagation "A satellite on a free body under the Earth's gravity with J2: orbit, node regression and ground track"
      parameter Real h0(unit = "m") = 400e3 "Altitude of the circular orbit";
      parameter Real inc(unit = "rad", displayUnit = "deg") = 0.9006 "Inclination (51.6 deg)";
      final parameter Real r0(unit = "m") = EquaForgeAerospace.radiusEarth + h0;
      final parameter Real vc(unit = "m/s") = sqrt(EquaForgeAerospace.muEarth/r0) "Circular speed";
      Environment.RotatingEarth earth annotation(Placement(transformation(origin = {-70, 40}, extent = {{-10, -10}, {10, 10}})));
      Multibody.Visualization.AttachedShape globe(shapeType = EquaForgeVC.Visualization.ShapeType.Sphere, length = 2*EquaForgeAerospace.radiusEarth, color = {60, 120, 210}, opacity = 0.9) annotation(Placement(transformation(origin = {-35, 40}, extent = {{-10, -10}, {10, 10}})));
      Multibody.BodiesAndFrames.FreeBody satellite(r_start = {r0, 0, 0}, v_start = {0, vc*cos(inc), vc*sin(inc)}, w_start = {0, 0, 0.001}, r_nominal = 7e6, v_nominal = 8e3) annotation(Placement(transformation(origin = {10, -10}, extent = {{-10, -10}, {10, 10}})));
      Multibody.BodiesAndFrames.MassProperties props(m = 1000, I_11 = 300, I_22 = 400, I_33 = 500) annotation(Placement(transformation(origin = {-30, -40}, extent = {{-10, -10}, {10, 10}})));
      Environment.CentralGravity gravity annotation(Placement(transformation(origin = {-30, 10}, extent = {{-10, -10}, {10, 10}})));
      GNC.OrbitalElements elements annotation(Placement(transformation(origin = {60, 20}, extent = {{-10, -10}, {10, 10}})));
      GNC.GroundTrack track annotation(Placement(transformation(origin = {60, -30}, extent = {{-10, -10}, {10, 10}})));
      Multibody.Visualization.AttachedShape marker(shapeType = EquaForgeVC.Visualization.ShapeType.Sphere, length = 2e5, color = {230, 120, 30}, trail = 5600) annotation(Placement(transformation(origin = {-70, -10}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(earth.frame_b, globe.frame_a) annotation(Line(points = {{-60, 40}, {-45, 40}}, color = {95, 95, 95}, thickness = 0.5));
      connect(satellite.frame_a, gravity.frame_a) annotation(Line(points = {{0, -10}, {-46, -10}, {-46, 10}, {-40, 10}}, color = {95, 95, 95}, thickness = 0.5));
      connect(gravity.g, satellite.g) annotation(Line(points = {{-19, 10}, {10, 10}, {10, 2}}, color = {0, 0, 127}));
      connect(props.y, satellite.mass) annotation(Line(points = {{-19, -40}, {10, -40}, {10, -21}}, color = {120, 60, 0}));
      connect(satellite.motion, elements.vehicle) annotation(Line(points = {{21, -10}, {36, -10}, {36, 20}, {50, 20}}, color = {95, 95, 95}));
      connect(satellite.motion, track.vehicle) annotation(Line(points = {{21, -10}, {36, -10}, {36, -30}, {50, -30}}, color = {95, 95, 95}));
      connect(satellite.frame_a, marker.frame_a) annotation(Line(points = {{0, -10}, {-80, -10}}, color = {95, 95, 95}));
      annotation(experiment(StopTime = 16700, Interval = 10, Tolerance = 1e-10), __EquaForge(category = "Aerospace", plots = {
          Plot(name = "Altitude, apoapsis and periapsis", curves = {"track.altitude", "elements.apoapsis", "elements.periapsis"}),
          Plot(name = "Node and inclination", curves = {"elements.raan", "elements.inclination"}),
          Plot(name = "Ground track", curves = {"track.latitude", "track.longitude"}),
          Plot(name = "Orbital energy", curves = {"elements.energy"})}, plotArrangement = "Grid", linkTime = true),
        Diagram(coordinateSystem(extent = {{-100, -60}, {100, 100}}), graphics = {Text(extent = {{-95, 98}, {95, 60}}, textString = "## Orbit with J2\nA 1 t satellite in a 400 km circular orbit at 51.6 deg flies three orbits on a free body; the Earth's flattening (J2) turns its plane westward by about 5 deg a day and makes the altitude wobble.\n- Plot the node, the altitude and the ground track; open the 3-D view.\n- Try: J2 = 0 (gravity) for a fixed plane, another inclination or altitude.", fontSize = 9, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
        Documentation(info = "<html><p>A satellite on a <code>Multibody.BodiesAndFrames.FreeBody</code> under <code>Environment.CentralGravity</code> with the J2 term. Its node moves at dOmega/dt = -1.5 n J2 (Re/p)^2 cos i, about -5 deg per day at 400 km and 51.6 deg; the ground track moves west by the Earth's turn and the regression on each orbit.</p></html>"));
    end OrbitPropagation;

    model StaticFire "An engine on a test stand: tanks, pressurisation, turbopump, chamber and thrust through a throttle programme"
      Propulsion.RocketEngine engine(F_vac = 2.65e6, Isp_vac = 350, A_e = 1.5) annotation(Placement(transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}})));
      Propulsion.PropellantTank lox(rho_l = 1141, radius = 2, length = 12, m_start = 1.6e5, p_start = 3e5, R_gas = 259.8, T_sat = 90, h_fg = 2.13e5) annotation(Placement(transformation(origin = {-40, 30}, extent = {{-10, -10}, {10, 10}})));
      Propulsion.PropellantTank ch4(rho_l = 422, radius = 2, length = 9, m_start = 4.5e4, p_start = 3e5, R_gas = 518.3, T_sat = 112, h_fg = 5.1e5) annotation(Placement(transformation(origin = {-40, -40}, extent = {{-10, -10}, {10, 10}})));
      Blocks.StepSequence program(times = {0, 6, 12, 18}, values = {1, 0.6, 1, 0.7}) "Throttle programme" annotation(Placement(transformation(origin = {-80, 10}, extent = {{-10, -10}, {10, 10}})));
      Blocks.BooleanStep ignition(startTime = 1) annotation(Placement(transformation(origin = {-80, -10}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Constant seaLevel(k = 101325) annotation(Placement(transformation(origin = {-10, -40}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Constant gravityAxial(k = 9.81) "The stand holds the tanks upright" annotation(Placement(transformation(origin = {-80, 60}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Constant pTarget(k = 3e5) "Ullage pressure set-point" annotation(Placement(transformation(origin = {-80, -70}, extent = {{-10, -10}, {10, 10}})));
      Blocks.PI loxPress(k = 2e-5, Ti = 2, yMax = 20, yMin = 0) "Pressurant flow of the oxygen tank" annotation(Placement(transformation(origin = {-75, 35}, extent = {{-5, -5}, {5, 5}})));
      Blocks.PI ch4Press(k = 2e-5, Ti = 2, yMax = 10, yMin = 0) "Pressurant flow of the methane tank" annotation(Placement(transformation(origin = {-75, -45}, extent = {{-5, -5}, {5, 5}})));
      EquaForgeVC.Thermal.FixedTemperature air(T = 300) annotation(Placement(transformation(origin = {-10, 70}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Thermal.Convection wallLeak(hA = 2e3) "Heat leak through the tank's insulation" annotation(Placement(transformation(origin = {-40, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
      EquaForgeVC.Thermal.HeatCapacitor wall(C = 5e6, T_start = 95) annotation(Placement(transformation(origin = {-60, 85}, extent = {{-6, -6}, {6, 6}})));
      EquaForgeVC.Thermal.ThermalConductor wetted(G = 5e4) annotation(Placement(transformation(origin = {-40, 50}, extent = {{-6, -6}, {6, 6}}, rotation = 270)));
    equation
      connect(program.y, engine.throttle) annotation(Line(points = {{-69, 10}, {-20, 10}, {-20, 6}, {8, 6}}, color = {0, 0, 127}));
      connect(ignition.y, engine.on) annotation(Line(points = {{-69, -10}, {-20, -10}, {-20, 0}, {8, 0}}, color = {255, 0, 255}));
      connect(seaLevel.y, engine.p_amb) annotation(Line(points = {{1, -40}, {4, -40}, {4, -6}, {8, -6}}, color = {0, 0, 127}));
      connect(engine.mdot_ox, lox.mdot_out) annotation(Line(points = {{31, -2}, {40, -2}, {40, 50}, {-56, 50}, {-56, 36}, {-52, 36}}, color = {0, 0, 127}));
      connect(engine.mdot_fuel, ch4.mdot_out) annotation(Line(points = {{31, -6}, {44, -6}, {44, -60}, {-56, -60}, {-56, -34}, {-52, -34}}, color = {0, 0, 127}));
      connect(gravityAxial.y, lox.a_axial) annotation(Line(points = {{-69, 60}, {-60, 60}, {-60, 24}, {-52, 24}}, color = {0, 0, 127}));
      connect(gravityAxial.y, ch4.a_axial) annotation(Line(points = {{-69, 60}, {-60, 60}, {-60, -46}, {-52, -46}}, color = {0, 0, 127}));
      connect(pTarget.y, loxPress.u_s) annotation(Line(points = {{-69, -70}, {-90, -70}, {-90, 35}, {-81, 35}}, color = {0, 0, 127}));
      connect(pTarget.y, ch4Press.u_s) annotation(Line(points = {{-69, -70}, {-90, -70}, {-90, -45}, {-81, -45}}, color = {0, 0, 127}));
      connect(lox.p, loxPress.u_m) annotation(Line(points = {{-29, 36}, {-24, 36}, {-24, 20}, {-75, 20}, {-75, 29}}, color = {0, 0, 127}));
      connect(ch4.p, ch4Press.u_m) annotation(Line(points = {{-29, -34}, {-24, -34}, {-24, -52}, {-75, -52}, {-75, -51}}, color = {0, 0, 127}));
      connect(loxPress.y, lox.mdot_press) annotation(Line(points = {{-69.5, 35}, {-62, 35}, {-62, 30}, {-52, 30}}, color = {0, 0, 127}));
      connect(ch4Press.y, ch4.mdot_press) annotation(Line(points = {{-69.5, -45}, {-62, -45}, {-62, -40}, {-52, -40}}, color = {0, 0, 127}));
      connect(air.port, wallLeak.fluid) annotation(Line(points = {{0, 70}, {-30, 70}}, color = {191, 0, 0}));
      connect(wallLeak.solid, wall.port) annotation(Line(points = {{-50, 70}, {-60, 70}, {-60, 79}}, color = {191, 0, 0}));
      connect(wall.port, wetted.port_a) annotation(Line(points = {{-60, 79}, {-60, 56}, {-40, 56}}, color = {191, 0, 0}));
      connect(wetted.port_b, lox.heatPort) annotation(Line(points = {{-40, 44}, {-40, 40}}, color = {191, 0, 0}));
      annotation(experiment(StopTime = 25, Interval = 0.01, Tolerance = 1e-6, __EquaForge_Algorithm = "bdf"), __EquaForge(category = "Aerospace", plots = {
          Plot(name = "Thrust", curves = {"engine.F"}),
          Plot(name = "Chamber pressure and turbopump speed", curves = {"engine.pc", "engine.speed.w"}),
          Plot(name = "Tank pressures", curves = {"lox.p", "ch4.p"}),
          Plot(name = "Propellant left", curves = {"lox.m", "ch4.m"}),
          Plot(name = "Specific impulse", curves = {"engine.Isp"}),
          Plot(name = "Boil-off", curves = {"lox.mdot_boil"})}, plotArrangement = "Grid", linkTime = true),
        Diagram(coordinateSystem(extent = {{-100, -80}, {100, 140}}), graphics = {Text(extent = {{-95, 138}, {95, 100}}, textString = "## Static fire\nA 2.65 MN methane-oxygen engine on a test stand runs a throttle programme from its tanks: the turbopump spins up, the chamber pressure follows, and two PI controllers keep the ullage pressures at 3 bar by feeding pressurant gas.\n- Plot thrust, chamber pressure and the tank pressures.\n- Try: a faster programme, the heat leak hA, another set-point.", fontSize = 9, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
        Documentation(info = "<html><p>A <code>Propulsion.RocketEngine</code> at sea level fed by two <code>Propulsion.PropellantTank</code>s. At sea level the delivered specific impulse is (F_vac - p_a A_e)/(mdot g0), about 330 s for this nozzle against 350 s in vacuum; the tanks lose (1 + MR) times the fuel flow in all.</p></html>"));
    end StaticFire;

    model EntryHeating "A capsule enters the atmosphere: deceleration, stagnation heating and the heat shield's temperature"
      parameter Real h0(unit = "m") = 120e3 "Entry interface altitude";
      parameter Real V0(unit = "m/s") = 7500 "Entry speed";
      parameter Real gamma0(unit = "rad", displayUnit = "deg") = -0.035 "Flight path angle at entry (-2 deg)";
      final parameter Real r0(unit = "m") = EquaForgeAerospace.radiusEarth + h0;
      Multibody.BodiesAndFrames.FreeBody capsule(r_start = {r0, 0, 0}, v_start = {V0*sin(gamma0), V0*cos(gamma0), 0}, Q_start = Multibody.Frames.planarQ({0, 0, 1}, EquaForgeVC.pi/2 - gamma0), r_nominal = 7e6, v_nominal = 8e3) annotation(Placement(transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}})));
      Multibody.BodiesAndFrames.MassProperties props(m = 5000, I_11 = 6000, I_22 = 5000, I_33 = 5000) annotation(Placement(transformation(origin = {-40, -40}, extent = {{-10, -10}, {10, 10}})));
      Environment.CentralGravity gravity annotation(Placement(transformation(origin = {-40, 20}, extent = {{-10, -10}, {10, 10}})));
      Environment.AtmosphereUS76 atmosphere annotation(Placement(transformation(origin = {80, 40}, extent = {{-10, -10}, {10, 10}})));
      Environment.AirData airData annotation(Placement(transformation(origin = {40, 20}, extent = {{-10, -10}, {10, 10}})));
      Aerodynamics.BodyAero aero(S = 12.6, Mach_table = {0, 0.8, 1.2, 3, 25}, CA_table = {1.0, 1.1, 1.4, 1.5, 1.5}, CN_alpha = 0.3, CD_cross = 1.0, planformRatio = 1, x_cp_nose = -1.0, x_cp_tail = 1.0, x_cp_broadside = -0.2) "Blunt capsule: centre of pressure behind the centre of mass (stable heat shield first)" annotation(Placement(transformation(origin = {-40, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
      Thermal.StagnationHeating heating(noseRadius = 4.7, area = 12.6, shapeFactor = 0.6) annotation(Placement(transformation(origin = {80, -10}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Thermal.PrescribedHeatFlow heatIn annotation(Placement(transformation(origin = {80, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      EquaForgeVC.Thermal.HeatCapacitor shield(C = 6e5, T_start = 250) "Heat shield: 600 kg of ablator-free tiles" annotation(Placement(transformation(origin = {60, -70}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Thermal.BodyRadiation radiation(Gr = 0.85*12.6) annotation(Placement(transformation(origin = {30, -60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Thermal.FixedTemperature space(T = 250) "Cold sky and air" annotation(Placement(transformation(origin = {0, -60}, extent = {{-10, -10}, {10, 10}})));
      EquaForgeVC.Thermal.ThermalConductor insulation(G = 30) annotation(Placement(transformation(origin = {90, -75}, extent = {{-6, -6}, {6, 6}})));
      EquaForgeVC.Thermal.HeatCapacitor structure(C = 3e6, T_start = 280) annotation(Placement(transformation(origin = {110, -70}, extent = {{-6, -6}, {6, 6}})));
      EquaForgeVC.Thermal.TemperatureSensor shieldT annotation(Placement(transformation(origin = {30, -90}, extent = {{-10, -10}, {10, 10}})));
      Visualization.TemperatureColor glow(Tcold = 400, Thot = 1900) annotation(Placement(transformation(origin = {0, -90}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
      Multibody.Visualization.AttachedShape body(shapeType = EquaForgeVC.Visualization.ShapeType.Cone, length = 3.5, width = 5, position = {-1.75, 0, 0}, lengthDirection = {-1, 0, 0}, trail = 400, useColorInput = true) "Heat shield forward" annotation(Placement(transformation(origin = {-40, -70}, extent = {{-10, -10}, {10, 10}})));
      GNC.IMU imu annotation(Placement(transformation(origin = {40, 60}, extent = {{-10, -10}, {10, 10}})));
    equation
      connect(props.y, capsule.mass) annotation(Line(points = {{-29, -40}, {0, -40}, {0, -11}}, color = {120, 60, 0}));
      connect(capsule.frame_a, gravity.frame_a) annotation(Line(points = {{-10, 0}, {-56, 0}, {-56, 20}, {-50, 20}}, color = {95, 95, 95}, thickness = 0.5));
      connect(gravity.g, capsule.g) annotation(Line(points = {{-29, 20}, {0, 20}, {0, 12}}, color = {0, 0, 127}));
      connect(capsule.frame_a, aero.frame_b) annotation(Line(points = {{-10, 0}, {-20, 0}, {-20, -10}, {-30, -10}}, color = {95, 95, 95}, thickness = 0.5));
      connect(capsule.motion, airData.vehicle) annotation(Line(points = {{11, 0}, {24, 0}, {24, 26}, {30, 26}}, color = {95, 95, 95}));
      airData.wind = {0, 0} "no wind";
      connect(airData.h, atmosphere.h) annotation(Line(points = {{51, 28}, {60, 28}, {60, 40}, {68, 40}}, color = {0, 0, 127}));
      connect(atmosphere.rho, airData.rho) annotation(Line(points = {{91, 46}, {96, 46}, {96, 6}, {22, 6}, {22, 16}, {28, 16}}, color = {0, 0, 127}));
      connect(atmosphere.a, airData.a) annotation(Line(points = {{91, 34}, {94, 34}, {94, 8}, {24, 8}, {24, 12}, {28, 12}}, color = {0, 0, 127}));
      connect(airData.v_air, aero.v_air) annotation(Line(points = {{51, 24}, {56, 24}, {56, -24}, {-60, -24}, {-60, -14}, {-52, -14}}, color = {0, 0, 127}));
      connect(airData.qbar, aero.qbar) annotation(Line(points = {{51, 12}, {54, 12}, {54, -22}, {-58, -22}, {-58, -10}, {-52, -10}}, color = {0, 0, 127}));
      connect(airData.Mach, aero.Mach) annotation(Line(points = {{51, 16}, {58, 16}, {58, -26}, {-62, -26}, {-62, -6}, {-52, -6}}, color = {0, 0, 127}));
      connect(atmosphere.rho, heating.rho) annotation(Line(points = {{91, 46}, {98, 46}, {98, 4}, {64, 4}, {64, -6}, {68, -6}}, color = {0, 0, 127}));
      connect(airData.V, heating.V) annotation(Line(points = {{51, 20}, {62, 20}, {62, -14}, {68, -14}}, color = {0, 0, 127}));
      connect(heating.Q_flow, heatIn.Q_flow) annotation(Line(points = {{91, -10}, {96, -10}, {96, -28}, {80, -28}}, color = {0, 0, 127}));
      connect(heatIn.port, shield.port) annotation(Line(points = {{80, -50}, {80, -80}, {60, -80}}, color = {191, 0, 0}));
      connect(shield.port, radiation.port_b) annotation(Line(points = {{60, -80}, {44, -80}, {44, -60}, {40, -60}}, color = {191, 0, 0}));
      connect(radiation.port_a, space.port) annotation(Line(points = {{20, -60}, {10, -60}}, color = {191, 0, 0}));
      connect(shield.port, insulation.port_a) annotation(Line(points = {{60, -80}, {84, -80}, {84, -75}}, color = {191, 0, 0}));
      connect(insulation.port_b, structure.port) annotation(Line(points = {{96, -75}, {110, -75}, {110, -76}}, color = {191, 0, 0}));
      connect(shield.port, shieldT.port) annotation(Line(points = {{60, -80}, {60, -90}, {40, -90}}, color = {191, 0, 0}));
      connect(shieldT.T, glow.T) annotation(Line(points = {{19, -90}, {12, -90}}, color = {0, 0, 127}));
      connect(glow.rgb, body.colorIn) annotation(Line(points = {{-11, -90}, {-20, -90}, {-20, -50}, {-40, -50}, {-40, -58}}, color = {0, 0, 127}));
      connect(capsule.frame_a, body.frame_a) annotation(Line(points = {{-10, 0}, {-18, 0}, {-18, -70}, {-50, -70}}, color = {95, 95, 95}));
      connect(capsule.motion, imu.vehicle) annotation(Line(points = {{11, 0}, {22, 0}, {22, 66}, {30, 66}}, color = {95, 95, 95}));
      connect(gravity.g, imu.g) annotation(Line(points = {{-29, 20}, {-20, 20}, {-20, 54}, {28, 54}}, color = {0, 0, 127}));
      when airData.h < 5000 then
        terminate("below 5 km: the parachutes take over");
      end when;
      annotation(experiment(StopTime = 900, Interval = 0.5, Tolerance = 1e-8, __EquaForge_Algorithm = "bdf"), __EquaForge(category = "Aerospace", plots = {
          Plot(name = "Altitude", curves = {"airData.h"}),
          Plot(name = "Airspeed and Mach number", curves = {"airData.V", "airData.Mach"}),
          Plot(name = "Deceleration", curves = {"imu.loadFactor"}),
          Plot(name = "Stagnation heat flux", curves = {"heating.q"}),
          Plot(name = "Heat shield and structure", curves = {"shield.T", "structure.T"}),
          Plot(name = "Dynamic pressure", curves = {"airData.qbar"})}, plotArrangement = "Grid", linkTime = true),
        Diagram(coordinateSystem(extent = {{-100, -110}, {120, 120}}), graphics = {Text(extent = {{-95, 118}, {115, 80}}, textString = "## Entry heating\nA 5 t capsule meets the atmosphere at 120 km and 7.5 km/s, 2 deg below the horizon. Drag brakes it at up to about 8 g; the Sutton-Graves heat flux peaks earlier, high up, and the heat shield glows as it radiates the heat away.\n- Plot the deceleration, the heat flux and the shield temperature; open the 3-D view.\n- Try: a steeper entry (gamma0), a heavier capsule, a smaller shield.", fontSize = 9, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
        Documentation(info = "<html><p>A ballistic entry: <code>Environment.AirData</code> and <code>AtmosphereUS76</code> give the dynamic pressure, <code>Aerodynamics.BodyAero</code> the drag, and <code>Thermal.StagnationHeating</code> the heat flow into a lumped heat shield that radiates to the sky and conducts into the structure. For a ballistic entry the peak deceleration is about V0^2 sin(gamma0) / (2 e H) (Allen and Eggers, H the scale height), independent of the mass.</p></html>"));
    end EntryHeating;
    model Hopper "A test vehicle hops from its pad on the turning Earth and lands again with a guided landing burn"
      parameter Real latitude(unit = "rad", displayUnit = "deg") = 0.4538 "Latitude of the pad (26 deg)";
      parameter Real longitude(unit = "rad", displayUnit = "deg") = -1.6956 "Longitude of the pad (-97.15 deg)";
      parameter Real tLiftoff(unit = "s") = 3 "Release from the pad";
      parameter Real tCutoff(unit = "s") = 16 "Engine cutoff on the way up";
      final parameter Real Rs[3, 3] = Multibody.Frames.fromQ(site.Q_site);
      Environment.RotatingEarth earth annotation(Placement(transformation(origin = {-130, 60}, extent = {{-10, -10}, {10, 10}})));
      Environment.LaunchSite site(latitude = latitude, longitude = longitude) annotation(Placement(transformation(origin = {-100, 60}, extent = {{-10, -10}, {10, 10}})));
      Multibody.JointsAndMotions.Attachment clamp "Hold-down clamps" annotation(Placement(transformation(origin = {-60, 60}, extent = {{-10, -10}, {10, 10}})));
      Multibody.BodiesAndFrames.CapturableBody vehicle(r_start = site.r_site, v_start = cross({0, 0, EquaForgeAerospace.omegaEarth}, site.r_site), Q_start = site.Q_site, w_start = Rs*{0, 0, EquaForgeAerospace.omegaEarth}, r_nominal = 6.4e6, v_nominal = 500) annotation(Placement(transformation(origin = {-20, 60}, extent = {{-10, -10}, {10, 10}})));
      Multibody.BodiesAndFrames.RigidBodyFrame foot[4](r = {{0, 4, 0}, {0, 0, 4}, {0, -4, 0}, {0, 0, -4}}) "Feet of the four legs" annotation(Placement(transformation(origin = {-36, 20}, extent = {{-6, -6}, {6, 6}}, rotation = 180)));
      Multibody.ForcesAndMoments.Contact legs[4](each n = {1, 0, 0}, each c = 5e6, each d = 5e5, each d_t = 5e5) "Landing legs on the pad (x is up at the site)" annotation(Placement(transformation(origin = {-60, 20}, extent = {{-10, -10}, {10, 10}})));
      Multibody.Sensors.RelativePosition aboveSite annotation(Placement(transformation(origin = {-60, -20}, extent = {{-10, -10}, {10, 10}})));
      Multibody.BodiesAndFrames.MassProperties dry(m = 6e4, r_CM = {9, 0, 0}, I_11 = 2e5, I_22 = 2.5e6, I_33 = 2.5e6) annotation(Placement(transformation(origin = {-110, -60}, extent = {{-10, -10}, {10, 10}})));
      Propulsion.PropellantTank lox(rho_l = 1141, radius = 2, length = 4, x_bottom = 3, m_start = 3e4, R_gas = 259.8, T_sat = 90, h_fg = 2.13e5) annotation(Placement(transformation(origin = {-110, -100}, extent = {{-10, -10}, {10, 10}})));
      Propulsion.PropellantTank ch4(rho_l = 422, radius = 2, length = 4, x_bottom = 8, m_start = 8.3e3, R_gas = 518.3, T_sat = 112, h_fg = 5.1e5) annotation(Placement(transformation(origin = {-110, -140}, extent = {{-10, -10}, {10, 10}})));
      Multibody.BodiesAndFrames.MassSum3 massSum annotation(Placement(transformation(origin = {-60, -100}, extent = {{-10, -10}, {10, 10}})));
      Propulsion.EngineCluster engine(N = 1, F_vac = 1.5e6, Isp_vac = 350, A_e = 0.5, pe_ratio = 3e-3) annotation(Placement(transformation(origin = {40, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
      Blocks.Gain pressurantOx(k = 0.004) "Autogenous pressurant: a share of the flow" annotation(Placement(transformation(origin = {-80, -120}, extent = {{-6, -6}, {6, 6}}, rotation = 180)));
      Blocks.Gain pressurantFuel(k = 0.004) annotation(Placement(transformation(origin = {-80, -160}, extent = {{-6, -6}, {6, 6}}, rotation = 180)));
      Environment.CentralGravity gravity annotation(Placement(transformation(origin = {20, 100}, extent = {{-10, -10}, {10, 10}})));
      Environment.AtmosphereUS76 atmosphere annotation(Placement(transformation(origin = {110, 100}, extent = {{-10, -10}, {10, 10}})));
      Environment.AirData airData annotation(Placement(transformation(origin = {70, 100}, extent = {{-10, -10}, {10, 10}})));
      Aerodynamics.BodyAero aero(S = 12.6, planformRatio = 5, x_cp_nose = 14, x_cp_tail = 6, x_cp_broadside = 10) annotation(Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
      GNC.IMU imu annotation(Placement(transformation(origin = {70, 140}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Constant level(k = 0) annotation(Placement(transformation(origin = {20, -80}, extent = {{-6, -6}, {6, 6}})));
      Blocks.Constant east(k = EquaForgeVC.pi/2) annotation(Placement(transformation(origin = {20, -100}, extent = {{-6, -6}, {6, 6}})));
      GNC.LocalDirection eastward annotation(Placement(transformation(origin = {50, -100}, extent = {{-10, -10}, {10, 10}})));
      GNC.AttitudeError attitude annotation(Placement(transformation(origin = {90, -80}, extent = {{-10, -10}, {10, 10}})));
      Blocks.RealDemultiplexer axes(n = 3) annotation(Placement(transformation(origin = {120, -80}, extent = {{-6, -6}, {6, 6}})));
      Blocks.PID pitchControl(k = 0.4, Ti = 20, Td = 1.6, N = 10, yMax = 0.15) "Gimbal about y from the error about y" annotation(Placement(transformation(origin = {150, -60}, extent = {{-10, -10}, {10, 10}})));
      Blocks.PID yawControl(k = 0.4, Ti = 20, Td = 1.6, N = 10, yMax = 0.15) annotation(Placement(transformation(origin = {150, -100}, extent = {{-10, -10}, {10, 10}})));
      Blocks.Constant zero(k = 0) annotation(Placement(transformation(origin = {120, -130}, extent = {{-6, -6}, {6, 6}})));
      Blocks.RealMultiplexer gimbals(n = 2) annotation(Placement(transformation(origin = {180, -80}, extent = {{-6, -6}, {6, 6}})));
      GNC.PoweredDescent descent(h_target = 0, v_touch = 1.5, margin = 0.8) annotation(Placement(transformation(origin = {20, -20}, extent = {{-10, -10}, {10, 10}})));
      Logical.ModeSequencer flight(n = 4) "0 pad, 1 ascent, 2 coast, 3 landing burn, 4 landed" annotation(Placement(transformation(origin = {100, -20}, extent = {{-10, -10}, {10, 10}})));
      Logical.LessThreshold touchdown(threshold = 0.05) annotation(Placement(transformation(origin = {60, -40}, extent = {{-6, -6}, {6, 6}})));
      Logical.Or burning1 annotation(Placement(transformation(origin = {140, -10}, extent = {{-6, -6}, {6, 6}})));
      Logical.Or burning annotation(Placement(transformation(origin = {160, 0}, extent = {{-6, -6}, {6, 6}})));
      Blocks.Constant cruise(k = 0.85) "Throttle on the way up" annotation(Placement(transformation(origin = {100, 20}, extent = {{-6, -6}, {6, 6}})));
      Blocks.Switch throttle annotation(Placement(transformation(origin = {140, 30}, extent = {{-10, -10}, {10, 10}})));
      Multibody.Visualization.AttachedShape hull(shapeType = EquaForgeVC.Visualization.ShapeType.Cylinder, length = 16, width = 4, position = {9, 0, 0}, color = {220, 220, 225}, trail = 60) annotation(Placement(transformation(origin = {0, 30}, extent = {{-6, -6}, {6, 6}})));
      Multibody.Visualization.AttachedShape pad(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 1, width = 30, height = 30, position = {-0.5, 0, 0}, color = {150, 150, 150}) annotation(Placement(transformation(origin = {-100, 20}, extent = {{-6, -6}, {6, 6}})));
    equation
      connect(earth.frame_b, site.frame_a) annotation(Line(points = {{-120, 60}, {-110, 60}}, color = {95, 95, 95}, thickness = 0.5));
      connect(earth.motion, site.earth) annotation(Line(points = {{-130, 49}, {-130, 40}, {-106, 40}, {-106, 49}}, color = {95, 95, 95}));
      connect(site.frame_b, clamp.frame_b) annotation(Line(points = {{-90, 60}, {-70, 60}}, color = {95, 95, 95}, thickness = 0.5));
      connect(site.motion, clamp.carrier) annotation(Line(points = {{-94, 49}, {-94, 44}, {-66, 44}, {-66, 49}}, color = {95, 95, 95}));
      connect(clamp.held, vehicle.carrier) annotation(Line(points = {{-49, 60}, {-40, 60}, {-40, 80}, {-26, 80}, {-26, 72}}, color = {95, 95, 95}));
      connect(vehicle.load, clamp.load) annotation(Line(points = {{-14, 49}, {-14, 44}, {-54, 44}, {-54, 49}}, color = {0, 100, 0}));
      for k in 1:4 loop
        connect(site.frame_b, legs[k].frame_a) annotation(Line(points = {{-90, 60}, {-80, 60}, {-80, 20}, {-70, 20}}, color = {95, 95, 95}));
        connect(vehicle.frame_a, foot[k].frame_a) annotation(Line(points = {{-30, 60}, {-26, 60}, {-26, 20}, {-30, 20}}, color = {95, 95, 95}));
        connect(foot[k].frame_b, legs[k].frame_b) annotation(Line(points = {{-42, 20}, {-50, 20}}, color = {95, 95, 95}));
      end for;
      connect(site.frame_b, aboveSite.frame_a) annotation(Line(points = {{-90, 60}, {-80, 60}, {-80, -20}, {-70, -20}}, color = {95, 95, 95}));
      connect(vehicle.frame_a, aboveSite.frame_b) annotation(Line(points = {{-30, 60}, {-36, 60}, {-36, -20}, {-50, -20}}, color = {95, 95, 95}));
      connect(site.frame_b, pad.frame_a) annotation(Line(points = {{-90, 60}, {-80, 60}, {-80, 34}, {-112, 34}, {-112, 20}, {-106, 20}}, color = {95, 95, 95}));
      connect(dry.y, massSum.u1) annotation(Line(points = {{-99, -60}, {-80, -60}, {-80, -94}, {-71, -94}}, color = {120, 60, 0}));
      connect(lox.mass, massSum.u2) annotation(Line(points = {{-110, -111}, {-110, -114}, {-90, -114}, {-90, -100}, {-71, -100}}, color = {120, 60, 0}));
      connect(ch4.mass, massSum.u3) annotation(Line(points = {{-110, -151}, {-110, -154}, {-76, -154}, {-76, -106}, {-71, -106}}, color = {120, 60, 0}));
      connect(massSum.y, vehicle.mass) annotation(Line(points = {{-49, -100}, {-20, -100}, {-20, 49}}, color = {120, 60, 0}));
      connect(vehicle.frame_a, engine.frame_b) annotation(Line(points = {{-30, 60}, {-36, 60}, {-36, 0}, {20, 0}, {20, 20}, {30, 20}}, color = {95, 95, 95}, thickness = 0.5));
      connect(engine.mdot_ox, lox.mdot_out) annotation(Line(points = {{34, 31}, {34, 36}, {-130, 36}, {-130, -94}, {-122, -94}}, color = {0, 0, 127}));
      connect(engine.mdot_fuel, ch4.mdot_out) annotation(Line(points = {{46, 31}, {46, 38}, {-134, 38}, {-134, -134}, {-122, -134}}, color = {0, 0, 127}));
      connect(engine.mdot_ox, pressurantOx.u) annotation(Line(points = {{34, 31}, {34, 36}, {-72, 36}, {-72, -120}, {-73, -120}}, color = {0, 0, 127}));
      connect(engine.mdot_fuel, pressurantFuel.u) annotation(Line(points = {{46, 31}, {46, 38}, {-70, 38}, {-70, -160}, {-73, -160}}, color = {0, 0, 127}));
      connect(pressurantOx.y, lox.mdot_press) annotation(Line(points = {{-86.6, -120}, {-126, -120}, {-126, -100}, {-122, -100}}, color = {0, 0, 127}));
      connect(pressurantFuel.y, ch4.mdot_press) annotation(Line(points = {{-86.6, -160}, {-126, -160}, {-126, -140}, {-122, -140}}, color = {0, 0, 127}));
      connect(imu.specificForce[1], lox.a_axial) annotation(Line(points = {{81, 144}, {190, 144}, {190, -170}, {-128, -170}, {-128, -106}, {-122, -106}}, color = {0, 0, 127}));
      connect(imu.specificForce[1], ch4.a_axial) annotation(Line(points = {{81, 144}, {190, 144}, {190, -170}, {-128, -170}, {-128, -146}, {-122, -146}}, color = {0, 0, 127}));
      connect(vehicle.frame_a, gravity.frame_a) annotation(Line(points = {{-30, 60}, {-36, 60}, {-36, 100}, {10, 100}}, color = {95, 95, 95}));
      connect(gravity.g, vehicle.g) annotation(Line(points = {{31, 100}, {40, 100}, {40, 76}, {-20, 76}, {-20, 72}}, color = {0, 0, 127}));
      connect(gravity.g, imu.g) annotation(Line(points = {{31, 100}, {40, 100}, {40, 134}, {58, 134}}, color = {0, 0, 127}));
      connect(vehicle.motion, imu.vehicle) annotation(Line(points = {{-9, 60}, {0, 60}, {0, 146}, {60, 146}}, color = {95, 95, 95}));
      connect(vehicle.motion, airData.vehicle) annotation(Line(points = {{-9, 60}, {0, 60}, {0, 106}, {60, 106}}, color = {95, 95, 95}));
      connect(airData.h, atmosphere.h) annotation(Line(points = {{81, 108}, {90, 108}, {90, 100}, {98, 100}}, color = {0, 0, 127}));
      connect(atmosphere.rho, airData.rho) annotation(Line(points = {{121, 106}, {126, 106}, {126, 84}, {54, 84}, {54, 96}, {58, 96}}, color = {0, 0, 127}));
      connect(atmosphere.a, airData.a) annotation(Line(points = {{121, 94}, {124, 94}, {124, 86}, {56, 86}, {56, 92}, {58, 92}}, color = {0, 0, 127}));
      connect(atmosphere.p, engine.p_amb) annotation(Line(points = {{121, 102}, {128, 102}, {128, 40}, {56, 40}, {56, 28}, {52, 28}}, color = {0, 0, 127}));
      connect(airData.v_air, aero.v_air) annotation(Line(points = {{81, 104}, {130, 104}, {130, 56}, {122, 56}}, color = {0, 0, 127}));
      connect(airData.qbar, aero.qbar) annotation(Line(points = {{81, 92}, {132, 92}, {132, 60}, {122, 60}}, color = {0, 0, 127}));
      connect(airData.Mach, aero.Mach) annotation(Line(points = {{81, 96}, {134, 96}, {134, 64}, {122, 64}}, color = {0, 0, 127}));
      connect(vehicle.frame_a, aero.frame_b) annotation(Line(points = {{-30, 60}, {-36, 60}, {-36, 0}, {94, 0}, {94, 60}, {100, 60}}, color = {95, 95, 95}));
      connect(vehicle.frame_a, hull.frame_a) annotation(Line(points = {{-30, 60}, {-36, 60}, {-36, 30}, {-6, 30}}, color = {95, 95, 95}));
      connect(level.y, eastward.elevation) annotation(Line(points = {{26.6, -80}, {32, -80}, {32, -100}, {38, -100}}, color = {0, 0, 127}));
      connect(east.y, eastward.azimuth) annotation(Line(points = {{26.6, -100}, {30, -100}, {30, -106}, {38, -106}}, color = {0, 0, 127}));
      connect(vehicle.motion, eastward.vehicle) annotation(Line(points = {{-9, 60}, {4, 60}, {4, -94}, {40, -94}}, color = {95, 95, 95}));
      connect(vehicle.motion, attitude.vehicle) annotation(Line(points = {{-9, 60}, {4, 60}, {4, -50}, {74, -50}, {74, -74}, {80, -74}}, color = {95, 95, 95}));
      connect(descent.direction, attitude.direction) annotation(Line(points = {{31, -28}, {70, -28}, {70, -80}, {78, -80}}, color = {0, 0, 127}));
      connect(site.motion, descent.target) annotation(Line(points = {{-94, 49}, {-94, -44}, {20, -44}, {20, -31}}, color = {95, 95, 95}));
      connect(eastward.d, attitude.rollReference) annotation(Line(points = {{61, -100}, {70, -100}, {70, -86}, {78, -86}}, color = {0, 0, 127}));
      connect(attitude.error, axes.u) annotation(Line(points = {{101, -80}, {112.8, -80}}, color = {0, 0, 127}));
      connect(axes.y[2], pitchControl.u_m) annotation(Line(points = {{126.6, -80}, {134, -80}, {134, -76}, {150, -76}, {150, -72}}, color = {0, 0, 127}));
      connect(axes.y[3], yawControl.u_m) annotation(Line(points = {{126.6, -80}, {134, -80}, {134, -116}, {150, -116}, {150, -112}}, color = {0, 0, 127}));
      connect(zero.y, pitchControl.u_s) annotation(Line(points = {{126.6, -130}, {136, -130}, {136, -60}, {138, -60}}, color = {0, 0, 127}));
      connect(zero.y, yawControl.u_s) annotation(Line(points = {{126.6, -130}, {136, -130}, {136, -100}, {138, -100}}, color = {0, 0, 127}));
      connect(pitchControl.y, gimbals.u[1]) annotation(Line(points = {{161, -60}, {166, -60}, {166, -80}, {172.8, -80}}, color = {0, 0, 127}));
      connect(yawControl.y, gimbals.u[2]) annotation(Line(points = {{161, -100}, {166, -100}, {166, -80}, {172.8, -80}}, color = {0, 0, 127}));
      connect(gimbals.y, engine.gimbal) annotation(Line(points = {{186.6, -80}, {194, -80}, {194, 20}, {52, 20}}, color = {0, 0, 127}));
      connect(vehicle.motion, descent.vehicle) annotation(Line(points = {{-9, 60}, {4, 60}, {4, -14}, {10, -14}}, color = {95, 95, 95}));
      connect(aboveSite.r_rel[1], descent.h) annotation(Line(points = {{-60, -31}, {-60, -36}, {-10, -36}, {-10, -20}, {8, -20}}, color = {0, 0, 127}));
      connect(aboveSite.r_rel[1], touchdown.u) annotation(Line(points = {{-60, -31}, {-60, -40}, {52.8, -40}}, color = {0, 0, 127}));
      connect(descent.throttle, throttle.u1) annotation(Line(points = {{31, -20}, {40, -20}, {40, 10}, {120, 10}, {120, 38}, {128, 38}}, color = {0, 0, 127}));
      connect(cruise.y, throttle.u3) annotation(Line(points = {{106.6, 20}, {128, 20}, {128, 22}}, color = {0, 0, 127}));
      connect(flight.active[4], throttle.u2) annotation(Line(points = {{111, -23}, {120, -23}, {120, 30}, {128, 30}}, color = {255, 0, 255}));
      connect(throttle.y, engine.throttle) annotation(Line(points = {{151, 30}, {160, 30}, {160, 12}, {52, 12}}, color = {0, 0, 127}));
      connect(flight.active[1], burning1.u1) annotation(Line(points = {{111, -27}, {126, -27}, {126, -10}, {132.8, -10}}, color = {255, 0, 255}));
      connect(flight.active[2], burning1.u2) annotation(Line(points = {{111, -25}, {128, -25}, {128, -14.8}, {132.8, -14.8}}, color = {255, 0, 255}));
      connect(burning1.y, burning.u1) annotation(Line(points = {{146.6, -10}, {148, -10}, {148, 0}, {152.8, 0}}, color = {255, 0, 255}));
      connect(flight.active[4], burning.u2) annotation(Line(points = {{111, -23}, {150, -23}, {150, -4.8}, {152.8, -4.8}}, color = {255, 0, 255}));
      connect(burning.y, engine.on) annotation(Line(points = {{166.6, 0}, {170, 0}, {170, 16}, {52, 16}}, color = {255, 0, 255}));
      connect(flight.active[1], clamp.attach) annotation(Line(points = {{111, -27}, {116, -27}, {116, 90}, {-60, 90}, {-60, 72}}, color = {255, 0, 255}));
      connect(flight.active[1], vehicle.attach) annotation(Line(points = {{111, -27}, {116, -27}, {116, 90}, {-14, 90}, {-14, 72}}, color = {255, 0, 255}));
      flight.advance[1] = time > tLiftoff;
      flight.advance[2] = time > tCutoff;
      flight.advance[3] = descent.ignite;
      connect(touchdown.y, flight.advance[4]) annotation(Line(points = {{66.6, -40}, {80, -40}, {80, -20}, {88, -20}}, color = {255, 0, 255}));
      descent.aMax = (engine.F_vac - engine.A_e*atmosphere.p)/massSum.y.m "full thrust over the mass";
      engine.failed = false;
      airData.wind = {0, 0} "calm";
      annotation(experiment(StopTime = 60, Interval = 0.02, Tolerance = 1e-7, __EquaForge_Algorithm = "bdf"), __EquaForge(category = "Aerospace", plots = {
          Plot(name = "Height above the pad", curves = {"aboveSite.r_rel[1]"}),
          Plot(name = "Sink rate and plan", curves = {"descent.sinkRate", "descent.v_ref"}),
          Plot(name = "Thrust", curves = {"engine.thrust"}),
          Plot(name = "Flight phase", curves = {"flight.phase"}),
          Plot(name = "Propellant", curves = {"lox.m", "ch4.m"}),
          Plot(name = "Tilt and gimbal", curves = {"attitude.angle", "pitchControl.y", "yawControl.y"}),
          Plot(name = "Leg loads", curves = {"legs[1].f_n", "legs[2].f_n", "legs[3].f_n", "legs[4].f_n"}),
          Plot(name = "Offset from the pad", curves = {"descent.offset"})}, plotArrangement = "Grid", linkTime = true),
        Diagram(coordinateSystem(extent = {{-140, -180}, {200, 220}}), graphics = {Text(extent = {{-135, 218}, {195, 170}}, textString = "## Hopper\nA 100 t test vehicle stands on its pad on the turning Earth, held by its clamps while its engine starts. Released at 3 s, it climbs to about 400 m, cuts off, falls, and lights again when the landing guidance says the burn would just stop it at the pad; steering over the pad all the way, it touches down at about 1.5 m/s and rests on its four legs.\n- Plot the height, the sink rate against its plan and the flight phase; open the 3-D view and follow the hull.\n- Try: a later cutoff, a smaller margin, a gust (the wind input of airData).", fontSize = 9, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
        Documentation(info = "<html><p>The launch-and-landing chain in miniature: a <code>Multibody.BodiesAndFrames.CapturableBody</code> held at an <code>Environment.LaunchSite</code> by an <code>Attachment</code>, an <code>Propulsion.EngineCluster</code> fed by two <code>PropellantTank</code>s, attitude control through the gimbal (<code>GNC.AttitudeError</code> and two <code>PID</code>s), a <code>Logical.ModeSequencer</code> for the phases, <code>GNC.PoweredDescent</code> for the landing burn and a <code>Multibody.ForcesAndMoments.Contact</code> for the legs.</p></html>"));
    end Hopper;
    annotation(Documentation(info = "<html><p>Small models of each part of the library: an orbit with J2, an engine on its test stand a capsule entering the atmosphere and a vehicle that hops off its pad and lands again. The launch and landing of a two-stage vehicle is the study <code>examples/starship_mission</code>.</p></html>"));
  end Examples;
  annotation(__EquaForge(toolboxGroups = true), Documentation(info = "<html><p>Launch vehicles and spacecraft, after the categories of reference simulator's aerospace libraries:</p><ul><li><b>Environment</b>: the turning Earth, launch sites, gravity with J2, the standard atmosphere, air data.</li><li><b>Aerodynamics</b>: body forces from nose-first to broadside and tail-first, flaps and grid fins.</li><li><b>Propulsion</b>: propellant tanks with pressurisation and boil-off, pump-fed engines, engine clusters with gimbal and engine out.</li><li><b>Actuators</b>: electromechanical actuators for gimbals and control surfaces.</li><li><b>GNC</b>: orbital elements, ground track, inertial sensors, steering directions, attitude error, impact point prediction and landing guidance.</li><li><b>Thermal</b>: stagnation-point heating for entry.</li></ul><p>The vehicles themselves are <code>Multibody.BodiesAndFrames.FreeBody</code> and <code>CapturableBody</code>: the world frame is inertial and centred on the Earth, z towards the north pole. Body axes: x along the vehicle, y towards its belly. The values in the blocks are illustrative orders of magnitude.</p></html>"));
end EquaForgeAerospace;

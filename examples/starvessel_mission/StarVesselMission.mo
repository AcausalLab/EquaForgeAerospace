package StarVesselMission "A StarVessel launch to orbit and back: ascent, hot staging, booster return and tower catch, orbit, entry and landing"
  model FeedSystem "Propellant feed of a stage: oxygen and methane tanks, autogenous pressurisation, heat leak and the stage's mass properties"
    parameter Real m_dry(unit = "kg") = 2.75e5 "Dry mass of the stage";
    parameter Real r_CM_dry[3](each unit = "m") = {30, 0, 0} "Centre of mass of the dry stage, stage frame";
    parameter Real I_dry[3](each unit = "kg.m2") = {5e6, 1.2e8, 1.2e8} "Inertia of the dry stage about its centre of mass";
    parameter Real radius(unit = "m") = 4.5 "Inner radius of the tanks";
    parameter Real m_lox(unit = "kg") = 2.65e6 "Liquid oxygen at the start";
    parameter Real lox_bottom(unit = "m") = 4 "Bottom of the oxygen tank, stage frame x";
    parameter Real lox_length(unit = "m") = 38.5 "Length of the oxygen tank";
    parameter Real m_ch4(unit = "kg") = 7.5e5 "Liquid methane at the start";
    parameter Real ch4_bottom(unit = "m") = 43 "Bottom of the methane tank";
    parameter Real ch4_length(unit = "m") = 29.5 "Length of the methane tank";
    parameter Real lox_residual(unit = "kg") = 2e-3*m_lox "Oxygen the engines cannot draw (0.2 % of a full load)";
    parameter Real ch4_residual(unit = "kg") = 2e-3*m_ch4 "Methane the engines cannot draw";
    parameter Real p_set(unit = "Pa") = 3.5e5 "Ullage pressure the controllers hold";
    parameter Real tapShare = 0.01 "Largest share of the engine flow the pressurant tap can return to a tank";
    parameter Real kPress(unit = "kg/(s.Pa)") = 2e-3 "Pressurant flow per pascal below the set-point";
    parameter Real T_ambient(unit = "K") = 290 "Temperature outside the insulation";
    parameter Real hA(unit = "W/K") = 4e3 "Heat leak through the insulation of each tank";
    EquaForgeVC.Interfaces.RealInput mdot_ox(unit = "kg/s") "Oxygen the engines draw" annotation(Placement(transformation(extent = {{-140, 40}, {-100, 80}})));
    EquaForgeVC.Interfaces.RealInput mdot_fuel(unit = "kg/s") "Methane the engines draw" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
    EquaForgeVC.Interfaces.RealInput a_axial(unit = "m/s2") "Specific force along the stage (settles the liquids)" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
    EquaForgeVC.Multibody.Interfaces.MassPropertiesOutput mass "The stage with its propellant" annotation(Placement(transformation(extent = {{100, 50}, {120, 70}})));
    EquaForgeVC.Interfaces.RealOutput propellant(unit = "kg") "Propellant left" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
    EquaForgeVC.Interfaces.BooleanOutput empty(start = false, fixed = true) "A tank has run dry: the engines it feeds flame out" annotation(Placement(transformation(extent = {{100, -100}, {120, -80}})));
    EquaForgeVC.Interfaces.RealOutput p_ullage[2](each unit = "Pa") "Ullage pressures: oxygen, methane" annotation(Placement(transformation(extent = {{100, -70}, {120, -50}})));
    EquaForgeAerospace.Propulsion.PropellantTank lox(rho_l = 1141, radius = radius, length = lox_length, x_bottom = lox_bottom, m_start = m_lox, p_start = p_set, R_gas = 259.8, T_sat = 90, h_fg = 2.13e5, p_relief = 1.3*p_set, m_residual = lox_residual) annotation(Placement(transformation(origin = {-20, 50}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Propulsion.PropellantTank ch4(rho_l = 422, radius = radius, length = ch4_length, x_bottom = ch4_bottom, m_start = m_ch4, p_start = p_set, R_gas = 518.3, T_sat = 112, h_fg = 5.1e5, p_relief = 1.3*p_set, m_residual = ch4_residual) annotation(Placement(transformation(origin = {-20, -50}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.BodiesAndFrames.MassProperties dry(m = m_dry, r_CM = r_CM_dry, I_11 = I_dry[1], I_22 = I_dry[2], I_33 = I_dry[3]) annotation(Placement(transformation(origin = {40, 80}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.BodiesAndFrames.MassSum3 stage annotation(Placement(transformation(origin = {80, 60}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Add total annotation(Placement(transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Constant setPoint(k = p_set) "Ullage pressure set-point" annotation(Placement(transformation(origin = {-130, 0}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.PI loxPress(k = kPress, Ti = 2, yMax = 1e3, yMin = 0) "Pressurant demand, oxygen tank" annotation(Placement(transformation(origin = {-95, 30}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.PI ch4Press(k = kPress/2, Ti = 2, yMax = 1e3, yMin = 0) "Pressurant demand, methane tank" annotation(Placement(transformation(origin = {-95, -70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Gain loxTap(k = tapShare) "What the tap can return" annotation(Placement(transformation(origin = {-95, 70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Gain ch4Tap(k = tapShare) annotation(Placement(transformation(origin = {-95, -30}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Min loxValve "Demand within the tap" annotation(Placement(transformation(origin = {-60, 50}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Min ch4Valve annotation(Placement(transformation(origin = {-60, -50}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Thermal.FixedTemperature outside(T = T_ambient) annotation(Placement(transformation(origin = {60, -60}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Thermal.Convection loxLeak(hA = hA) annotation(Placement(transformation(origin = {40, 30}, extent = {{-8, -8}, {8, 8}}, rotation = 180)));
    EquaForgeVC.Thermal.Convection ch4Leak(hA = hA) annotation(Placement(transformation(origin = {40, -80}, extent = {{-8, -8}, {8, 8}}, rotation = 180)));
    EquaForgeVC.Thermal.HeatCapacitor loxWall(C = 2e7, T_start = 95) annotation(Placement(transformation(origin = {15, 40}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Thermal.HeatCapacitor ch4Wall(C = 2e7, T_start = 115) annotation(Placement(transformation(origin = {15, -70}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Thermal.ThermalConductor loxWetted(G = 2e5) annotation(Placement(transformation(origin = {-5, 75}, extent = {{-6, -6}, {6, 6}}, rotation = 180)));
    EquaForgeVC.Thermal.ThermalConductor ch4Wetted(G = 2e5) annotation(Placement(transformation(origin = {-5, -25}, extent = {{-6, -6}, {6, 6}}, rotation = 180)));
  equation
    connect(mdot_ox, lox.mdot_out);
    connect(mdot_fuel, ch4.mdot_out);
    connect(a_axial, lox.a_axial);
    connect(a_axial, ch4.a_axial);
    connect(setPoint.y, loxPress.u_s);
    connect(setPoint.y, ch4Press.u_s);
    connect(lox.p, loxPress.u_m);
    connect(ch4.p, ch4Press.u_m);
    connect(mdot_ox, loxTap.u);
    connect(mdot_fuel, ch4Tap.u);
    connect(loxPress.y, loxValve.u1);
    connect(loxTap.y, loxValve.u2);
    connect(ch4Press.y, ch4Valve.u1);
    connect(ch4Tap.y, ch4Valve.u2);
    connect(loxValve.y, lox.mdot_press);
    connect(ch4Valve.y, ch4.mdot_press);
    connect(outside.port, loxLeak.fluid);
    connect(outside.port, ch4Leak.fluid);
    connect(loxLeak.solid, loxWall.port);
    connect(ch4Leak.solid, ch4Wall.port);
    connect(loxWall.port, loxWetted.port_a);
    connect(ch4Wall.port, ch4Wetted.port_a);
    connect(loxWetted.port_b, lox.heatPort);
    connect(ch4Wetted.port_b, ch4.heatPort);
    connect(dry.y, stage.u1);
    connect(lox.mass, stage.u2);
    connect(ch4.mass, stage.u3);
    connect(stage.y, mass);
    connect(lox.m, total.u1);
    connect(ch4.m, total.u2);
    connect(total.y, propellant);
    p_ullage = {lox.p, ch4.p};
    // once a tank has run dry the engines it feeds stay out
    empty = lox.empty or ch4.empty or pre(empty);
    annotation(Icon(graphics = {
        Rectangle(extent = {{-80, 90}, {-10, -90}}, lineColor = {64, 64, 64}, fillColor = {200, 225, 245}, fillPattern = FillPattern.Solid, radius = 20),
        Rectangle(extent = {{10, 90}, {80, -90}}, lineColor = {64, 64, 64}, fillColor = {245, 225, 200}, fillPattern = FillPattern.Solid, radius = 20),
        Text(extent = {{-80, 20}, {-10, -20}}, textString = "LOX"),
        Text(extent = {{10, 20}, {80, -20}}, textString = "CH4"),
        Text(extent = {{-150, 130}, {150, 100}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-140, -100}, {120, 140}}), graphics = {Text(extent = {{-135, 138}, {115, 100}}, textString = "## Feed system\nThe engines draw oxygen and methane from two tanks. A PI controller per tank holds the ullage at its set-point with gas tapped from the engines (Min: never more than the tap gives), heat through the insulation boils propellant off, and the dry stage plus both liquids make the stage's mass properties (MassSum3).", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>The propellant system of one stage, built from <code>Aerospace.Propulsion.PropellantTank</code>, <code>Blocks.PI</code>, <code>Blocks.Min</code> and the lumped <code>Thermal</code> blocks; its output is the mass, centre of mass and inertia of the stage as its tanks drain.</p></html>"));
  end FeedSystem;

  model ElectricBus "Battery and bus that power the electromechanical actuators"
    parameter Real V_battery(unit = "V") = 400 "Battery voltage";
    parameter Real R_internal(unit = "Ohm") = 0.02 "Internal resistance of the battery";
    parameter Real C_bus(unit = "F") = 0.2 "Bus capacitance";
    EquaForgeVC.Interfaces.RealInput current(unit = "A") "Current the actuators draw" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
    EquaForgeVC.Interfaces.RealOutput voltage(unit = "V") "Bus voltage" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
    Real power(unit = "W") "Power from the battery";
    EquaForgeVC.Electrical.Ground ground annotation(Placement(transformation(origin = {0, -60}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Electrical.ConstantVoltage battery(V = V_battery) annotation(Placement(transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Electrical.Resistor internal(R = R_internal) annotation(Placement(transformation(origin = {-30, 30}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Electrical.Capacitor bus(C = C_bus, v(start = V_battery, fixed = true)) annotation(Placement(transformation(origin = {10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    EquaForgeVC.Electrical.SignalCurrent load annotation(Placement(transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  equation
    connect(battery.n, ground.p);
    connect(battery.p, internal.p);
    connect(internal.n, bus.p);
    connect(internal.n, load.p);
    connect(bus.n, ground.p);
    connect(load.n, ground.p);
    connect(current, load.iRef);
    voltage = bus.v;
    power = battery.v*internal.i;
    annotation(Icon(graphics = {
        Rectangle(extent = {{-70, 40}, {70, -40}}, lineColor = {0, 0, 255}, fillColor = {235, 235, 255}, fillPattern = FillPattern.Solid),
        Line(points = {{-40, 20}, {-40, -20}}, color = {0, 0, 255}, thickness = 0.5),
        Line(points = {{-25, 10}, {-25, -10}}, color = {0, 0, 255}, thickness = 0.5),
        Text(extent = {{-10, 20}, {70, -20}}, textString = "V", textColor = {0, 0, 255}),
        Text(extent = {{-150, 90}, {150, 60}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-100, -80}, {100, 100}}), graphics = {Text(extent = {{-95, 98}, {95, 62}}, textString = "## Electric bus\nA battery with its internal resistance feeds the bus capacitor; the actuators draw their current (SignalCurrent), so a hard manoeuvre sags the bus voltage.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}));
  end ElectricBus;

  model ActuatorSet "Electromechanical actuators of a set of control surfaces or a gimbal"
    parameter Integer n(min = 1) = 4 "Number of actuators";
    parameter Boolean detailed = false "Each servo's motor electrics and loops (false: their second-order response, for long runs)" annotation(Evaluate = true);
    parameter Real ratio = 200 "Motor turns per surface turn";
    parameter Real J_load(unit = "kg.m2") = 2000 "Inertia of each surface about its hinge";
    parameter Real angleMax(unit = "rad", displayUnit = "deg") = 0.35 "Travel each way";
    parameter Real angleMin(unit = "rad", displayUnit = "deg") = -angleMax "Travel the other way";
    parameter Real Imax(unit = "A") = 150 "Current limit of each motor";
    parameter Real k_motor(unit = "N.m/A") = 2.0 "Torque constant";
    EquaForgeVC.Interfaces.RealInput command[n](each unit = "rad") "Commanded angles" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
    EquaForgeVC.Interfaces.RealInput loadTorque[n](each unit = "N.m") "Loads on the surfaces (hinge moments)" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
    EquaForgeVC.Interfaces.RealOutput angle[n](each unit = "rad", each displayUnit = "deg") "Angles of the surfaces" annotation(Placement(transformation(extent = {{100, 30}, {120, 50}})));
    EquaForgeVC.Interfaces.RealOutput current(unit = "A") "Current drawn from the bus" annotation(Placement(transformation(extent = {{100, -50}, {120, -30}})));
    EquaForgeAerospace.Actuators.ElectromechanicalActuator act[n](each detailed = detailed, each ratio = ratio, each J_load = J_load, each angleMax = angleMax, each angleMin = angleMin, each Imax = Imax, each k_motor = k_motor) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
  equation
    for k in 1:n loop
      connect(command[k], act[k].command);
      connect(loadTorque[k], act[k].loadTorque);
      connect(act[k].angle, angle[k]);
    end for;
    current = sum(act[k].current for k in 1:n);
    annotation(Icon(graphics = {
        Rectangle(extent = {{-80, 30}, {0, -30}}, lineColor = {0, 0, 0}, fillColor = {0, 110, 200}, fillPattern = FillPattern.HorizontalCylinder),
        Rectangle(extent = {{0, 10}, {80, -10}}, lineColor = {64, 64, 64}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Forward),
        Text(extent = {{-80, 20}, {0, -20}}, textString = "%n", textColor = {255, 255, 255}),
        Text(extent = {{-150, 80}, {150, 50}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-100, -60}, {100, 100}}), graphics = {Text(extent = {{-95, 98}, {95, 62}}, textString = "## Actuators\nOne electromechanical actuator per surface: a servo motor in position control turns a screw that moves the surface against its load (Drives.PositionServo, Mechanics.IdealGear, Mechanics.Torque).", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}));
  end ActuatorSet;

  model AttitudeControl "Attitude error, a PID per axis and the allocation to engine gimbal, aerodynamic surfaces and thrusters"
    parameter Real omega(unit = "rad/s") = 0.8 "Bandwidth of the attitude loops";
    parameter Real zeta = 0.9 "Damping of the attitude loops";
    parameter Real gimbalMax(unit = "rad", displayUnit = "deg") = 0.26 "Gimbal travel";
    parameter Real x_gimbal(unit = "m") = 0 "Gimbal plane along x, vehicle frame";
    parameter Real thrustMin(unit = "N") = 1e5 "Below this thrust the gimbal does not steer";
    parameter Real surfaceGain[3](each unit = "m3") = {1e3, 1e3, 1e3} "Moment of the surfaces per radian and per pascal of dynamic pressure, about x, y and z";
    parameter Real qMin(unit = "Pa") = 200 "Below this dynamic pressure the surfaces do not steer";
    parameter Real mix[4, 3] = {{0, -1, 0}, {0, 0, -1}, {0, 1, 0}, {0, 0, 1}} "Surface deflections per unit of moment about x, y, z";
    parameter Real surfaceBias[4](each unit = "rad") = zeros(4) "Neutral deflections of the surfaces";
    parameter Boolean useBandwidthInput = false "Scale the loops' bandwidth by the bandwidth input (faster loops for a flip and a landing)" annotation(Evaluate = true);
    parameter Boolean useTrimInput = false "Take the neutral deflections from the trim input (scheduled by the flight computer)" annotation(Evaluate = true);
    parameter Real surfaceMax(unit = "rad", displayUnit = "deg") = 0.35 "Surface travel each way from neutral";
    parameter Real rcsMax(unit = "N.m") = 5e5 "Largest moment of the reaction-control thrusters per axis";
    parameter Real rcsDeadband(unit = "N.m") = 1e4 "Commands the thrusters leave alone";
    parameter Real surfaceAuthority[3](each unit = "m3") = surfaceGain*surfaceMax "Surface moment per pascal at full travel, about x, y and z (0 where the surfaces do not steer)";
    parameter Real stopShare = 0.7 "Turn-rate limit, as a share of the rate the actuators can still stop on the way in";
    parameter Real Ti(unit = "s") = 30 "Integral time of the rate loops";
    EquaForgeVC.Multibody.Interfaces.MotionInput vehicle "Motion of the vehicle" annotation(Placement(transformation(extent = {{-110, 70}, {-90, 90}})));
    EquaForgeVC.Multibody.Interfaces.MassPropertiesInput mass "Mass properties (inertia, centre of mass)" annotation(Placement(transformation(extent = {{-110, -90}, {-90, -70}})));
    EquaForgeVC.Interfaces.RealInput direction[3] "Where the nose should point" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
    EquaForgeVC.Interfaces.RealInput rollReference[3] "Where the belly should point" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
    EquaForgeVC.Interfaces.RealInput thrust(unit = "N") "Thrust of the gimballed engines" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
    EquaForgeVC.Interfaces.RealInput qbar(unit = "Pa") "Dynamic pressure" annotation(Placement(transformation(origin = {0, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealInput trim[4](each unit = "rad") if useTrimInput "Neutral deflections of the surfaces" annotation(Placement(transformation(origin = {60, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealInput neutral[4](each unit = "rad") "The neutral deflections in use" annotation(Placement(transformation(origin = {60, -100}, extent = {{-4, -4}, {4, 4}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealInput bandwidth if useBandwidthInput "Bandwidth of the loops as a multiple of omega" annotation(Placement(transformation(origin = {-60, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealInput scale "The bandwidth multiple in use" annotation(Placement(transformation(origin = {-60, -100}, extent = {{-4, -4}, {4, 4}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealOutput gimbal[2](each unit = "rad") "Gimbal commands: about y, about z" annotation(Placement(transformation(extent = {{100, 50}, {120, 70}})));
    EquaForgeVC.Interfaces.RealOutput surfaces[4](each unit = "rad") "Surface commands" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
    EquaForgeVC.Interfaces.RealOutput rcs[3](each unit = "N.m") "Thruster moments" annotation(Placement(transformation(extent = {{100, -70}, {120, -50}})));
    Real M[3](each unit = "N.m") "Commanded moment";
    EquaForgeAerospace.GNC.AttitudeError error annotation(Placement(transformation(origin = {-70, 40}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Gain angleGain[3](each k = omega/(2*zeta)) "Turn rate wanted for the error" annotation(Placement(transformation(origin = {-45, 70}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.VariableLimiter rateLimit[3] "No faster than the actuators can stop" annotation(Placement(transformation(origin = {-20, 70}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.PI axis[3](each k = 2*zeta*omega, each Ti = Ti, each yMax = 2*omega^2*(if useBandwidthInput then 4 else 1)) "Rate loop per axis: angular acceleration command (rad/s2)" annotation(Placement(transformation(origin = {5, 55}, extent = {{-10, -10}, {10, 10}})));
    Real authority[3](each unit = "rad/s2") "Angular acceleration the gimbal, the surfaces and the thrusters can give";
    Real rateMax[3](each unit = "rad/s") "Fastest turn the actuators can still stop within the loop's bandwidth";
    EquaForgeVC.Blocks.Max thrustFloor annotation(Placement(transformation(origin = {-60, -40}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Constant minThrust(k = thrustMin) annotation(Placement(transformation(origin = {-85, -55}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeVC.Blocks.Division gimbalY "Moment over the thrust's lever" annotation(Placement(transformation(origin = {40, 70}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Division gimbalZ annotation(Placement(transformation(origin = {40, 50}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Limiter gimbalLimit[2](each uMax = gimbalMax, each generateEvent = false) annotation(Placement(transformation(origin = {70, 60}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Max qFloor annotation(Placement(transformation(origin = {-10, -80}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Constant minQ(k = qMin) annotation(Placement(transformation(origin = {-35, -95}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeVC.Blocks.Division surfaceShare[3] "Moment over the surfaces' authority" annotation(Placement(transformation(origin = {30, -10}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.VariableLimiter surfaceLimit[4] "Travel each way from neutral" annotation(Placement(transformation(origin = {80, 0}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.DeadZone rcsBand[3](each uMax = rcsDeadband) annotation(Placement(transformation(origin = {40, -60}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Limiter rcsLimit[3](each uMax = rcsMax, each generateEvent = false) annotation(Placement(transformation(origin = {70, -60}, extent = {{-6, -6}, {6, 6}})));
    Real lever(unit = "m") "From the gimbal to the centre of mass";
  equation
    connect(vehicle, error.vehicle);
    connect(direction, error.direction);
    connect(rollReference, error.rollReference);
    // rate command from the error, limited to what the actuators can stop; the rate loop follows it
    authority[1] = (rcsMax + noEvent(max(qbar - qMin, 0))*surfaceAuthority[1])/mass.I[1];
    authority[2] = (rcsMax + abs(lever)*thrust*sin(gimbalMax) + noEvent(max(qbar - qMin, 0))*surfaceAuthority[2])/mass.I[2];
    authority[3] = (rcsMax + abs(lever)*thrust*sin(gimbalMax) + noEvent(max(qbar - qMin, 0))*surfaceAuthority[3])/mass.I[3];
    rateMax = stopShare*authority/(scale*angleGain[1].k);
    for k in 1:3 loop
      // a bandwidth multiple s scales the error and the rate loop's inputs: the loop's frequency becomes s omega
      angleGain[k].u = scale*error.error[k];
      connect(angleGain[k].y, rateLimit[k].u);
      rateLimit[k].limit1 = rateMax[k];
      rateLimit[k].limit2 = -rateMax[k];
      axis[k].u_s = scale*rateLimit[k].y;
      // the rate loop measures the body's turn rate (rate gyros): no lag of a differentiated angle
      axis[k].u_m = scale*vehicle.w[k];
      connect(rcsBand[k].y, rcsLimit[k].u);
      connect(rcsLimit[k].y, rcs[k]);
      connect(qFloor.y, surfaceShare[k].u2);
    end for;
    M = {mass.I[1], mass.I[2], mass.I[3]} .* {axis[1].y, axis[2].y, axis[3].y};
    // gimbal: a deflection d about y gives the moment -lever T sin d about y (and likewise about z)
    lever = mass.r_CM[1] - x_gimbal;
    connect(thrust, thrustFloor.u1);
    connect(minThrust.y, thrustFloor.u2);
    gimbalY.u1 = -M[2]/lever;
    gimbalZ.u1 = -M[3]/lever;
    connect(thrustFloor.y, gimbalY.u2);
    connect(thrustFloor.y, gimbalZ.u2);
    connect(gimbalY.y, gimbalLimit[1].u);
    connect(gimbalZ.y, gimbalLimit[2].u);
    connect(gimbalLimit.y, gimbal);
    // surfaces: deflection share of each axis, mixed onto the four surfaces about their neutral deflections
    connect(trim, neutral);
    connect(bandwidth, scale);
    if not useBandwidthInput then
      scale = 1;
    end if;
    if not useTrimInput then
      neutral = surfaceBias;
    end if;
    connect(qbar, qFloor.u1);
    connect(minQ.y, qFloor.u2);
    for k in 1:3 loop
      surfaceShare[k].u1 = M[k]/surfaceGain[k];
    end for;
    for j in 1:4 loop
      surfaceLimit[j].u = neutral[j] + sum(mix[j, k]*surfaceShare[k].y for k in 1:3);
      surfaceLimit[j].limit1 = neutral[j] + surfaceMax;
      surfaceLimit[j].limit2 = neutral[j] - surfaceMax;
      connect(surfaceLimit[j].y, surfaces[j]);
    end for;
    // thrusters: what the gimbal and the surfaces leave to them, outside the dead band
    for k in 1:3 loop
      rcsBand[k].u = M[k];
    end for;
    annotation(Icon(graphics = {
        Rectangle(extent = {{-80, 60}, {80, -60}}, lineColor = {0, 0, 127}, fillColor = {245, 245, 255}, fillPattern = FillPattern.Solid),
        Line(points = {{-60, -40}, {40, 30}}, color = {0, 0, 127}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
        Line(points = {{-60, -40}, {10, 45}}, color = {200, 0, 0}, pattern = LinePattern.Dash),
        Text(extent = {{-150, 100}, {150, 70}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-110, -110}, {110, 140}}), graphics = {Text(extent = {{-105, 138}, {105, 98}}, textString = "## Attitude control\nThe attitude error sets a turn rate per axis, limited to what the actuators can stop (VariableLimiter), and a PI rate loop on the measured turn rate gives the angular acceleration; times the inertia it is the moment wanted. The gimbal gives it through the thrust's lever (Division by the thrust, Max keeps it finite), the surfaces through the dynamic pressure (Division by q, mixed onto four surfaces), and the thrusters take what is left outside their dead band.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}));
  end AttitudeControl;
  model BoosterFlightComputer "The booster's flight: pad, ascent, hot staging, flip and boostback, tail-first fall, landing burn into the tower"
    parameter Integer phase_start = 0 "Phase at the start: 0 pad (a segment that starts later sets 3 or 4)";
    parameter Real tRelease(unit = "s") = 4 "Release from the launch mount";
    parameter Real azimuth(unit = "rad", displayUnit = "deg") = 1.5708 "Launch azimuth, from north towards east";
    parameter Real latTarget(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the catch tower";
    parameter Real lonTarget(unit = "rad", displayUnit = "deg") = -1.69571 "Longitude of the catch tower";
    parameter Real pitchTimes[:](each unit = "s") = {0, 12, 20, 60, 100, 160} "Times of the pitch programme";
    parameter Real pitchElevations[size(pitchTimes, 1)](each unit = "rad", each displayUnit = "deg") = {1.5708, 1.5708, 1.48, 1.05, 0.75, 0.52} "Elevation of the nose above the horizon";
    parameter Real throttleTimes[:](each unit = "s") = {0, 50, 58, 78, 86} "Times of the throttle programme";
    parameter Real throttleValues[size(throttleTimes, 1)] = {1, 1, 0.7, 0.7, 1} "Throttle through max-Q";
    parameter Real m_MECO(unit = "kg") = 4.0e5 "Propellant left at main engine cutoff (for the return)";
    parameter Real tSeparation(unit = "s") = 2 "From cutoff to separation (hot staging)";
    parameter Real tFlip(unit = "s") = 12 "Shortest flip before the boostback burn may end";
    parameter Real boostbackElevation(unit = "rad", displayUnit = "deg") = 0.05 "Nose above the horizon in the boostback burn";
    parameter Real rangeBias(unit = "m") = 400 "The boostback aims this far beyond the tower (drag shortens the fall)";
    parameter Real crossGain(unit = "rad/m") = 2.2e-5 "Boostback: turn of the thrust's azimuth per metre of the impact point's cross-range";
    parameter Real h_ignitionMax(unit = "m") = 6000 "No landing burn above this height (the air still brakes the fall)";
    parameter Real glideTilt = 0.15 "Glide steering in the fall: tan of the nose's largest lean";
    parameter Real h_glide(unit = "m") = 40000 "Below this height the fall steers towards the target";
    parameter Real glideTime(unit = "s") = 20 "Glide steering: the cross-track speed it asks for closes the cross-track offset in this time";
    parameter Real glideGain(unit = "s/m") = 0.05 "Glide steering: lean per m/s of cross-track speed still needed";
    parameter Real F_engine(unit = "N") = 2.65e6 "Vacuum thrust of one engine";
    parameter Real A_engine(unit = "m2") = 1.5 "Exit area of one engine";
    parameter Real brakingMargin = 0.6 "Share of the thirteen engines' thrust the braking plan counts on (ignition)";
    parameter Real catchRadius(unit = "m") = 20 "The arms close on the booster if it reaches the catch height within this distance of the catch point";
    parameter Real landingBandwidth = 2.5 "Attitude loops in the landing burn, as a multiple of their bandwidth";
    EquaForgeVC.Multibody.Interfaces.MotionInput vehicle "Motion of the booster" annotation(Placement(transformation(extent = {{-210, 150}, {-190, 170}})));
    EquaForgeVC.Multibody.Interfaces.MotionInput target "Motion of the catch point" annotation(Placement(transformation(extent = {{-210, -170}, {-190, -150}})));
    EquaForgeVC.Interfaces.RealInput propellant(unit = "kg") "Propellant left" annotation(Placement(transformation(extent = {{-220, 80}, {-180, 120}})));
    EquaForgeVC.Interfaces.RealInput mass(unit = "kg") "Mass of the vehicle (stack while joined)" annotation(Placement(transformation(extent = {{-220, 20}, {-180, 60}})));
    EquaForgeVC.Interfaces.RealInput p_amb(unit = "Pa") "Ambient pressure" annotation(Placement(transformation(extent = {{-220, -40}, {-180, 0}})));
    EquaForgeVC.Interfaces.RealInput crossRange(unit = "m") "Impact point across the line from the tower to the booster" annotation(Placement(transformation(extent = {{-220, -140}, {-180, -100}})));
    EquaForgeVC.Interfaces.RealInput rangeToGo(unit = "m") "Impact point to the tower, positive while short" annotation(Placement(transformation(extent = {{-220, -100}, {-180, -60}})));
    EquaForgeVC.Interfaces.RealOutput direction[3] "Where the nose should point" annotation(Placement(transformation(extent = {{200, 150}, {220, 170}})));
    EquaForgeVC.Interfaces.RealOutput rollReference[3] "Where the belly should point" annotation(Placement(transformation(extent = {{200, 110}, {220, 130}})));
    EquaForgeVC.Interfaces.RealOutput throttleCenter "Throttle of the gimballed engines (core and inner ring)" annotation(Placement(transformation(extent = {{200, 60}, {220, 80}})));
    EquaForgeVC.Interfaces.RealOutput throttleOuter "Throttle of the outer ring" annotation(Placement(transformation(extent = {{200, 20}, {220, 40}})));
    EquaForgeVC.Interfaces.BooleanOutput centerOn "Core three running" annotation(Placement(transformation(extent = {{200, -20}, {220, 0}})));
    EquaForgeVC.Interfaces.BooleanOutput innerOn "Inner ring of ten running" annotation(Placement(transformation(extent = {{200, 220}, {220, 240}})));
    EquaForgeVC.Interfaces.BooleanOutput outerOn "Outer ring running" annotation(Placement(transformation(extent = {{200, -60}, {220, -40}})));
    EquaForgeVC.Interfaces.BooleanOutput held "Held by the launch mount" annotation(Placement(transformation(extent = {{200, -100}, {220, -80}})));
    EquaForgeVC.Interfaces.BooleanOutput joined "Carrying the ship" annotation(Placement(transformation(extent = {{200, -140}, {220, -120}})));
    EquaForgeVC.Interfaces.BooleanOutput finsDeployed "Grid fins steering" annotation(Placement(transformation(extent = {{200, -180}, {220, -160}})));
    EquaForgeVC.Interfaces.RealOutput bandwidth "Bandwidth multiple of the attitude loops" annotation(Placement(transformation(extent = {{200, 190}, {220, 210}})));
    EquaForgeVC.Interfaces.BooleanOutput caught "In the arms" annotation(Placement(transformation(extent = {{200, -250}, {220, -230}})));
    EquaForgeVC.Interfaces.BooleanOutput staging "Main engine cutoff has come: the ship lights its engines" annotation(Placement(transformation(extent = {{200, -220}, {220, -200}})));
    Real h(unit = "m") "Height above the catch point";
    Real toTarget[3](each unit = "m") "Horizontal way to the catch point, world frame";
    Real drift[3](each unit = "m/s") "Horizontal velocity relative to the catch point";
    Real crossTrack[3] "Horizontal, square to the drift: the line the fall steers along (the boostback set the range)";
    Real glideSteer(unit = "m/s") "Cross-track speed the fall still needs";
    Real glide[3] "Nose direction in the fall: tail-first, tilted towards the target";
    Real Rv[3, 3] "The booster's orientation";
    Real Rt[3, 3] "The catch point's axes: x up, y east, z north";
    EquaForgeVC.Logical.ModeSequencer flight(n = 6, phase_start = phase_start) "0 pad, 1 ascent, 2 hot staging, 3 flip and boostback, 4 fall, 5 landing burn, 6 caught" annotation(Placement(transformation(origin = {40, 0}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeVC.Blocks.Clock missionTime "Time since ignition" annotation(Placement(transformation(origin = {-150, 160}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.GreaterThreshold release(threshold = tRelease) annotation(Placement(transformation(origin = {-100, 60}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.LessThreshold meco(threshold = m_MECO) "Main engine cutoff" annotation(Placement(transformation(origin = {-100, 30}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.GreaterThreshold separated(threshold = tSeparation + 2) annotation(Placement(transformation(origin = {-100, 0}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.GreaterThreshold flipped(threshold = tFlip) annotation(Placement(transformation(origin = {-130, -40}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.LessThreshold onTarget(threshold = -rangeBias) "Impact point past the tower by the bias" annotation(Placement(transformation(origin = {-130, -70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.And boostbackDone annotation(Placement(transformation(origin = {-100, -55}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.LessThreshold lowEnough(threshold = h_ignitionMax) annotation(Placement(transformation(origin = {-70, -100}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.And lightUp "Low enough, and the burn would just stop the booster" annotation(Placement(transformation(origin = {0, -100}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.Less threeWillDo "The sink rate is down to the core three's landing profile" annotation(Placement(transformation(origin = {20, -130}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.And inLandingBurn annotation(Placement(transformation(origin = {45, -130}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Logical.SRLatch coreOnly "The landing burn starts on thirteen engines and ends on three" annotation(Placement(transformation(origin = {70, -130}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.And never annotation(Placement(transformation(origin = {70, -160}, extent = {{-5, -5}, {5, 5}})));
    Integer landingEngines "Engines of the landing burn";
    Real a13(unit = "m/s2") "Acceleration of thirteen engines at full thrust";
    Real stop13(unit = "m") "Stopping height of the braking plan";
    Boolean braking "Thirteen engines: the sink rate is high enough to brake on them";
    EquaForgeVC.Logical.LessThreshold atArms(threshold = 0.3) "Catch pins at the arms' height" annotation(Placement(transformation(origin = {-100, -120}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Table1D pitch(x = pitchTimes, values = pitchElevations) "Pitch programme" annotation(Placement(transformation(origin = {-110, 130}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Constant launchAzimuth(k = azimuth) annotation(Placement(transformation(origin = {-110, 105}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeAerospace.GNC.LocalDirection ascent annotation(Placement(transformation(origin = {-70, 130}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.VelocityDirection prograde annotation(Placement(transformation(origin = {-30, 160}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.VelocityDirection tailFirst(retrograde = true) "Nose against the velocity: engines first" annotation(Placement(transformation(origin = {10, 160}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.GroundTrack toTower(latTarget = latTarget, lonTarget = lonTarget) "Bearing of the tower" annotation(Placement(transformation(origin = {-70, 90}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Constant bbElevation(k = boostbackElevation) annotation(Placement(transformation(origin = {-40, 105}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeAerospace.GNC.LocalDirection boostback annotation(Placement(transformation(origin = {-10, 100}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Constant zero(k = 0) annotation(Placement(transformation(origin = {20, 130}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeAerospace.GNC.LocalDirection north "The local north: the axis the vehicle pitches about" annotation(Placement(transformation(origin = {50, 130}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.PoweredDescent landing(h_target = 0, v_touch = 1.0, margin = 0.75, tiltMax = 0.2, h_upright = 3, timeToGo = false, k_p = 0.06, k_d = 0.5, v_lateralMax = 10, h_hold = 150) annotation(Placement(transformation(origin = {-30, -150}, extent = {{-12, -12}, {12, 12}})));
    EquaForgeVC.Blocks.Table1D throttleProgramme(x = throttleTimes, values = throttleValues) annotation(Placement(transformation(origin = {120, 90}, extent = {{-8, -8}, {8, 8}})));
  equation
    connect(missionTime.y, pitch.u);
    connect(missionTime.y, throttleProgramme.u);
    connect(missionTime.y, release.u);
    connect(propellant, meco.u);
    connect(flight.phaseTime, separated.u);
    connect(flight.phaseTime, flipped.u);
    // the impact point only steers the boostback: elsewhere its relation stays quiet
    onTarget.u = if flight.phase == 3 then rangeToGo else 1e9;
    connect(flipped.y, boostbackDone.u1);
    connect(onTarget.y, boostbackDone.u2);
    connect(release.y, flight.advance[1]);
    connect(meco.y, flight.advance[2]);
    connect(separated.y, flight.advance[3]);
    connect(boostbackDone.y, flight.advance[4]);
    // the ignition test only matters in the fall: elsewhere (caught, h near zero) its relation stays quiet
    braking = stop13 >= (if flight.phase == 4 then h else 1e9);
    lightUp.u1 = braking;
    connect(lowEnough.y, lightUp.u2);
    connect(lightUp.y, flight.advance[5]);
    flight.advance[6] = atArms.y and landing.offset < catchRadius;
    connect(vehicle, ascent.vehicle);
    connect(pitch.y, ascent.elevation);
    connect(launchAzimuth.y, ascent.azimuth);
    connect(vehicle, prograde.vehicle);
    connect(vehicle, tailFirst.vehicle);
    connect(vehicle, toTower.vehicle);
    connect(vehicle, boostback.vehicle);
    connect(bbElevation.y, boostback.elevation);
    // the boostback thrusts towards the tower, turned a little to bring the impact point onto the line to it
    boostback.azimuth = toTower.bearing - noEvent(max(-0.1, min(0.1, crossGain*crossRange)));
    connect(vehicle, north.vehicle);
    connect(zero.y, north.elevation);
    connect(zero.y, north.azimuth);
    connect(vehicle, landing.vehicle);
    connect(target, landing.target);
    h = (vehicle.r - target.r)*target.r/sqrt(target.r*target.r);
    landing.h = h;
    a13 = 13*(F_engine - A_engine*p_amb)/mass;
    stop13 = noEvent(max(landing.sinkRate, 0))^2/(2*noEvent(max(brakingMargin*a13 - 9.80665, 0.5)));
    threeWillDo.u1 = landing.sinkRate;
    connect(landing.v_ref, threeWillDo.u2);
    connect(threeWillDo.y, inLandingBurn.u1);
    connect(flight.active[6], inLandingBurn.u2);
    connect(inLandingBurn.y, coreOnly.set);
    never.u1 = false;
    never.u2 = false;
    connect(never.y, coreOnly.reset);
    landingEngines = if flight.phase == 5 and coreOnly.y then 3 else 13;
    landing.aMax = 3*(F_engine - A_engine*p_amb)/mass "the plan and the tracking are the core three's";
    atArms.u = h;
    caught = flight.phase == 6;
    lowEnough.u = h;
    // falling tail-first, the body's normal force pushes away from the way the nose leans: lean against
    // the cross-track speed still needed (the boostback has set the range along the drift)
    toTarget = (target.r - vehicle.r) - ((target.r - vehicle.r)*target.r/(target.r*target.r))*target.r;
    drift = (vehicle.v - target.v) - ((vehicle.v - target.v)*target.r/(target.r*target.r))*target.r;
    crossTrack = cross(target.r, drift)/noEvent(max(sqrt(cross(target.r, drift)*cross(target.r, drift)), 1e-3));
    glideSteer = (toTarget*crossTrack)/glideTime - drift*crossTrack;
    glide = tailFirst.d - (if h < h_glide then noEvent(max(-glideTilt, min(glideTilt, glideGain*glideSteer))) else 0)*crossTrack;
    // what each phase steers by
    direction = if flight.phase == 6 then {Rt[1, 1], Rt[1, 2], Rt[1, 3]} elseif flight.phase <= 1 then ascent.d elseif flight.phase == 2 then prograde.d elseif flight.phase == 3 then boostback.d elseif flight.phase == 4 then glide else landing.direction;
    // in the landing burn the booster rolls its catch pins onto the arms (the tower's east-west line), caught it holds
    Rv = EquaForgeVC.Multibody.Frames.fromQ(vehicle.Q);
    Rt = EquaForgeVC.Multibody.Frames.fromQ(target.Q);
    rollReference = if flight.phase == 6 then {Rv[2, 1], Rv[2, 2], Rv[2, 3]} elseif flight.phase == 5 then {Rt[2, 1], Rt[2, 2], Rt[2, 3]} else cross(north.d, direction);
    bandwidth = if flight.phase == 5 then landingBandwidth else 1;
    throttleCenter = if flight.phase <= 1 then throttleProgramme.y elseif flight.phase == 2 then 0.4 elseif flight.phase == 3 then 1 elseif flight.phase == 5 then (if coreOnly.y then landing.throttle else 1) else 0.4;
    throttleOuter = throttleProgramme.y;
    centerOn = flight.phase <= 3 or flight.phase == 5;
    innerOn = flight.phase <= 1 or flight.phase == 3 or (flight.phase == 5 and not coreOnly.y);
    outerOn = flight.phase <= 1;
    held = flight.phase == 0;
    joined = flight.phase <= 1 or (flight.phase == 2 and flight.phaseTime < tSeparation);
    finsDeployed = flight.phase >= 3;
    staging = flight.phase >= 2;
    annotation(Icon(graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127}, fillColor = {240, 240, 255}, fillPattern = FillPattern.Solid),
        Text(extent = {{-90, 40}, {90, -40}}, textString = "FC"),
        Text(extent = {{-150, 140}, {150, 110}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-200, -240}, {200, 260}}), graphics = {Text(extent = {{-195, 258}, {195, 195}}, textString = "## Booster flight computer\nA ModeSequencer runs the flight: released by the clock, cut off when the propellant reaches the return reserve, separated two seconds into hot staging, the boostback ends when the impact point (ImpactPointPredictor) has passed the tower by the drag bias, the landing burn starts when PoweredDescent says so and ends at the arms.\nEach phase picks its direction: the pitch programme (Table1D, LocalDirection), prograde, the tower's bearing, tail-first, and the landing guidance.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}));
  end BoosterFlightComputer;
  model BoosterLook "The booster in the 3-D view: its hull, the hot-staging ring, the grid fins as they deflect, the catch pins and the plume of its engines"
    parameter Real trail(unit = "s") = 600 "Path drawn behind the hull";
    parameter Real F_full(unit = "N") = 7.5e7 "Thrust at which the plume is drawn its brightest";
    EquaForgeVC.Multibody.Interfaces.Frame_a frame_a "The booster's frame: at its engine gimbals, x towards the top" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
    EquaForgeVC.Interfaces.RealInput thrust(unit = "N") "Thrust of all its engines" annotation(Placement(transformation(origin = {-40, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealInput finAngle[4](each unit = "rad", each displayUnit = "deg") "Grid fin deflections (fins at +y, +z, -y, -z)" annotation(Placement(transformation(origin = {40, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Multibody.Visualization.AttachedShape hull(shapeType = EquaForgeVC.Visualization.ShapeType.Cylinder, length = 69, width = 9, position = {34.5, 0, 0}, color = {200, 200, 205}, trail = trail) "Stainless steel, 69 m" annotation(Placement(transformation(origin = {-40, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape ring(shapeType = EquaForgeVC.Visualization.ShapeType.Cylinder, length = 2, width = 9, position = {70, 0, 0}, color = {55, 55, 60}) "The vented hot-staging ring on top" annotation(Placement(transformation(origin = {0, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape fin[4](each shapeType = EquaForgeVC.Visualization.ShapeType.Box, each length = 3, each width = 4, each height = 0.6, widthDirection = {{0, 1, 0}, {0, 0, 1}, {0, -1, 0}, {0, 0, -1}}, position = {{66, 6.5, 0}, {66, 0, 6.5}, {66, -6.5, 0}, {66, 0, -6.5}}, each color = {85, 85, 92}, each useAngleInput = true, hingeAxis = {{0, 1, 0}, {0, 0, 1}, {0, -1, 0}, {0, 0, -1}}, hingePoint = {{66, 4.5, 0}, {66, 0, 4.5}, {66, -4.5, 0}, {66, 0, -4.5}}) "Grid fins, turning about their radial shafts" annotation(Placement(transformation(origin = {40, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape pin[2](each shapeType = EquaForgeVC.Visualization.ShapeType.Box, each length = 1.2, each width = 1.5, each height = 1.2, each widthDirection = {0, 0, 1}, position = {{62, 0, 5.25}, {62, 0, -5.25}}, each color = {70, 70, 78}) "The pins it hangs from in the tower's arms" annotation(Placement(transformation(origin = {-40, 5}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape plume(shapeType = EquaForgeVC.Visualization.ShapeType.Cone, length = 60, width = 14, position = {-30, 0, 0}, lengthDirection = {1, 0, 0}, color = {255, 170, 60}, useOpacityInput = true) "Exhaust: the tip at the engines, shown while they burn" annotation(Placement(transformation(origin = {0, 5}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(frame_a, hull.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {-54, 30}, {-54, 45}, {-50, 45}}, color = {95, 95, 95}));
    connect(frame_a, ring.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {-14, 30}, {-14, 45}, {-10, 45}}, color = {95, 95, 95}));
    connect(frame_a, plume.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {-14, -10}, {-14, 5}, {-10, 5}}, color = {95, 95, 95}));
    for k in 1:4 loop
      connect(frame_a, fin[k].frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {26, 30}, {26, 45}, {30, 45}}, color = {95, 95, 95}));
      connect(finAngle[k], fin[k].angleIn) annotation(Line(points = {{40, -100}, {40, 20}, {34, 20}, {34, 33}}, color = {0, 0, 127}));
    end for;
    for k in 1:2 loop
      connect(frame_a, pin[k].frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {-54, -10}, {-54, 5}, {-50, 5}}, color = {95, 95, 95}));
    end for;
    plume.opacityIn = noEvent(if thrust > 1e5 then 0.4 + 0.45*min(1, thrust/F_full) else 0);
    annotation(Icon(graphics = {
        Rectangle(extent = {{-25, 80}, {25, -50}}, lineColor = {80, 80, 80}, fillColor = {210, 210, 215}, fillPattern = FillPattern.VerticalCylinder),
        Polygon(points = {{-20, -50}, {20, -50}, {35, -90}, {-35, -90}}, lineColor = {230, 140, 40}, fillColor = {255, 180, 70}, fillPattern = FillPattern.Solid),
        Rectangle(extent = {{-40, 75}, {-25, 60}}, lineColor = {60, 60, 60}, fillColor = {90, 90, 90}, fillPattern = FillPattern.CrossDiag),
        Rectangle(extent = {{25, 75}, {40, 60}}, lineColor = {60, 60, 60}, fillColor = {90, 90, 90}, fillPattern = FillPattern.CrossDiag),
        Text(extent = {{-150, 130}, {150, 95}}, textString = "%name")}),
      Diagram(graphics = {Text(extent = {{-95, 98}, {95, 72}}, textString = "## Booster in 3-D\nShapes only (AttachedShape): they put no load on the booster. The fins turn with their actuators (angle input), the plume shows while the engines burn (opacity input).", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>What the 3-D view draws of the booster, about its frame at the engine gimbals (x towards the top): a 9 m hull 69 m long, the dark hot-staging ring above it, four grid fins at 66 m that turn with their actuators, the two catch pins at 62 m and a plume below the engines that shows while they burn, brighter with more thrust.</p></html>"));
  end BoosterLook;

  model Booster "StarVessel booster: structure, feed system, 33 engines in two rings, grid fins, actuators, attitude control and flight computer"
    parameter Integer phase_start = 0 "Phase of the flight computer at the start";
    parameter Real r_start[3](each unit = "m") = zeros(3) "Position of the booster frame at the start, world";
    parameter Real v_start[3](each unit = "m/s") = zeros(3) "Velocity at the start, world";
    parameter Real Q_start[4] = {0, 0, 0, 1} "Orientation at the start";
    parameter Real w_start[3](each unit = "rad/s") = zeros(3) "Angular velocity at the start, booster frame";
    parameter Real m_lox(unit = "kg") = 2.661e6 "Liquid oxygen loaded (a little over the mixture ratio: oxygen boils off faster)";
    parameter Real m_ch4(unit = "kg") = 7.39e5 "Liquid methane loaded";
    parameter Real shipMountX(unit = "m") = 69 "Where the ship's frame sits on the booster (its engine plane)";
    parameter Real latTower(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the catch tower";
    parameter Real lonTower(unit = "rad", displayUnit = "deg") = -1.69571 "Longitude of the catch tower";
    parameter Real tRelease(unit = "s") = 4 "Release from the launch mount";
    parameter Real m_MECO(unit = "kg") = 4.0e5 "Propellant left at cutoff";
    parameter Real rangeBias(unit = "m") = -350 "Boostback aim beyond the tower";
    parameter Boolean towerHolds = true "Caught: the arms hold the booster (true), or it rests on them through its pins' contacts (false: a TowerCatch with the arm mechanism)" annotation(Evaluate = true);
    EquaForgeVC.Multibody.Interfaces.Frame_b frame_a "The booster's frame (at its engine gimbals)" annotation(Placement(transformation(extent = {{-210, -10}, {-190, 10}})));
    EquaForgeVC.Multibody.Interfaces.MotionInput carrier "Launch mount: where the booster is held" annotation(Placement(transformation(origin = {-160, 210}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    EquaForgeVC.Multibody.Interfaces.LoadOutput load "Loads the launch mount takes while it holds the booster" annotation(Placement(transformation(origin = {-120, 210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Multibody.Interfaces.MotionInput towerCarrier "Catch arms: where the booster's frame is held once caught" annotation(Placement(transformation(origin = {40, -210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Interfaces.BooleanOutput caught "Caught by the tower" annotation(Placement(transformation(origin = {80, -210}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    EquaForgeVC.Interfaces.BooleanOutput held "Held by the launch mount" annotation(Placement(transformation(origin = {-80, 210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Multibody.Interfaces.MotionOutput motion "Motion of the booster frame" annotation(Placement(transformation(extent = {{200, 150}, {220, 170}})));
    EquaForgeVC.Multibody.Interfaces.MassPropertiesInput shipMass "The ship, about its frame" annotation(Placement(transformation(origin = {40, 210}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    EquaForgeVC.Multibody.Interfaces.LoadInput shipLoad "Loads on the ship while it is carried" annotation(Placement(transformation(origin = {80, 210}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    EquaForgeVC.Multibody.Interfaces.MotionOutput shipCarrier "Where the ship's frame must be while carried" annotation(Placement(transformation(origin = {120, 210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Interfaces.BooleanOutput joined "Carrying the ship" annotation(Placement(transformation(origin = {160, 210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Interfaces.BooleanOutput staging "Cutoff has come: the ship lights its engines" annotation(Placement(transformation(extent = {{200, 110}, {220, 130}})));
    EquaForgeVC.Multibody.Interfaces.MotionInput catchTarget "Motion of the point the booster's frame must stop at (below the arms)" annotation(Placement(transformation(origin = {0, -210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Multibody.Interfaces.Frame_b pin[2] "Catch pins: they rest on the tower's arms" annotation(Placement(transformation(extent = {{190, -10}, {210, 10}})));
    EquaForgeVC.Multibody.BodiesAndFrames.CapturableBody body(r_start = r_start, v_start = v_start, Q_start = Q_start, w_start = w_start, r_nominal = 6.4e6, v_nominal = 2e3) annotation(Placement(transformation(origin = {-120, 0}, extent = {{-14, -14}, {14, 14}})));
    FeedSystem feed(m_lox = m_lox, m_ch4 = m_ch4) annotation(Placement(transformation(origin = {-120, -100}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeVC.Multibody.BodiesAndFrames.CombinedMass stack(r_rel = {shipMountX, 0, 0}) "Booster and the ship it carries" annotation(Placement(transformation(origin = {-70, -100}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.JointsAndMotions.Attachment shipMount(r_rel = {shipMountX, 0, 0}) "Hot-staging ring" annotation(Placement(transformation(origin = {100, 170}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Propulsion.EngineCluster centerRing(N = 3, ringRadius = 0.9, failedAngle = 0.3) "Gimballed: the core three (they land the booster)" annotation(Placement(transformation(origin = {-160, -50}, extent = {{-12, -12}, {12, 12}}, rotation = 180)));
    EquaForgeAerospace.Propulsion.EngineCluster innerRing(N = 10, ringRadius = 2.5) "Gimballed: the inner ring of ten" annotation(Placement(transformation(origin = {-160, 0}, extent = {{-12, -12}, {12, 12}}, rotation = 180)));
    EquaForgeVC.Blocks.Add gimballedThrust annotation(Placement(transformation(origin = {-20, -100}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Add oxygenAll annotation(Placement(transformation(origin = {-185, -100}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeVC.Blocks.Add methaneAll annotation(Placement(transformation(origin = {-185, -130}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeAerospace.Propulsion.EngineCluster outerRing(N = 20, ringRadius = 4.0) "Fixed: the outer 20" annotation(Placement(transformation(origin = {-160, 50}, extent = {{-12, -12}, {12, 12}}, rotation = 180)));
    EquaForgeVC.Blocks.Add oxygen annotation(Placement(transformation(origin = {-170, -100}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Add methane annotation(Placement(transformation(origin = {-170, -130}, extent = {{-6, -6}, {6, 6}})));
    ActuatorSet gimbals(n = 2, ratio = 200, J_load = 4.7e4, angleMax = 0.26, Imax = 300) annotation(Placement(transformation(origin = {-80, -50}, extent = {{-10, -10}, {10, 10}})));
    ActuatorSet fins(n = 4, ratio = 300, J_load = 3e3, angleMax = 0.35, Imax = 200) annotation(Placement(transformation(origin = {60, 60}, extent = {{-10, -10}, {10, 10}})));
    ElectricBus bus annotation(Placement(transformation(origin = {60, 110}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Add actuatorCurrent annotation(Placement(transformation(origin = {30, 110}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeAerospace.Environment.CentralGravity gravity annotation(Placement(transformation(origin = {-60, 60}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.AtmosphereUS76 atmosphere annotation(Placement(transformation(origin = {40, -150}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.AirData airData annotation(Placement(transformation(origin = {0, -150}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.FileTable windTable(fileName = "wind.csv", columns = {2, 3}) "Wind against altitude: east, north" annotation(Placement(transformation(origin = {-40, -170}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Aerodynamics.BodyAero aero(S = 63.6, CA_tailFactor = 2.5, planformRatio = 8, x_cp_nose = 42, x_cp_tail = 36, x_cp_broadside = 35) annotation(Placement(transformation(origin = {-60, -150}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBodyFrame finStation(r = {66, 0, 0}) annotation(Placement(transformation(origin = {60, 20}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Aerodynamics.GridFinSet gridFins(S = 10, CN_delta = 3, radius = 5.5) annotation(Placement(transformation(origin = {100, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBodyFrame pinMount[2](r = {{62, 0, 5.5}, {62, 0, -5.5}}) annotation(Placement(transformation(origin = {160, 0}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.GNC.IMU imu annotation(Placement(transformation(origin = {-20, 60}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.ImpactPointPredictor ipp(latTarget = latTower, lonTarget = lonTower) annotation(Placement(transformation(origin = {20, 20}, extent = {{-10, -10}, {10, 10}})));
    AttitudeControl control(omega = 0.6, useBandwidthInput = true, surfaceGain = {660, 1860, 1860}, mix = {{1, -1, 0}, {1, 0, -1}, {1, 1, 0}, {1, 0, 1}}, rcsMax = 2e6, rcsDeadband = 2e5) annotation(Placement(transformation(origin = {20, -60}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeVC.Multibody.ForcesAndMoments.BodyMoment rcs "Reaction-control thrusters" annotation(Placement(transformation(origin = {-60, 20}, extent = {{-8, -8}, {8, 8}}, rotation = 180)));
    BoosterFlightComputer computer(phase_start = phase_start, tRelease = tRelease, m_MECO = m_MECO, rangeBias = rangeBias, latTarget = latTower, lonTarget = lonTower) annotation(Placement(transformation(origin = {120, -80}, extent = {{-16, -16}, {16, 16}})));
    BoosterLook look "How it looks in the 3-D view" annotation(Placement(transformation(origin = {-160, 120}, extent = {{-10, -10}, {10, 10}})));
  equation
    // the body and the launch mount
    connect(body.frame_a, frame_a);
    connect(body.load, load);
    connect(body.motion, motion);
    // the launch mount holds the booster before lift-off, the tower's arms once it is caught
    body.carrier.r = if computer.caught then towerCarrier.r else carrier.r;
    body.carrier.v = if computer.caught then towerCarrier.v else carrier.v;
    body.carrier.a = if computer.caught then towerCarrier.a else carrier.a;
    body.carrier.Q = if computer.caught then towerCarrier.Q else carrier.Q;
    body.carrier.w = if computer.caught then towerCarrier.w else carrier.w;
    body.carrier.z = if computer.caught then towerCarrier.z else carrier.z;
    body.attach = computer.held or computer.caught and towerHolds;
    held = computer.held;
    caught = computer.caught;
    connect(stack.y, body.mass);
    // propulsion and propellant
    connect(body.frame_a, centerRing.frame_b);
    connect(body.frame_a, outerRing.frame_b);
    connect(body.frame_a, innerRing.frame_b);
    connect(centerRing.mdot_ox, oxygen.u1);
    connect(outerRing.mdot_ox, oxygen.u2);
    connect(centerRing.mdot_fuel, methane.u1);
    connect(outerRing.mdot_fuel, methane.u2);
    connect(oxygen.y, oxygenAll.u1);
    connect(innerRing.mdot_ox, oxygenAll.u2);
    connect(methane.y, methaneAll.u1);
    connect(innerRing.mdot_fuel, methaneAll.u2);
    connect(oxygenAll.y, feed.mdot_ox);
    connect(methaneAll.y, feed.mdot_fuel);
    feed.a_axial = imu.specificForce[1];
    connect(feed.mass, stack.u1);
    connect(atmosphere.p, centerRing.p_amb);
    connect(atmosphere.p, outerRing.p_amb);
    connect(atmosphere.p, innerRing.p_amb);
    connect(computer.throttleCenter, innerRing.throttle);
    innerRing.on = computer.innerOn and not feed.empty;
    innerRing.failed = false;
    connect(computer.throttleCenter, centerRing.throttle);
    connect(computer.throttleOuter, outerRing.throttle);
    centerRing.on = computer.centerOn and not feed.empty;
    outerRing.on = computer.outerOn and not feed.empty;
    centerRing.failed = false;
    outerRing.failed = false;
    outerRing.gimbal = zeros(2);
    // the ship on top
    connect(shipMass, stack.u2);
    connect(computer.joined, stack.joined);
    connect(body.frame_a, shipMount.frame_b);
    connect(body.motion, shipMount.carrier);
    connect(shipMount.held, shipCarrier);
    connect(shipLoad, shipMount.load);
    connect(computer.joined, shipMount.attach);
    joined = computer.joined;
    staging = computer.staging;
    // environment
    connect(body.frame_a, gravity.frame_a);
    connect(gravity.g, body.g);
    connect(gravity.g, imu.g);
    connect(body.motion, imu.vehicle);
    connect(body.motion, airData.vehicle);
    connect(airData.h, atmosphere.h);
    connect(atmosphere.rho, airData.rho);
    connect(atmosphere.a, airData.a);
    connect(airData.h, windTable.u);
    connect(windTable.y, airData.wind);
    connect(body.frame_a, aero.frame_b);
    connect(airData.v_air, aero.v_air);
    connect(airData.qbar, aero.qbar);
    connect(airData.Mach, aero.Mach);
    connect(body.frame_a, finStation.frame_a);
    connect(finStation.frame_b, gridFins.frame_b);
    connect(airData.qbar, gridFins.qbar);
    for k in 1:2 loop
      connect(body.frame_a, pinMount[k].frame_a);
      connect(pinMount[k].frame_b, pin[k]);
    end for;
    // guidance, navigation and control
    connect(body.motion, ipp.vehicle);
    connect(body.motion, computer.vehicle);
    connect(catchTarget, computer.target);
    connect(feed.propellant, computer.propellant);
    computer.mass = stack.y.m;
    connect(atmosphere.p, computer.p_amb);
    connect(ipp.rangeToGo, computer.rangeToGo);
    connect(ipp.crossRange, computer.crossRange);
    connect(body.motion, control.vehicle);
    connect(stack.y, control.mass);
    connect(computer.direction, control.direction);
    connect(computer.rollReference, control.rollReference);
    connect(computer.bandwidth, control.bandwidth);
    connect(centerRing.thrust, gimballedThrust.u1);
    connect(innerRing.thrust, gimballedThrust.u2);
    connect(gimballedThrust.y, control.thrust);
    connect(airData.qbar, control.qbar);
    // the gimbals centre while the gimballed engines are off
    gimbals.command = if computer.centerOn then control.gimbal else zeros(2);
    gimbals.loadTorque = zeros(2);
    connect(gimbals.angle, centerRing.gimbal);
    connect(gimbals.angle, innerRing.gimbal);
    fins.command = if computer.finsDeployed then control.surfaces else zeros(4);
    connect(gridFins.hingeMoment, fins.loadTorque);
    connect(fins.angle, gridFins.delta);
    connect(body.frame_a, rcs.frame_b);
    connect(control.rcs, rcs.t);
    connect(gimbals.current, actuatorCurrent.u1);
    connect(fins.current, actuatorCurrent.u2);
    connect(actuatorCurrent.y, bus.current);
    connect(body.frame_a, look.frame_a);
    connect(fins.angle, look.finAngle);
    look.thrust = centerRing.thrust + innerRing.thrust + outerRing.thrust;
    annotation(Icon(coordinateSystem(extent = {{-200, -200}, {200, 200}}), graphics = {
        Rectangle(extent = {{-40, 180}, {40, -160}}, lineColor = {80, 80, 80}, fillColor = {210, 210, 215}, fillPattern = FillPattern.VerticalCylinder),
        Polygon(points = {{-40, -160}, {40, -160}, {55, -190}, {-55, -190}}, lineColor = {80, 80, 80}, fillColor = {120, 120, 120}, fillPattern = FillPattern.Solid),
        Rectangle(extent = {{-60, 170}, {-40, 140}}, lineColor = {60, 60, 60}, fillColor = {90, 90, 90}, fillPattern = FillPattern.CrossDiag),
        Rectangle(extent = {{40, 170}, {60, 140}}, lineColor = {60, 60, 60}, fillColor = {90, 90, 90}, fillPattern = FillPattern.CrossDiag),
        Text(extent = {{-200, 240}, {200, 205}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-200, -200}, {200, 280}}), graphics = {Text(extent = {{-195, 278}, {195, 220}}, textString = "## Booster\nA free body (CapturableBody: held on the mount, then free) with its feed system and mass properties, three engine rings (EngineCluster: the core three and the inner ten gimballed, the outer twenty fixed), grid fins at the top, the body's aerodynamics, gravity, atmosphere and wind (FileTable), actuators on a battery bus, attitude control and the flight computer. While it carries the ship, the hot-staging ring (Attachment) holds it and the combined mass moves the centre of mass up.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>The first stage. Illustrative values, rounded from public estimates for a fully reusable heavy-lift booster; not any manufacturer's data.</p></html>"));
  end Booster;
  model ShipFlightComputer "The ship's flight: carried, hot staging, ascent to orbit, coast, deorbit, belly-first entry, belly-flop, flip and landing"
    parameter Integer phase_start = 0 "Phase at the start: 0 carried (a segment that starts later sets 3 or 5)";
    parameter Real azimuth(unit = "rad", displayUnit = "deg") = 1.5708 "Azimuth of the ascent, from north towards east";
    parameter Real tanTheta0 = 0.545 "Linear-tangent steering: tan of the elevation at separation";
    parameter Real tanRate(unit = "1/s") = 0.00185 "Linear-tangent steering: fall of the tangent per second";
    parameter Real energyTarget(unit = "J/kg") = -3.0298e7 "Orbital energy at cutoff (a 200 km circular orbit)";
    parameter Real releaseDelay(unit = "s") = 120 "From orbit insertion to the payload's release";
    parameter Real tDeorbit(unit = "s") = 3930 "Time of the deorbit burn";
    parameter Real dvDeorbit(unit = "m/s") = 80 "Velocity change of the deorbit burn";
    parameter Real throttleDeorbit = 1 "Throttle of the deorbit burn (on one engine)";
    parameter Real alphaEntry(unit = "rad", displayUnit = "deg") = 1.05 "Angle of attack in hypersonic entry (60 deg)";
    parameter Real alphaFlop(unit = "rad", displayUnit = "deg") = 1.57 "Angle of attack in the subsonic belly-flop (90 deg)";
    parameter Real kBank = 10 "Entry steering: bank per radian of the pad's bearing off the flight direction";
    parameter Real bankMax(unit = "rad", displayUnit = "deg") = 1.0 "Largest bank in entry";
    parameter Real machFlop = 0.7 "Below this Mach number the ship falls belly-first and glides towards the pad";
    parameter Real flopTiltMax(unit = "rad", displayUnit = "deg") = 0.35 "Largest nose-down or nose-up tilt of the belly-flop";
    parameter Real flopSpeedMax(unit = "m/s") = 20 "Belly-flop: fastest drift it asks for towards the aim point";
    parameter Real flopTurnRate(unit = "rad/s") = 0.1 "Belly-flop: fastest turn of its heading towards the line of the steering";
    parameter Real flipShift(unit = "m") = 120 "The flip's thrust pushes the ship along its heading: the belly-flop aims this far short of the pad";
    parameter Real flopKp(unit = "rad/m") = 0.001 "Belly-flop tilt per metre from the aim point";
    parameter Real flopKd(unit = "rad.s/m") = 0.012 "Belly-flop tilt per m/s of drift (the drift follows the tilt with the broadside drag's lag of some 8 s)";
    parameter Real t_flip(unit = "s") = 5 "Time the flip takes: the landing burn starts this much ahead of the stopping height";
    parameter Real flipThrottle = 0.4 "Throttle of the flip while the ship lies flat; the landing law takes over as it comes upright";
    parameter Real F_engine(unit = "N") = 2.65e6 "Full vacuum thrust of one sea-level engine";
    parameter Real A_engine(unit = "m2") = 1.5 "Its exit area";
    parameter Real upright = 0.9 "Cosine of the tilt above which the flip counts as done";
    parameter Real settledRate(unit = "rad/s") = 0.05 "Turn rate below which the flip counts as settled";
    parameter Real landingBandwidth = 2.5 "Attitude loops in the flip and landing, as a multiple of their bandwidth";
    parameter Real marginOne = 0.95 "Share of one engine's thrust the landing plans to brake with"; 
    parameter Real foreTrim[4](each unit = "rad") = {1.1, 1.1, 0.4, 0.4} "Neutral deflection of the forward flaps at the Mach numbers of the schedule";
    parameter Real aftTrim[4](each unit = "rad") = {0.3, 0.3, 0.9, 0.9} "Neutral deflection of the aft flaps";
    parameter Real h_feet(unit = "m") = 1 "Height of the ship frame above the pad when the feet touch (the burn aims half a metre lower, so it always meets the ground; the engine stops 0.2 m above it)";
    EquaForgeVC.Multibody.Interfaces.MotionInput vehicle "Motion of the ship" annotation(Placement(transformation(extent = {{-210, 150}, {-190, 170}})));
    EquaForgeVC.Multibody.Interfaces.MotionInput target "Motion of the landing pad" annotation(Placement(transformation(extent = {{-210, -170}, {-190, -150}})));
    EquaForgeVC.Interfaces.BooleanInput staging "The booster has cut off" annotation(Placement(transformation(extent = {{-220, 100}, {-180, 140}})));
    EquaForgeVC.Interfaces.BooleanInput attached "Still on the booster" annotation(Placement(transformation(extent = {{-220, 60}, {-180, 100}})));
    EquaForgeVC.Interfaces.RealInput energy(unit = "J/kg") "Orbital energy" annotation(Placement(transformation(extent = {{-220, 20}, {-180, 60}})));
    EquaForgeVC.Interfaces.RealInput accel(unit = "m/s2") "Specific force along the ship (IMU)" annotation(Placement(transformation(extent = {{-220, -20}, {-180, 20}})));
    EquaForgeVC.Interfaces.RealInput mass(unit = "kg") "Mass of the ship" annotation(Placement(transformation(extent = {{-220, -60}, {-180, -20}})));
    EquaForgeVC.Interfaces.RealInput p_amb(unit = "Pa") "Ambient pressure" annotation(Placement(transformation(extent = {{-220, -100}, {-180, -60}})));
    EquaForgeVC.Interfaces.BooleanInput onLegs "The legs carry load: touchdown" annotation(Placement(transformation(extent = {{-220, -230}, {-180, -190}})));
    EquaForgeVC.Interfaces.RealInput Mach "Mach number" annotation(Placement(transformation(extent = {{-220, -140}, {-180, -100}})));
    EquaForgeVC.Interfaces.RealOutput direction[3] "Where the nose should point" annotation(Placement(transformation(extent = {{200, 150}, {220, 170}})));
    EquaForgeVC.Interfaces.RealOutput rollReference[3] "Where the belly should point" annotation(Placement(transformation(extent = {{200, 110}, {220, 130}})));
    EquaForgeVC.Interfaces.RealOutput throttleSL "Throttle of the sea-level engines" annotation(Placement(transformation(extent = {{200, 60}, {220, 80}})));
    EquaForgeVC.Interfaces.RealOutput throttleVac "Throttle of the vacuum engines" annotation(Placement(transformation(extent = {{200, 20}, {220, 40}})));
    EquaForgeVC.Interfaces.BooleanOutput pairOn "The pair of sea-level engines running" annotation(Placement(transformation(extent = {{200, 0}, {220, 20}})));
    EquaForgeVC.Interfaces.BooleanOutput slOn "The landing engine running" annotation(Placement(transformation(extent = {{200, -20}, {220, 0}})));
    EquaForgeVC.Interfaces.BooleanOutput vacOn "Vacuum engines running" annotation(Placement(transformation(extent = {{200, -60}, {220, -40}})));
    EquaForgeVC.Interfaces.BooleanOutput flapsActive "Flaps steering" annotation(Placement(transformation(extent = {{200, -100}, {220, -80}})));
    EquaForgeVC.Interfaces.RealOutput h(unit = "m") "Height above the landing pad" annotation(Placement(transformation(extent = {{200, -140}, {220, -120}})));
    EquaForgeVC.Interfaces.BooleanOutput release "Release the payload" annotation(Placement(transformation(extent = {{200, -180}, {220, -160}})));
    EquaForgeVC.Interfaces.RealOutput flapTrim[4](each unit = "rad") "Neutral flap deflections: trim for the angle of attack of the schedule" annotation(Placement(transformation(extent = {{200, 220}, {220, 240}})));
    EquaForgeVC.Interfaces.RealOutput bandwidth "Bandwidth multiple of the attitude loops" annotation(Placement(transformation(extent = {{200, 190}, {220, 210}})));
    EquaForgeVC.Interfaces.BooleanOutput headerFeed "The engines draw from the header tanks" annotation(Placement(transformation(extent = {{200, -220}, {220, -200}})));
    Real Rv[3, 3] "The ship's orientation: while it is carried and once it has landed it holds it, so its controllers rest";
    Real headingError(unit = "rad", displayUnit = "deg") "Bearing of the pad off the flight direction, positive to the right";
    Real crossRange(unit = "m") "Distance of the pad off the flight direction";
    Real rangeToGo(unit = "m") "Distance of the pad ahead along the flight direction";
    Real engines "Sea-level engines running in the landing burn";
    Real upShare "How far the flip has come: 0 flat, 1 upright";
    Real flopTilt(unit = "rad", displayUnit = "deg") "Nose-down tilt of the belly-flop: glides along its heading";
    Real a_flop[3](each unit = "m/s2") "Horizontal acceleration the belly-flop steers for: towards its aim point, against the drift";
    Real flopHeading(unit = "rad", displayUnit = "deg") "Heading of the belly-flop's axis, from east towards north";
  protected
    Real up[3], east[3], v_rel[3], e_v[3], e_h[3], right[3], d_h[3], dr_h[3], dv_h[3], h0[3], n_h[3], x_b[3], nose_h[3];
    Real a_e(unit = "m/s2"), a_n(unit = "m/s2") "The steering, east and north";
    Real v_flop[3](each unit = "m/s") "Drift the belly-flop asks for: towards its aim point, at most flopSpeedMax";
    Real flopDirection[3] "Nose direction of the belly-flop";
    Real a_along(unit = "m/s2") "Acceleration along the heading that nulls offset and drift at the flip";
  public
    EquaForgeVC.Logical.ModeSequencer flight(n = 8, phase_start = phase_start) "0 carried, 1 hot staging, 2 ascent, 3 coast, 4 deorbit burn, 5 entry, 6 belly-flop, 7 flip and landing burn, 8 landed" annotation(Placement(transformation(origin = {40, 0}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeVC.Logical.Not released annotation(Placement(transformation(origin = {-140, 80}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Logical.Greater orbit "Cutoff: the orbital energy is reached" annotation(Placement(transformation(origin = {-140, 40}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Constant targetEnergy(k = energyTarget) annotation(Placement(transformation(origin = {-170, 20}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeVC.Logical.GreaterThreshold deorbitTime(threshold = tDeorbit) annotation(Placement(transformation(origin = {-140, 0}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Clock missionTime annotation(Placement(transformation(origin = {-170, -10}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeVC.Blocks.Integrator deltaV "Velocity change of the deorbit burn" annotation(Placement(transformation(origin = {-140, -40}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.GreaterThreshold burnDone(threshold = dvDeorbit) annotation(Placement(transformation(origin = {-110, -40}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.LessThreshold subsonic(threshold = machFlop) "Into the belly-flop" annotation(Placement(transformation(origin = {-110, -70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.Greater flipNow "Stopping height plus the drop during the flip reach the height" annotation(Placement(transformation(origin = {-110, -100}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Logical.LessThreshold touchdown(threshold = h_feet + 0.2) annotation(Placement(transformation(origin = {-110, -130}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Atan2 elevation "Elevation from its tangent" annotation(Placement(transformation(origin = {-70, 140}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Constant launchAzimuth(k = azimuth) annotation(Placement(transformation(origin = {-70, 110}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeAerospace.GNC.LocalDirection ascent annotation(Placement(transformation(origin = {-30, 130}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.VelocityDirection retrograde(inertial = true, retrograde = true) annotation(Placement(transformation(origin = {50, 160}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Table1D alphaSchedule(x = {0, 0.8, 2, 30}, values = {alphaFlop, alphaFlop, alphaEntry, alphaEntry}) "Angle of attack against Mach number" annotation(Placement(transformation(origin = {-70, 70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Table1D foreSchedule(x = {0, 0.8, 2, 30}, values = foreTrim) "Forward flaps open wide for the belly-flop" annotation(Placement(transformation(origin = {130, 90}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Table1D aftSchedule(x = {0, 0.8, 2, 30}, values = aftTrim) "Aft flaps open wide for hypersonic trim" annotation(Placement(transformation(origin = {130, 60}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.Gain bankGain(k = kBank) "Bank towards the pad" annotation(Placement(transformation(origin = {-90, 45}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeVC.Blocks.Limiter bankLimit(uMax = bankMax, generateEvent = false) annotation(Placement(transformation(origin = {-65, 45}, extent = {{-5, -5}, {5, 5}})));
    EquaForgeAerospace.GNC.EntryAttitude entry annotation(Placement(transformation(origin = {-30, 70}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.LocalDirection north annotation(Placement(transformation(origin = {90, 130}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Logical.SRLatch singleEngine "Upright, settled and slow enough for one engine: land on it" annotation(Placement(transformation(origin = {-70, -130}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.GNC.PoweredDescent landing(h_target = h_feet - 0.5, v_touch = 1.5, margin = 0.85, tiltMax = 0.2, h_upright = 3, timeToGo = false, k_p = 0.02, k_d = 0.35, v_lateralMax = 3, h_hold = 250, usePlanInput = true) annotation(Placement(transformation(origin = {-30, -150}, extent = {{-12, -12}, {12, 12}})));
  equation
    connect(attached, released.u);
    flight.advance[1] = staging;
    connect(released.y, flight.advance[2]);
    connect(energy, orbit.u1);
    connect(targetEnergy.y, orbit.u2);
    connect(orbit.y, flight.advance[3]);
    connect(missionTime.y, deorbitTime.u);
    connect(deorbitTime.y, flight.advance[4]);
    deltaV.u = if flight.phase == 4 then abs(accel) else 0;
    connect(deltaV.y, burnDone.u);
    connect(burnDone.y, flight.advance[5]);
    connect(Mach, subsonic.u);
    connect(subsonic.y, flight.advance[6]);
    flipNow.u1 = landing.stoppingHeight + t_flip*landing.sinkRate;
    flipNow.u2 = h - h_feet;
    connect(flipNow.y, flight.advance[7]);
    connect(h, touchdown.u);
    flight.advance[8] = onLegs or touchdown.y;
    // linear-tangent ascent: tan(elevation) = tanTheta0 - tanRate (t - t_separation)
    elevation.u1 = tanTheta0 + (if flight.phase == 2 then -tanRate*flight.phaseTime else 0);
    elevation.u2 = 1;
    connect(vehicle, ascent.vehicle);
    connect(elevation.y, ascent.elevation);
    connect(launchAzimuth.y, ascent.azimuth);
    connect(vehicle, retrograde.vehicle);
    // where the pad is, seen from the flight direction (Earth-relative)
    up = vehicle.r/sqrt(vehicle.r*vehicle.r);
    east = cross(north.d, up);
    v_rel = vehicle.v - cross({0, 0, EquaForgeAerospace.omegaEarth}, vehicle.r);
    e_h = (v_rel - (v_rel*up)*up)/noEvent(max(sqrt((v_rel - (v_rel*up)*up)*(v_rel - (v_rel*up)*up)), 1e-3));
    right = cross(e_h, up);
    d_h = (target.r - vehicle.r) - ((target.r - vehicle.r)*up)*up;
    headingError = atan2(d_h*right, d_h*e_h);
    crossRange = d_h*right;
    rangeToGo = d_h*e_h;
    // entry: angle of attack from the schedule, bank towards the pad
    connect(vehicle, entry.vehicle);
    connect(Mach, alphaSchedule.u);
    connect(alphaSchedule.y, entry.alpha);
    connect(Mach, foreSchedule.u);
    connect(Mach, aftSchedule.u);
    flapTrim = {foreSchedule.y, foreSchedule.y, aftSchedule.y, aftSchedule.y};
    // the heading of a steepening fall means little: the bank fades out from Mach 2 to Mach 1
    bankGain.u = headingError*noEvent(min(1, max(0, Mach - 1)));
    connect(bankGain.y, bankLimit.u);
    connect(bankLimit.y, entry.bank);
    // belly-flop: the air's force leans along the heading when the nose tilts towards the airflow, so the ship
    // turns its heading (thrusters) towards the line of the steering it needs, and tilts along it
    x_b = {Rv[1, 1], Rv[1, 2], Rv[1, 3]};
    nose_h = (x_b - (x_b*up)*up)/noEvent(max(sqrt((x_b - (x_b*up)*up)*(x_b - (x_b*up)*up)), 1e-6));
    dr_h = (vehicle.r - target.r) - ((vehicle.r - target.r)*up)*up;
    dv_h = (vehicle.v - target.v) - ((vehicle.v - target.v)*up)*up;
    // a speed command from the offset, no faster than the flop can glide, and its tracking
    v_flop = -flopKp/flopKd*(dr_h + flipShift*h0)*noEvent(min(1, flopSpeedMax/max(flopKp/flopKd*sqrt((dr_h + flipShift*h0)*(dr_h + flipShift*h0)), 1e-9)));
    a_flop = -EquaForgeAerospace.g0*flopKd*(dv_h - v_flop);
    a_e = a_flop*east;
    a_n = a_flop*north.d;
    // the axis pushes either way along its line, so the heading turns towards the nearer end of the steering's
    // line: in doubled angles both ends are stable and nothing jumps; it enters with the flight direction
  initial equation
    flopHeading = atan2(v_rel*north.d, v_rel*east);
  equation
    when flight.phase == 6 then
      reinit(flopHeading, atan2(v_rel*north.d, v_rel*east));
    end when;
    der(flopHeading) = if flight.phase == 6 then flopTurnRate*(2*a_e*a_n*cos(2*flopHeading) - (a_e^2 - a_n^2)*sin(2*flopHeading))/(a_e^2 + a_n^2 + 0.25) else 0;
    h0 = cos(flopHeading)*east + sin(flopHeading)*north.d;
    a_along = a_flop*h0;
    flopTilt = noEvent(max(-flopTiltMax, min(flopTiltMax, a_along/EquaForgeAerospace.g0)));
    e_v = v_rel/noEvent(max(sqrt(v_rel*v_rel), 1e-3));
    n_h = (h0 - (h0*e_v)*e_v)/noEvent(max(sqrt((h0 - (h0*e_v)*e_v)*(h0 - (h0*e_v)*e_v)), 1e-6));
    flopDirection = sin(flopTilt)*e_v + cos(flopTilt)*n_h;
    connect(vehicle, north.vehicle);
    north.elevation = 0;
    north.azimuth = 0;
    // landing
    connect(vehicle, landing.vehicle);
    connect(target, landing.target);
    // radial height difference: right over the pad and far from it alike
    h = sqrt(vehicle.r*vehicle.r) - sqrt(target.r*target.r);
    landing.h = h;
    // three engines flip the ship; upright and with the sink rate on the profile one engine can fly (aPlan), the pair shuts down
    engines = if singleEngine.y then 1 else 3;
    landing.aMax = engines*(F_engine - A_engine*p_amb)/mass;
    landing.aPlan = marginOne*(F_engine - A_engine*p_amb)/mass - EquaForgeAerospace.g0;
    singleEngine.set = flight.phase == 7 and Rv[1, :]*up > upright and vehicle.w[2]^2 + vehicle.w[3]^2 < settledRate^2 and landing.sinkRate < landing.v_ref;
    singleEngine.reset = false;
    // what each phase steers by
    Rv = EquaForgeVC.Multibody.Frames.fromQ(vehicle.Q);
    direction = if flight.phase <= 1 or flight.phase == 8 then {Rv[1, 1], Rv[1, 2], Rv[1, 3]} elseif flight.phase == 2 then ascent.d elseif flight.phase == 3 or flight.phase == 4 then retrograde.d elseif flight.phase == 5 then entry.direction elseif flight.phase == 6 then flopDirection else landing.direction;
    rollReference = if flight.phase <= 1 or flight.phase >= 7 then {Rv[2, 1], Rv[2, 2], Rv[2, 3]} elseif flight.phase == 5 then entry.rollReference elseif flight.phase == 6 then e_v else cross(north.d, direction);
    upShare = noEvent(min(1, max(0, Rv[1, :]*up/upright)));
    throttleSL = if flight.phase == 7 then upShare*landing.throttle + (1 - upShare)*flipThrottle elseif flight.phase == 4 then throttleDeorbit else 1;
    throttleVac = 1;
    slOn = flight.phase == 1 or flight.phase == 2 or flight.phase == 4 or flight.phase == 7;
    pairOn = flight.phase == 1 or flight.phase == 2 or flight.phase == 7 and not singleEngine.y;
    vacOn = flight.phase == 1 or flight.phase == 2;
    // the flaps' gains hold while the air meets the belly: entry, belly-flop and the start of the flip
    flapsActive = flight.phase == 5 or flight.phase == 6 or flight.phase == 7 and upShare < 0.5;
    release = flight.phase >= 4 or flight.phase == 3 and flight.phaseTime > releaseDelay;
    headerFeed = flight.phase >= 5;
    bandwidth = if flight.phase == 7 then landingBandwidth else 1;
    annotation(Icon(graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127}, fillColor = {240, 240, 255}, fillPattern = FillPattern.Solid),
        Text(extent = {{-90, 40}, {90, -40}}, textString = "FC"),
        Text(extent = {{-150, 140}, {150, 110}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-200, -240}, {200, 260}}), graphics = {Text(extent = {{-195, 258}, {195, 195}}, textString = "## Ship flight computer\nThe ship lights its engines when the booster cuts off and flies a linear-tangent ascent (Atan2, LocalDirection) until its orbital energy reaches the target (Greater). It releases the payload, coasts retrograde and burns at the deorbit time until the integrated velocity change (Integrator) is enough. It enters belly-first at the angle of attack of its schedule (Table1D against Mach, EntryAttitude), banking towards the pad (Gain, Limiter). Subsonic, it falls belly-first, turning its heading towards the steering it needs and tilting along it to arrive over the pad; it flips on three engines when the landing burn's stopping height is near, and lands on one (SRLatch) with PoweredDescent.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}));
  end ShipFlightComputer;
  model HeatShield "The ship's heat shield: entry heating into the tiles, radiation to the sky, conduction into the structure"
    parameter Real area(unit = "m2") = 700 "Area of the tiled belly";
    parameter Real noseRadius(unit = "m") = 4.5 "Effective radius the flow meets";
    parameter Real C_tiles(unit = "J/K") = 1.2e7 "Heat capacity of the tiles";
    parameter Real emissivity = 0.85 "Emissivity of the tiles";
    parameter Real G_bond(unit = "W/K") = 2000 "Conductance from the tiles into the steel";
    parameter Real C_structure(unit = "J/K") = 1.5e8 "Heat capacity of the steel behind them";
    EquaForgeVC.Interfaces.RealInput rho(unit = "kg/m3") "Air density" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
    EquaForgeVC.Interfaces.RealInput V(unit = "m/s") "Airspeed" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
    EquaForgeVC.Interfaces.RealOutput T(unit = "K") "Temperature of the tiles" annotation(Placement(transformation(extent = {{100, 30}, {120, 50}})));
    EquaForgeVC.Interfaces.RealOutput rgb[3] "Glow colour of the tiles" annotation(Placement(transformation(extent = {{100, -50}, {120, -30}})));
    EquaForgeAerospace.Thermal.StagnationHeating heating(noseRadius = noseRadius, area = area, shapeFactor = 0.35) annotation(Placement(transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Thermal.PrescribedHeatFlow heatIn annotation(Placement(transformation(origin = {-30, 0}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Thermal.HeatCapacitor tiles(C = C_tiles, T_start = 250) annotation(Placement(transformation(origin = {0, 20}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Thermal.BodyRadiation radiation(Gr = emissivity*area) annotation(Placement(transformation(origin = {30, 40}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Thermal.FixedTemperature sky(T = 250) annotation(Placement(transformation(origin = {60, 40}, extent = {{-8, -8}, {8, 8}}, rotation = 180)));
    EquaForgeVC.Thermal.ThermalConductor bond(G = G_bond) annotation(Placement(transformation(origin = {30, -20}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Thermal.HeatCapacitor structure(C = C_structure, T_start = 280) annotation(Placement(transformation(origin = {60, -10}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Thermal.TemperatureSensor tileT annotation(Placement(transformation(origin = {30, 0}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Visualization.TemperatureColor glow(Tcold = 500, Thot = 1700) annotation(Placement(transformation(origin = {70, -40}, extent = {{-8, -8}, {8, 8}})));
  equation
    connect(rho, heating.rho);
    connect(V, heating.V);
    connect(heating.Q_flow, heatIn.Q_flow);
    connect(heatIn.port, tiles.port);
    connect(tiles.port, radiation.port_a);
    connect(radiation.port_b, sky.port);
    connect(tiles.port, bond.port_a);
    connect(bond.port_b, structure.port);
    connect(tiles.port, tileT.port);
    connect(tileT.T, T);
    connect(tileT.T, glow.T);
    connect(glow.rgb, rgb);
    annotation(Icon(graphics = {
        Rectangle(extent = {{-80, 20}, {80, -20}}, lineColor = {40, 40, 40}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid),
        Line(points = {{-60, 80}, {-40, 25}}, color = {230, 80, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
        Line(points = {{0, 80}, {0, 25}}, color = {230, 80, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
        Line(points = {{60, 80}, {40, 25}}, color = {230, 80, 0}, thickness = 0.5, arrow = {Arrow.None, Arrow.Filled}),
        Text(extent = {{-150, -40}, {150, -70}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-100, -60}, {100, 100}}), graphics = {Text(extent = {{-95, 98}, {95, 62}}, textString = "## Heat shield\nThe Sutton-Graves flux of entry heats the tiles (PrescribedHeatFlow into a HeatCapacitor); they radiate it to the sky (BodyRadiation) and pass a little into the steel (ThermalConductor). The tiles' temperature sets their glow in the 3-D view.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}));
  end HeatShield;

  model LandingLegs "Four legs: feet on rigid offsets, each with a contact on the ground plane"
    parameter Real footRadius(unit = "m") = 6 "Distance of the feet from the axis (the legs splay out beyond the skirt)";
    parameter Real footX(unit = "m") = -1 "Feet below the vehicle frame along x";
    parameter Real c(unit = "N/m") = 2e7 "Stiffness of each leg";
    parameter Real d(unit = "N.s/m") = 3e6 "Damping of each leg";
    parameter Real padRadius(unit = "m") = 40 "How far the ground plane reaches from the pad's centre (within some tens of kilometres it stays close to the curved ground)";
    parameter Real groundDepth(unit = "m") = 100 "Deepest a foot may be below the ground plane and still touch it (deeper is the far side of the Earth)";
    parameter Real mu = 0.3 "Friction of the feet on the pad";
    EquaForgeVC.Multibody.Interfaces.Frame_a vehicle "The vehicle's frame" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
    EquaForgeVC.Multibody.Interfaces.Frame_a ground "The pad: x up" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBodyFrame foot[4](r = {{footX, footRadius, 0}, {footX, 0, footRadius}, {footX, -footRadius, 0}, {footX, 0, -footRadius}}) annotation(Placement(transformation(origin = {40, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    EquaForgeVC.Multibody.ForcesAndMoments.Contact leg[4](each n = {1, 0, 0}, each c = c, each d = d, each d_t = d, each mu = mu, each extent = padRadius, each depth = groundDepth) annotation(Placement(transformation(origin = {-30, 0}, extent = {{-10, -10}, {10, 10}})));
    Real load(unit = "N") "Weight the legs carry";
  equation
    for k in 1:4 loop
      connect(vehicle, foot[k].frame_a);
      connect(foot[k].frame_b, leg[k].frame_b);
      connect(ground, leg[k].frame_a);
    end for;
    load = sum(leg[k].f_n for k in 1:4);
    annotation(Diagram(graphics = {Text(extent = {{-90, 92}, {90, 30}}, textString = "## Landing legs\nFour feet on rigid offsets from the vehicle's frame (RigidBodyFrame), each pressing on the pad's ground plane through a Contact: a spring and damper that only push, with friction. They are joined in a loop over the four legs; load is what they carry together.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Icon(graphics = {
        Line(points = {{-60, -60}, {-20, 40}}, color = {64, 64, 64}, thickness = 1),
        Line(points = {{60, -60}, {20, 40}}, color = {64, 64, 64}, thickness = 1),
        Line(points = {{-80, -60}, {80, -60}}, color = {120, 120, 120}),
        Text(extent = {{-150, 90}, {150, 60}}, textString = "%name")}));
  end LandingLegs;

  model Payload "Payload in the ship's bay: carried to orbit and released there"
    parameter Real m(unit = "kg") = 1e5 "Mass of the payload";
    parameter Real r_CM[3](each unit = "m") = {38, 0, 0} "Its centre of mass, ship frame";
    parameter Real I[3](each unit = "kg.m2") = {6e5, 1.5e6, 1.5e6} "Its inertia about its centre of mass";
    EquaForgeVC.Interfaces.BooleanInput release "Released: from now on the ship flies without it" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
    EquaForgeVC.Multibody.Interfaces.MassPropertiesOutput mass "What the ship still carries" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
    Real share "1 while on board, 0 once released";
  equation
    share = if release then 0 else 1;
    mass.m = 1 + share*m;
    mass.r_CM = r_CM;
    mass.I = share*{I[1], I[2], I[3], 0, 0, 0};
    annotation(Icon(graphics = {
        Rectangle(extent = {{-60, 50}, {60, -50}}, lineColor = {80, 80, 80}, fillColor = {235, 210, 120}, fillPattern = FillPattern.Solid),
        Line(points = {{-60, 50}, {60, -50}}, color = {80, 80, 80}),
        Line(points = {{-60, -50}, {60, 50}}, color = {80, 80, 80}),
        Text(extent = {{-150, 100}, {150, 70}}, textString = "%name")}),
      Diagram(graphics = {Text(extent = {{-90, 92}, {90, 30}}, textString = "## Payload\nMass properties written as equations: the payload's mass and inertia, about its centre of mass in the ship frame, drop out of the output when release turns true (share 1, then 0).", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>The payload as mass properties that drop out when it is released. Its own flight after release is not modelled.</p></html>"));
  end Payload;

  model ShipLook "The ship in the 3-D view: hull and nose, the heat shield glowing with its temperature, the flaps as they move, the legs and the plume of its engines"
    parameter Real trail(unit = "s") = 1500 "Path drawn behind the hull: the whole ascent, or the whole descent from the entry interface (a longer one, round the Earth, would stretch the 3-D view's depth until the pads merge with the ground)";
    parameter Real F_full(unit = "N") = 1.5e7 "Thrust at which the plume is drawn its brightest";
    EquaForgeVC.Multibody.Interfaces.Frame_a frame_a "The ship's frame: at its engine gimbals, x towards the nose, y towards the belly" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
    EquaForgeVC.Interfaces.RealInput thrust(unit = "N") "Thrust of all its engines" annotation(Placement(transformation(origin = {-60, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealInput flapAngle[4](each unit = "rad", each displayUnit = "deg") "Flap deflections: forward left, forward right, aft left, aft right (0 folded, pi/2 open)" annotation(Placement(transformation(origin = {0, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.RealInput tileColor[3] "Colour of the heat shield, RGB 0..255" annotation(Placement(transformation(origin = {60, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.BooleanInput legsOut "The legs are deployed (for the landing)" annotation(Placement(transformation(origin = {120, 0}, extent = {{20, -20}, {-20, 20}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape hull(shapeType = EquaForgeVC.Visualization.ShapeType.Cylinder, length = 41, width = 9, position = {20.5, 0, 0}, color = {215, 215, 220}, trail = trail) "Stainless steel, 41 m to the nose" annotation(Placement(transformation(origin = {-40, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape nose(shapeType = EquaForgeVC.Visualization.ShapeType.Cone, length = 9, width = 9, position = {45.5, 0, 0}, color = {215, 215, 220}) "The nose cone" annotation(Placement(transformation(origin = {0, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape tiles(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 41, width = 0.4, height = 7, position = {20.5, 4.6, 0}, useColorInput = true) "The heat shield on the belly (+y), glowing with its temperature" annotation(Placement(transformation(origin = {40, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape flap[4](each shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = {5, 5, 8, 8}, width = {3, 3, 4, 4}, each height = 0.4, position = {{45, -1.5, 3}, {45, -1.5, -3}, {4.5, -2, 4.5}, {4.5, -2, -4.5}}, each color = {45, 45, 50}, each useAngleInput = true, hingeAxis = {{-1, 0, 0}, {1, 0, 0}, {-1, 0, 0}, {1, 0, 0}}, hingePoint = {{45, 0, 3}, {45, 0, -3}, {4.5, 0, 4.5}, {4.5, 0, -4.5}}) "Flaps hinged along the sides: folded towards the back at 0, standing out at pi/2" annotation(Placement(transformation(origin = {-40, 5}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape leg[4](each shapeType = EquaForgeVC.Visualization.ShapeType.Box, each length = 5.25, each width = 0.6, each height = 0.6, lengthDirection = {{-5, 1.6, 0}, {-5, 0, 1.6}, {-5, -1.6, 0}, {-5, 0, -1.6}}, widthDirection = {{0, 0, 1}, {0, 1, 0}, {0, 0, 1}, {0, 1, 0}}, position = {{1.5, 5.2, 0}, {1.5, 0, 5.2}, {1.5, -5.2, 0}, {1.5, 0, -5.2}}, each color = {90, 90, 96}, each useOpacityInput = true) "Legs out to the feet, 6 m from the axis: shown once deployed" annotation(Placement(transformation(origin = {0, 5}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape plume(shapeType = EquaForgeVC.Visualization.ShapeType.Cone, length = 30, width = 9, position = {-15, 0, 0}, color = {255, 175, 70}, useOpacityInput = true) "Exhaust: the tip at the engines, shown while they burn" annotation(Placement(transformation(origin = {40, 5}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(frame_a, hull.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {-54, 30}, {-54, 45}, {-50, 45}}, color = {95, 95, 95}));
    connect(frame_a, nose.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {-14, 30}, {-14, 45}, {-10, 45}}, color = {95, 95, 95}));
    connect(frame_a, tiles.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {26, 30}, {26, 45}, {30, 45}}, color = {95, 95, 95}));
    connect(tileColor, tiles.colorIn) annotation(Line(points = {{60, -100}, {60, 65}, {40, 65}, {40, 57}}, color = {0, 0, 127}));
    connect(frame_a, plume.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {26, -10}, {26, 5}, {30, 5}}, color = {95, 95, 95}));
    for k in 1:4 loop
      connect(frame_a, flap[k].frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {-54, -10}, {-54, 5}, {-50, 5}}, color = {95, 95, 95}));
      connect(flapAngle[k], flap[k].angleIn) annotation(Line(points = {{0, -100}, {0, -25}, {-46, -25}, {-46, -7}}, color = {0, 0, 127}));
      connect(frame_a, leg[k].frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {-14, -10}, {-14, 5}, {-10, 5}}, color = {95, 95, 95}));
      leg[k].opacityIn = if legsOut then 1 else 0;
    end for;
    plume.opacityIn = noEvent(if thrust > 1e4 then 0.4 + 0.45*min(1, thrust/F_full) else 0);
    annotation(Icon(graphics = {
        Rectangle(extent = {{-25, 50}, {25, -60}}, lineColor = {80, 80, 80}, fillColor = {220, 220, 225}, fillPattern = FillPattern.VerticalCylinder),
        Polygon(points = {{-25, 50}, {0, 90}, {25, 50}}, lineColor = {80, 80, 80}, fillColor = {220, 220, 225}, fillPattern = FillPattern.Solid),
        Rectangle(extent = {{25, 50}, {15, -60}}, lineColor = {30, 30, 30}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid),
        Polygon(points = {{-20, -60}, {20, -60}, {30, -95}, {-30, -95}}, lineColor = {230, 140, 40}, fillColor = {255, 180, 70}, fillPattern = FillPattern.Solid),
        Text(extent = {{-150, 130}, {150, 95}}, textString = "%name")}),
      Diagram(graphics = {Text(extent = {{-95, 98}, {95, 72}}, textString = "## Ship in 3-D\nShapes only (AttachedShape): they put no load on the ship. The flaps turn with their actuators (angle input), the tiles take the heat shield's colour (colour input), the plume shows while the engines burn (opacity input).", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>What the 3-D view draws of the ship, about its frame at the engine gimbals (x towards the nose, y towards the belly): a 9 m hull 41 m long under a 9 m nose cone, the heat shield on the belly in the colour of its temperature, four flaps hinged along the sides that turn with their actuators (folded towards the back, standing out when open), four legs once they are deployed for the landing (<b>legsOut</b>) and a plume below the engines that shows while they burn. Belly-first, the dark shield faces the ground and the flaps stand out into the flow.</p></html>"));
  end ShipLook;

  model Ship "StarVessel upper stage: feed system, sea-level and vacuum engines, flaps, heat shield, legs, attitude control and flight computer"
    parameter Integer phase_start = 0 "Phase of the flight computer at the start";
    parameter Real r_start[3](each unit = "m") = zeros(3) "Position of the ship frame at the start, world";
    parameter Real v_start[3](each unit = "m/s") = zeros(3) "Velocity at the start, world";
    parameter Real Q_start[4] = {0, 0, 0, 1} "Orientation at the start";
    parameter Real w_start[3](each unit = "rad/s") = zeros(3) "Angular velocity at the start, ship frame";
    parameter Real m_lox(unit = "kg") = 1.151e6 "Liquid oxygen loaded in the main tank";
    parameter Real m_ch4(unit = "kg") = 3.18e5 "Liquid methane loaded in the main tank";
    parameter Real m_headerLox(unit = "kg") = 2.05e4 "Liquid oxygen in the header tank (for the landing)";
    parameter Real m_headerCh4(unit = "kg") = 5.7e3 "Liquid methane in the header tank";
    parameter Real m_payload(unit = "kg") = 1e5 "Payload carried to orbit";
    parameter Real residualLox(unit = "kg") = 2e-3*m_lox "Oxygen the main tank cannot give (a segment that starts with a part load keeps the full load's)";
    parameter Real residualCh4(unit = "kg") = 2e-3*m_ch4 "Methane the main tank cannot give";
    parameter Real residualHeaderLox(unit = "kg") = 2e-3*m_headerLox "Oxygen the header tank cannot give";
    parameter Real residualHeaderCh4(unit = "kg") = 2e-3*m_headerCh4 "Methane the header tank cannot give";
    parameter Real tDeorbit(unit = "s") = 3930 "Time of the deorbit burn";
    parameter Real dvDeorbit(unit = "m/s") = 80 "Velocity change of the deorbit burn";
    parameter Real tanTheta0 = 0.545 "Ascent steering: tan of the elevation at separation";
    parameter Real tanRate(unit = "1/s") = 0.00185 "Ascent steering: fall of the tangent per second";
    parameter Real latPad(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the landing pad";
    parameter Real lonPad(unit = "rad", displayUnit = "deg") = -1.69575 "Longitude of the landing pad";
    EquaForgeVC.Multibody.Interfaces.Frame_b frame_a "The ship's frame (at its engine gimbals)" annotation(Placement(transformation(extent = {{-210, -10}, {-190, 10}})));
    EquaForgeVC.Multibody.Interfaces.MotionInput carrier "Where the ship is held while carried" annotation(Placement(transformation(origin = {-160, -210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Interfaces.BooleanInput attach "Carried by the booster" annotation(Placement(transformation(origin = {-120, -220}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Multibody.Interfaces.LoadOutput load "Loads the booster takes while it carries the ship" annotation(Placement(transformation(origin = {-80, -210}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    EquaForgeVC.Multibody.Interfaces.MassPropertiesOutput mass "The ship with its propellant" annotation(Placement(transformation(origin = {-40, -210}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    EquaForgeVC.Interfaces.BooleanInput staging "The booster has cut off: light the engines" annotation(Placement(transformation(origin = {0, -220}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Interfaces.BooleanOutput landed "Standing on its legs" annotation(Placement(transformation(extent = {{200, 110}, {220, 130}})));
    EquaForgeVC.Multibody.Interfaces.MotionOutput motion "Motion of the ship frame" annotation(Placement(transformation(extent = {{200, 150}, {220, 170}})));
    EquaForgeVC.Multibody.Interfaces.MotionInput padTarget "Motion of the landing pad" annotation(Placement(transformation(origin = {80, -210}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Multibody.Interfaces.Frame_a pad "The landing pad's frame (x up): the legs stand on it" annotation(Placement(transformation(origin = {140, -200}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Multibody.BodiesAndFrames.CapturableBody body(r_start = r_start, v_start = v_start, Q_start = Q_start, w_start = w_start, r_nominal = 6.4e6, v_nominal = 2e3) annotation(Placement(transformation(origin = {-120, 0}, extent = {{-14, -14}, {14, 14}})));
    FeedSystem feed(m_dry = 1.4e5, r_CM_dry = {23, 0, 0}, I_dry = {4e6, 3e7, 3e7}, m_lox = m_lox, lox_bottom = 2, lox_length = 17, m_ch4 = m_ch4, ch4_bottom = 20, ch4_length = 13, kPress = 1e-3, T_ambient = 250, hA = 1e3, lox_residual = residualLox, ch4_residual = residualCh4) annotation(Placement(transformation(origin = {-120, -100}, extent = {{-14, -14}, {14, 14}})));
    FeedSystem header(m_dry = 100, r_CM_dry = {40, 0, 0}, I_dry = {10, 10, 10}, radius = 1.6, m_lox = m_headerLox, lox_bottom = 36, lox_length = 3.5, m_ch4 = m_headerCh4, ch4_bottom = 42, ch4_length = 3.5, kPress = 1e-4, T_ambient = 250, hA = 200, lox_residual = residualHeaderLox, ch4_residual = residualHeaderCh4) "Header tanks in the nose: the landing propellant" annotation(Placement(transformation(origin = {-120, -150}, extent = {{-12, -12}, {12, 12}})));
    Payload payload(m = m_payload) annotation(Placement(transformation(origin = {-80, -150}, extent = {{-8, -8}, {8, 8}})));
    Boolean dry "The tanks feeding the sea-level engines have run dry";
    EquaForgeVC.Multibody.BodiesAndFrames.MassSum3 shipMass "Structure and main tanks, header tanks, payload" annotation(Placement(transformation(origin = {-80, -110}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Propulsion.EngineCluster slOne(N = 1, ringRadius = 0) "The sea-level engine that lands the ship (lumped on the axis), gimballed" annotation(Placement(transformation(origin = {-160, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    EquaForgeAerospace.Propulsion.EngineCluster slPair(N = 2, ringRadius = 1.4) "The other two sea-level engines, gimballed: off for the deorbit burn and the last of the landing" annotation(Placement(transformation(origin = {-160, -70}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    EquaForgeAerospace.Propulsion.EngineCluster vacRing(N = 3, ringRadius = 3.3, F_vac = 2.75e6, Isp_vac = 375, A_e = 4.5, pe_ratio = 3e-4) "Vacuum engines, fixed" annotation(Placement(transformation(origin = {-160, 50}, extent = {{-12, -12}, {12, 12}}, rotation = 180)));
    EquaForgeVC.Blocks.Add oxygen annotation(Placement(transformation(origin = {-170, -100}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeVC.Blocks.Add methane annotation(Placement(transformation(origin = {-170, -130}, extent = {{-6, -6}, {6, 6}})));
    ActuatorSet gimbals(n = 2, ratio = 200, J_load = 1.1e4, angleMax = 0.26, Imax = 200) annotation(Placement(transformation(origin = {-80, -50}, extent = {{-10, -10}, {10, 10}})));
    ActuatorSet flapDrives(n = 4, ratio = 300, J_load = 2e4, angleMax = 1.5, angleMin = 0, Imax = 250) annotation(Placement(transformation(origin = {60, 60}, extent = {{-10, -10}, {10, 10}})));
    ElectricBus bus annotation(Placement(transformation(origin = {60, 110}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Add actuatorCurrent annotation(Placement(transformation(origin = {30, 110}, extent = {{-6, -6}, {6, 6}})));
    EquaForgeAerospace.Environment.CentralGravity gravity annotation(Placement(transformation(origin = {-60, 60}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.AtmosphereUS76 atmosphere annotation(Placement(transformation(origin = {40, -150}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.AirData airData annotation(Placement(transformation(origin = {0, -150}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.FileTable windTable(fileName = "wind.csv", columns = {2, 3}) annotation(Placement(transformation(origin = {-40, -170}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Aerodynamics.BodyAero aero(S = 63.6, planformRatio = 5.6, x_cp_nose = 32, x_cp_tail = 18, x_cp_broadside = 24) annotation(Placement(transformation(origin = {-60, -150}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBodyFrame flapMount[4](r = {{44, 0, 5}, {44, 0, -5}, {4, 0, 5}, {4, 0, -5}}) "Forward left, forward right, aft left, aft right" annotation(Placement(transformation(origin = {100, 20}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Aerodynamics.Flap flap[4](S = {10, 10, 25, 25}) annotation(Placement(transformation(origin = {140, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    HeatShield heatShield annotation(Placement(transformation(origin = {80, -150}, extent = {{-10, -10}, {10, 10}})));
    LandingLegs legs(padRadius = 30000) annotation(Placement(transformation(origin = {140, -150}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeAerospace.GNC.IMU imu annotation(Placement(transformation(origin = {-20, 60}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.OrbitalElements orbit annotation(Placement(transformation(origin = {20, 20}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.GroundTrack track(latTarget = latPad, lonTarget = lonPad) annotation(Placement(transformation(origin = {20, -20}, extent = {{-10, -10}, {10, 10}})));
    AttitudeControl control(omega = 0.5, surfaceGain = {334, 1e12, 1327}, mix = {{1, 0, -1}, {-1, 0, -1}, {1, 0, 1}, {-1, 0, 1}}, useTrimInput = true, useBandwidthInput = true, surfaceMax = 0.6, surfaceAuthority = {200, 0, 796}, rcsMax = 4e5, rcsDeadband = 2e4) annotation(Placement(transformation(origin = {20, -70}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeVC.Multibody.ForcesAndMoments.BodyMoment rcs "Reaction-control thrusters" annotation(Placement(transformation(origin = {-60, 20}, extent = {{-8, -8}, {8, 8}}, rotation = 180)));
    ShipFlightComputer computer(phase_start = phase_start, tDeorbit = tDeorbit, dvDeorbit = dvDeorbit, tanTheta0 = tanTheta0, tanRate = tanRate) annotation(Placement(transformation(origin = {120, -80}, extent = {{-16, -16}, {16, 16}})));
    ShipLook look "How it looks in the 3-D view" annotation(Placement(transformation(origin = {-160, 120}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(body.frame_a, frame_a);
    connect(carrier, body.carrier);
    connect(attach, body.attach);
    connect(body.load, load);
    connect(body.motion, motion);
    connect(feed.mass, shipMass.u1);
    connect(header.mass, shipMass.u2);
    connect(payload.mass, shipMass.u3);
    connect(computer.release, payload.release);
    connect(shipMass.y, body.mass);
    connect(shipMass.y, mass);
    // propulsion and propellant
    connect(body.frame_a, slOne.frame_b);
    connect(body.frame_a, slPair.frame_b);
    connect(body.frame_a, vacRing.frame_b);
    oxygen.u1 = slOne.mdot_ox + slPair.mdot_ox;
    connect(vacRing.mdot_ox, oxygen.u2);
    methane.u1 = slOne.mdot_fuel + slPair.mdot_fuel;
    connect(vacRing.mdot_fuel, methane.u2);
    // the main tanks feed the ascent and the deorbit burn, the header tanks the landing
    feed.mdot_ox = if computer.headerFeed then 0 else oxygen.y;
    feed.mdot_fuel = if computer.headerFeed then 0 else methane.y;
    header.mdot_ox = if computer.headerFeed then oxygen.y else 0;
    header.mdot_fuel = if computer.headerFeed then methane.y else 0;
    feed.a_axial = imu.specificForce[1];
    header.a_axial = imu.specificForce[1];
    connect(atmosphere.p, slOne.p_amb);
    connect(atmosphere.p, slPair.p_amb);
    connect(atmosphere.p, vacRing.p_amb);
    connect(computer.throttleSL, slOne.throttle);
    connect(computer.throttleSL, slPair.throttle);
    connect(computer.throttleVac, vacRing.throttle);
    // an engine runs while the computer asks and the tanks that feed it still hold propellant
    slOne.on = computer.slOn and not dry;
    slPair.on = computer.pairOn and not dry;
    vacRing.on = computer.vacOn and not feed.empty;
    dry = if computer.headerFeed then header.empty else feed.empty;
    slOne.failed = false;
    slPair.failed = false;
    vacRing.failed = false;
    vacRing.gimbal = zeros(2);
    // environment
    connect(body.frame_a, gravity.frame_a);
    connect(gravity.g, body.g);
    connect(gravity.g, imu.g);
    connect(body.motion, imu.vehicle);
    connect(body.motion, airData.vehicle);
    connect(airData.h, atmosphere.h);
    connect(atmosphere.rho, airData.rho);
    connect(atmosphere.a, airData.a);
    connect(airData.h, windTable.u);
    connect(windTable.y, airData.wind);
    connect(body.frame_a, aero.frame_b);
    connect(airData.v_air, aero.v_air);
    connect(airData.qbar, aero.qbar);
    connect(airData.Mach, aero.Mach);
    for k in 1:4 loop
      connect(body.frame_a, flapMount[k].frame_a);
      connect(flapMount[k].frame_b, flap[k].frame_b);
      connect(airData.v_air, flap[k].v_air);
      connect(airData.qbar, flap[k].qbar);
      connect(flapDrives.angle[k], flap[k].delta);
      connect(flap[k].hingeMoment, flapDrives.loadTorque[k]);
    end for;
    connect(atmosphere.rho, heatShield.rho);
    connect(airData.V, heatShield.V);
    connect(body.frame_a, legs.vehicle);
    connect(pad, legs.ground);
    // guidance, navigation and control
    connect(body.motion, orbit.vehicle);
    connect(body.motion, track.vehicle);
    connect(body.motion, computer.vehicle);
    connect(padTarget, computer.target);
    connect(staging, computer.staging);
    connect(attach, computer.attached);
    connect(orbit.energy, computer.energy);
    computer.accel = imu.specificForce[1];
    computer.mass = shipMass.y.m;
    connect(atmosphere.p, computer.p_amb);
    connect(airData.Mach, computer.Mach);
    computer.onLegs = legs.load > 1e4;
    landed = computer.flight.phase == 8;
    connect(body.motion, control.vehicle);
    connect(shipMass.y, control.mass);
    connect(computer.direction, control.direction);
    connect(computer.rollReference, control.rollReference);
    connect(computer.flapTrim, control.trim);
    connect(computer.bandwidth, control.bandwidth);
    control.thrust = slOne.thrust + slPair.thrust;
    connect(airData.qbar, control.qbar);
    // the gimbals centre while the sea-level engines are off
    gimbals.command = if computer.slOn then control.gimbal else zeros(2);
    gimbals.loadTorque = zeros(2);
    connect(gimbals.angle, slOne.gimbal);
    connect(gimbals.angle, slPair.gimbal);
    flapDrives.command = if computer.flapsActive then control.surfaces else fill(0.1, 4);
    connect(body.frame_a, rcs.frame_b);
    rcs.t = if computer.flight.phase == 8 then zeros(3) else control.rcs;
    connect(gimbals.current, actuatorCurrent.u1);
    connect(flapDrives.current, actuatorCurrent.u2);
    connect(actuatorCurrent.y, bus.current);
    connect(body.frame_a, look.frame_a);
    connect(flapDrives.angle, look.flapAngle);
    connect(heatShield.rgb, look.tileColor);
    look.thrust = slOne.thrust + slPair.thrust + vacRing.thrust;
    look.legsOut = computer.flight.phase >= 7;
    annotation(Icon(coordinateSystem(extent = {{-200, -200}, {200, 200}}), graphics = {
        Rectangle(extent = {{-40, 120}, {40, -160}}, lineColor = {80, 80, 80}, fillColor = {220, 220, 225}, fillPattern = FillPattern.VerticalCylinder),
        Polygon(points = {{-40, 120}, {0, 190}, {40, 120}}, lineColor = {80, 80, 80}, fillColor = {220, 220, 225}, fillPattern = FillPattern.Solid),
        Rectangle(extent = {{40, 120}, {20, -160}}, lineColor = {30, 30, 30}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid),
        Polygon(points = {{-40, 110}, {-70, 90}, {-70, 60}, {-40, 70}}, lineColor = {60, 60, 60}, fillColor = {90, 90, 90}, fillPattern = FillPattern.Solid),
        Polygon(points = {{-40, -110}, {-80, -130}, {-80, -160}, {-40, -150}}, lineColor = {60, 60, 60}, fillColor = {90, 90, 90}, fillPattern = FillPattern.Solid),
        Text(extent = {{-200, 240}, {200, 205}}, textString = "%name")}),
      Diagram(coordinateSystem(extent = {{-200, -200}, {200, 280}}), graphics = {Text(extent = {{-195, 278}, {195, 220}}, textString = "## Ship\nA free body that rides on the booster until hot staging (CapturableBody), with its feed system, three gimballed sea-level engines (one that lands it and a pair) and three fixed vacuum engines, four flaps on electromechanical actuators, the heat shield, landing legs, attitude control (gimbal, flaps, thrusters) and the flight computer. Orbit and ground track come from OrbitalElements and GroundTrack.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>The second stage. Illustrative values, rounded from public estimates for a fully reusable upper stage; not any manufacturer's data. The body axes: x towards the nose, y towards the belly (the heat shield).</p></html>"));
  end Ship;
  model LaunchComplex "The launch site in the 3-D view: land and sea, the launch deck, the tower with its arms (they close on the caught booster) and the ship's landing pad"
    parameter Real latitude(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the launch pad (the tower and the landing pad are placed from it)";
    parameter Real catchNorth(unit = "m") = 1.5e-6*EquaForgeAerospace.radiusEarth "The catch axis, north of the launch pad (the catch point is 1.5e-6 rad of latitude north)";
    parameter Real shipPadEast(unit = "m") = -4e-5*EquaForgeAerospace.radiusEarth*cos(latitude) "The ship's landing pad, east of the launch pad (4e-5 rad of longitude west)";
    parameter Real catchHeight(unit = "m") = 80 "Height of the arms' tops: the booster's pins come to rest there";
    parameter Real armLength(unit = "m") = 24 "Length of each arm";
    parameter Real armOpen(unit = "rad", displayUnit = "deg") = 1.0 "How far the arms stand open";
    parameter Real T_close(unit = "s") = 1.5 "Time constant of the arms closing";
    parameter Boolean arms = true "Draw the arms and their carriage (false: hidden, the model has its own, as TowerCatch)" annotation(Evaluate = true);
    EquaForgeVC.Multibody.Interfaces.Frame_a frame_a "The launch pad's site frame: x up, y east, z north (LaunchSite)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
    EquaForgeVC.Interfaces.BooleanInput caught "The booster is caught: the arms close on it" annotation(Placement(transformation(origin = {0, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
    EquaForgeVC.Multibody.Visualization.AttachedShape ground(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 2, width = 24000, height = 24000, position = {-1.3, 0, 0}, color = {190, 176, 140}) "Land, 24 km square around the pad (a flat plate: the ground drops 11 m by its edge). Its length is the vertical: the 3-D view drawn in its axes has east, north and up" annotation(Placement(transformation(origin = {-50, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape sea(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 2, width = 30000, height = 24000, position = {-0.8, 1500 + 15000, 0}, color = {40, 92, 145}) "The sea from 1.5 km east of the pad, drawn over the land" annotation(Placement(transformation(origin = {-15, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape deck(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 1.5, width = 40, height = 40, position = {-0.75, 0, 0}, color = {165, 165, 160}) "The launch deck the booster stands on" annotation(Placement(transformation(origin = {20, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape clamp[6](each shapeType = EquaForgeVC.Visualization.ShapeType.Box, each length = 2.5, each width = 1.6, each height = 1.6, widthDirection = {{0, 1, 0}, {0, 0.5, 0.866}, {0, -0.5, 0.866}, {0, -1, 0}, {0, -0.5, -0.866}, {0, 0.5, -0.866}}, position = {{1.25, 5.3, 0}, {1.25, 2.65, 4.59}, {1.25, -2.65, 4.59}, {1.25, -5.3, 0}, {1.25, -2.65, -4.59}, {1.25, 2.65, -4.59}}, each color = {80, 80, 88}) "Hold-down clamps around the booster's base" annotation(Placement(transformation(origin = {55, 45}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape tower(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 146, width = 12, height = 12, position = {73, -20, catchNorth}, color = {72, 76, 86}) "The tower, 20 m west of the catch axis" annotation(Placement(transformation(origin = {-50, 5}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape mast(shapeType = EquaForgeVC.Visualization.ShapeType.Cylinder, length = 14, width = 1.2, position = {153, -20, catchNorth}, color = {130, 130, 135}) "Lightning mast" annotation(Placement(transformation(origin = {-15, 5}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape carriage(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 6, width = 4, height = 16, position = {catchHeight - 1, -12, catchNorth}, color = {95, 98, 108}, opacity = if arms then 1 else 0) "The carriage the arms hang on" annotation(Placement(transformation(origin = {20, 5}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape arm[2](each shapeType = EquaForgeVC.Visualization.ShapeType.Box, each length = 2, each width = armLength, each height = 2, position = {{catchHeight - 1, -12 + armLength/2, catchNorth + 5.5}, {catchHeight - 1, -12 + armLength/2, catchNorth - 5.5}}, each color = {95, 95, 105}, each useAngleInput = true, each hingeAxis = {1, 0, 0}, hingePoint = {{catchHeight, -12, catchNorth + 5.5}, {catchHeight, -12, catchNorth - 5.5}}, each opacity = if arms then 1 else 0) "The arms: hinged on the carriage, they swing in under the booster's pins" annotation(Placement(transformation(origin = {55, 5}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape shipPad(shapeType = EquaForgeVC.Visualization.ShapeType.Cylinder, length = 1.5, width = 36, position = {-0.75, shipPadEast, 0}, color = {150, 150, 148}) "The ship's landing pad" annotation(Placement(transformation(origin = {-50, -35}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape padMark(shapeType = EquaForgeVC.Visualization.ShapeType.Cylinder, length = 0.1, width = 10, position = {0.05, shipPadEast, 0}, color = {215, 180, 40}) "The target painted on it" annotation(Placement(transformation(origin = {-15, -35}, extent = {{-10, -10}, {10, 10}})));
    Real closing(start = 0, fixed = true) "How far the arms have closed, 0 open .. 1 shut";
  equation
    der(closing) = ((if caught then 1 else 0) - closing)/T_close;
    arm[1].angleIn = armOpen*(1 - closing);
    arm[2].angleIn = -armOpen*(1 - closing);
    connect(frame_a, ground.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {-64, 30}, {-64, 45}, {-60, 45}}, color = {95, 95, 95}));
    connect(frame_a, sea.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {-29, 30}, {-29, 45}, {-25, 45}}, color = {95, 95, 95}));
    connect(frame_a, deck.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {6, 30}, {6, 45}, {10, 45}}, color = {95, 95, 95}));
    connect(frame_a, tower.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {-64, -10}, {-64, 5}, {-60, 5}}, color = {95, 95, 95}));
    connect(frame_a, mast.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {-29, -10}, {-29, 5}, {-25, 5}}, color = {95, 95, 95}));
    connect(frame_a, carriage.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {6, -10}, {6, 5}, {10, 5}}, color = {95, 95, 95}));
    connect(frame_a, shipPad.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -50}, {-64, -50}, {-64, -35}, {-60, -35}}, color = {95, 95, 95}));
    connect(frame_a, padMark.frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -50}, {-29, -50}, {-29, -35}, {-25, -35}}, color = {95, 95, 95}));
    for k in 1:6 loop
      connect(frame_a, clamp[k].frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, 30}, {41, 30}, {41, 45}, {45, 45}}, color = {95, 95, 95}));
    end for;
    for k in 1:2 loop
      connect(frame_a, arm[k].frame_a) annotation(Line(points = {{-100, 0}, {-80, 0}, {-80, -10}, {41, -10}, {41, 5}, {45, 5}}, color = {95, 95, 95}));
    end for;
    annotation(Icon(graphics = {
        Rectangle(extent = {{-90, -50}, {90, -70}}, lineColor = {150, 135, 100}, fillColor = {190, 176, 140}, fillPattern = FillPattern.Solid),
        Rectangle(extent = {{-60, 80}, {-40, -50}}, lineColor = {50, 50, 60}, fillColor = {72, 76, 86}, fillPattern = FillPattern.CrossDiag),
        Line(points = {{-40, 30}, {10, 40}}, color = {60, 60, 70}, thickness = 1),
        Line(points = {{-40, 30}, {10, 20}}, color = {60, 60, 70}, thickness = 1),
        Rectangle(extent = {{0, 60}, {20, -50}}, lineColor = {80, 80, 80}, fillColor = {210, 210, 215}, fillPattern = FillPattern.VerticalCylinder),
        Rectangle(extent = {{40, -45}, {80, -50}}, lineColor = {100, 100, 100}, fillColor = {150, 150, 148}, fillPattern = FillPattern.Solid),
        Text(extent = {{-150, 130}, {150, 95}}, textString = "%name")}),
      Diagram(graphics = {Text(extent = {{-95, 98}, {95, 72}}, textString = "## Launch complex in 3-D\nShapes only, on the launch pad's site frame (x up, y east, z north). The arms swing in (angle input) when the booster is caught. Draw the 3-D view in the axes of site.ground: the site stays level, though the world frame turns with the Earth's centre.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>What the 3-D view draws of the launch site, placed on the launch pad's site frame (x up, y east, z north): 24 km of land and the sea from 1.5 km east, the launch deck with its hold-down clamps, the 146 m tower 20 m west of the catch axis with its carriage and two 24 m arms at 80 m, and the ship's landing pad 230 m west. The arms stand open until <b>caught</b>, then close. The land plate's length is the vertical, so choosing its axes in the 3-D view (<i>site.ground axes</i>) draws the site level with east, north and up, and the vehicles' paths over the ground.</p><p>Illustrative dimensions, not a survey of any real site.</p></html>"));
  end LaunchComplex;

  model AscentToOrbit "Lift-off to orbit: the stack climbs, stages hot, the booster flies back into the tower and the ship goes on to orbit and releases its payload"
    parameter Real lat(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the launch pad";
    parameter Real lon(unit = "rad", displayUnit = "deg") = -1.69571 "Longitude of the launch pad";
    EquaForgeAerospace.Environment.RotatingEarth earth annotation(Placement(transformation(origin = {-150, -20}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeAerospace.Environment.LaunchSite pad(latitude = lat, longitude = lon) "The launch mount" annotation(Placement(transformation(origin = {-100, 40}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.LaunchSite catchPoint(latitude = lat + 1.5e-6, longitude = lon, altitude = 80 - 62) "Where the booster's frame stops in the arms" annotation(Placement(transformation(origin = {-100, -20}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.LaunchSite shipPad(latitude = lat, longitude = lon - 4e-5) "The ship's landing pad, beside the tower" annotation(Placement(transformation(origin = {-100, -80}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.JointsAndMotions.Attachment mount "Holds the stack until release" annotation(Placement(transformation(origin = {-50, 40}, extent = {{-10, -10}, {10, 10}})));
    final parameter Real Rp[3, 3] = EquaForgeVC.Multibody.Frames.fromQ(pad.Q_site);
    final parameter Real rShip0[3](each unit = "m") = pad.r_site + transpose(Rp)*{69, 0, 0};
    Booster booster(r_start = pad.r_site, v_start = cross({0, 0, EquaForgeAerospace.omegaEarth}, pad.r_site), Q_start = pad.Q_site, w_start = Rp*{0, 0, EquaForgeAerospace.omegaEarth}) annotation(Placement(transformation(origin = {20, 20}, extent = {{-30, -30}, {30, 30}})));
    Ship ship(r_start = rShip0, v_start = cross({0, 0, EquaForgeAerospace.omegaEarth}, rShip0), Q_start = pad.Q_site, w_start = Rp*{0, 0, EquaForgeAerospace.omegaEarth}) annotation(Placement(transformation(origin = {120, 20}, extent = {{-30, -30}, {30, 30}})));
    LaunchComplex site(latitude = lat) "The site in the 3-D view" annotation(Placement(transformation(origin = {-150, 40}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(earth.frame_b, pad.frame_a);
    connect(earth.motion, pad.earth);
    connect(earth.frame_b, catchPoint.frame_a);
    connect(earth.motion, catchPoint.earth);
    connect(earth.frame_b, shipPad.frame_a);
    connect(earth.motion, shipPad.earth);
    connect(pad.frame_b, mount.frame_b);
    connect(pad.motion, mount.carrier);
    connect(pad.frame_b, site.frame_a);
    connect(booster.caught, site.caught);
    connect(mount.held, booster.carrier);
    connect(booster.load, mount.load);
    connect(booster.held, mount.attach);
    connect(catchPoint.motion, booster.catchTarget);
    connect(catchPoint.motion, booster.towerCarrier);
    connect(ship.mass, booster.shipMass);
    connect(ship.load, booster.shipLoad);
    connect(booster.shipCarrier, ship.carrier);
    connect(booster.joined, ship.attach);
    connect(booster.staging, ship.staging);
    connect(shipPad.motion, ship.padTarget);
    connect(shipPad.frame_b, ship.pad);
    annotation(experiment(StopTime = 600, Interval = 0.5, Tolerance = 1e-7, __EquaForge_Algorithm = "bdf"),
      Diagram(coordinateSystem(extent = {{-180, -110}, {180, 160}}), graphics = {Text(extent = {{-175, 158}, {175, 70}}, textString = "## Ascent to orbit\nThe stack lifts off the mount (Attachment) on the turning Earth. The booster cuts off with its return propellant left, the ship lights its engines (hot staging) and flies a linear-tangent ascent to a 185 by 225 km orbit; it releases its payload two minutes later. The booster flips, burns back towards the tower (its impact point steered onto it), falls tail-first steering with its grid fins and brakes into the arms at the catch point.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>The first ten minutes of the mission. Everything after hot staging that concerns the booster is also in <code>BoosterReturn</code>; the ship's orbit goes on in <code>OrbitPlanning</code> and <code>FullMission</code>.</p></html>"),
      __EquaForge(plots = {
        Plot(name = "Altitude", curves = {"ship.airData.h", "booster.airData.h"}),
        Plot(name = "Speed", curves = {"ship.airData.speedGround", "booster.airData.speedGround"}),
        Plot(name = "Dynamic pressure", curves = {"ship.airData.qbar", "booster.airData.qbar"}),
        Plot(name = "Propellant", curves = {"ship.feed.propellant", "booster.feed.propellant"}),
        Plot(name = "Orbit", curves = {"ship.orbit.periapsis", "ship.orbit.apoapsis"}),
        Plot(name = "Flight phases", curves = {"ship.computer.flight.phase", "booster.computer.flight.phase"})}, plotArrangement = "Grid", linkTime = true,
        animation = Animation(frame = "site.ground", follow = "ship.look.hull", view = "iso")));
  end AscentToOrbit;

  model BoosterReturn "The booster alone, from lift-off to the catch: ascent with the ship's mass, boostback, the tail-first fall and the landing burn into the tower's arms"
    parameter Real lat(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the launch pad";
    parameter Real lon(unit = "rad", displayUnit = "deg") = -1.69571 "Longitude of the launch pad";
    EquaForgeAerospace.Environment.RotatingEarth earth annotation(Placement(transformation(origin = {-150, -20}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeAerospace.Environment.LaunchSite pad(latitude = lat, longitude = lon) "The launch mount" annotation(Placement(transformation(origin = {-100, 40}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.LaunchSite catchPoint(latitude = lat + 1.5e-6, longitude = lon, altitude = 80 - 62) "Where the booster's frame stops in the arms" annotation(Placement(transformation(origin = {-100, -40}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.JointsAndMotions.Attachment mount "Holds the booster until release" annotation(Placement(transformation(origin = {-50, 40}, extent = {{-10, -10}, {10, 10}})));
    final parameter Real Rp[3, 3] = EquaForgeVC.Multibody.Frames.fromQ(pad.Q_site);
    Booster booster(r_start = pad.r_site, v_start = cross({0, 0, EquaForgeAerospace.omegaEarth}, pad.r_site), Q_start = pad.Q_site, w_start = Rp*{0, 0, EquaForgeAerospace.omegaEarth}) annotation(Placement(transformation(origin = {40, 0}, extent = {{-30, -30}, {30, 30}})));
    EquaForgeVC.Multibody.BodiesAndFrames.MassProperties ship(m = 1.733e6, r_CM = {20, 0, 0}, I_11 = 5e6, I_22 = 3e8, I_33 = 3e8) "Stand-in for the ship until hot staging" annotation(Placement(transformation(origin = {40, 70}, extent = {{-8, -8}, {8, 8}})));
    LaunchComplex site(latitude = lat) "The site in the 3-D view" annotation(Placement(transformation(origin = {-150, 40}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(earth.frame_b, pad.frame_a);
    connect(earth.motion, pad.earth);
    connect(earth.frame_b, catchPoint.frame_a);
    connect(earth.motion, catchPoint.earth);
    connect(pad.frame_b, mount.frame_b);
    connect(pad.motion, mount.carrier);
    connect(pad.frame_b, site.frame_a);
    connect(booster.caught, site.caught);
    connect(mount.held, booster.carrier);
    connect(booster.load, mount.load);
    connect(booster.held, mount.attach);
    connect(ship.y, booster.shipMass);
    booster.shipLoad.f = zeros(3);
    booster.shipLoad.t = zeros(3);
    connect(catchPoint.motion, booster.catchTarget);
    connect(catchPoint.motion, booster.towerCarrier);
    annotation(experiment(StopTime = 480, Interval = 0.2, Tolerance = 1e-7, __EquaForge_Algorithm = "bdf"),
      Diagram(coordinateSystem(extent = {{-180, -100}, {180, 170}}), graphics = {Text(extent = {{-175, 168}, {175, 92}}, textString = "## Booster return\nThe booster with the ship as a mass (MassProperties) until hot staging. It flips, burns back towards the tower until its impact point (ImpactPointPredictor) has come back past it by the drag bias, falls tail-first steering across the track with its grid fins, lights thirteen engines and finishes on three into the arms. The arms close if it reaches the catch height within 20 m.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      __EquaForge(plots = {
        Plot(name = "Altitude", curves = {"booster.airData.h"}),
        Plot(name = "Miss at the tower", curves = {"booster.computer.landing.offset"}),
        Plot(name = "Sink rate and its plan", curves = {"booster.computer.landing.sinkRate", "booster.computer.landing.v_ref"}),
        Plot(name = "Impact point", curves = {"booster.ipp.rangeToGo", "booster.ipp.crossRange"}),
        Plot(name = "Propellant", curves = {"booster.feed.lox.m_l", "booster.feed.ch4.m_l"}),
        Plot(name = "Thrust", curves = {"booster.centerRing.thrust", "booster.innerRing.thrust", "booster.outerRing.thrust"})}, plotArrangement = "Grid", linkTime = true,
        animation = Animation(frame = "site.ground", follow = "booster.look.hull", view = "iso")));
  end BoosterReturn;
  model ShipEntryLanding "The ship from orbit to its legs: the deorbit burn, belly-first entry banking towards the pad, the belly-flop, the flip and the landing burn"
    parameter Real latPad(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the landing pad";
    parameter Real lonPad(unit = "rad", displayUnit = "deg") = -1.69575 "Longitude of the landing pad";
    parameter Real tDeorbit(unit = "s") = 4108.5 "Time of the deorbit burn (the worksheet shoots it)";
    EquaForgeAerospace.Environment.RotatingEarth earth annotation(Placement(transformation(origin = {-150, -20}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeAerospace.Environment.LaunchSite shipPad(latitude = latPad, longitude = lonPad) "The landing pad" annotation(Placement(transformation(origin = {-90, -20}, extent = {{-10, -10}, {10, 10}})));
    Ship ship(phase_start = 3, tDeorbit = tDeorbit, latPad = latPad, lonPad = lonPad, m_payload = 0,
      r_start = {-5699691.294, 3019654.708, -1373384.468}, v_start = {-3899.644446, -6023.497815, 2977.57738}, Q_start = {0.1870227427, -0.1184309568, -0.4835820628, -0.846844136}, w_start = {0.0004899716113, 5.520799866e-05, 0.001203897331},
      m_lox = 22122.4, m_ch4 = 4201.4, m_headerLox = 19460.6, m_headerCh4 = 5377.02, residualLox = 2302, residualCh4 = 636, residualHeaderLox = 41, residualHeaderCh4 = 11.4) "In its parking orbit, 3900 s after lift-off, the payload released" annotation(Placement(transformation(origin = {40, 0}, extent = {{-30, -30}, {30, 30}})));
    EquaForgeAerospace.Environment.LaunchSite launchPad(latitude = latPad, longitude = lonPad + 4e-5) "The launch pad beside the tower: the site in the 3-D view hangs from it" annotation(Placement(transformation(origin = {-90, 50}, extent = {{-10, -10}, {10, 10}})));
    LaunchComplex site(latitude = latPad) "The site in the 3-D view" annotation(Placement(transformation(origin = {-40, 50}, extent = {{-10, -10}, {10, 10}})));
    Boolean home "On its legs";
    discrete Real tHome(start = 1e9, fixed = true) "When it touched down";
  equation
    connect(earth.frame_b, shipPad.frame_a);
    connect(earth.motion, shipPad.earth);
    connect(earth.frame_b, launchPad.frame_a);
    connect(earth.motion, launchPad.earth);
    connect(launchPad.frame_b, site.frame_a);
    site.caught = false;
    connect(earth.motion, ship.carrier);
    ship.attach = false;
    ship.staging = false;
    connect(shipPad.motion, ship.padTarget);
    connect(shipPad.frame_b, ship.pad);
    home = ship.landed;
    when home then
      tHome = time;
    end when;
    when home and time > tHome + 15 then
      terminate("the ship stands on its legs");
    end when;
    annotation(experiment(StartTime = 3900, StopTime = 6500, Interval = 0.5, Tolerance = 1e-7, __EquaForge_Algorithm = "bdf", __EquaForge_OutputIntervals = {{3900, 1}, {4200, 10}, {6150, 0.25}}),
      Diagram(coordinateSystem(extent = {{-180, -100}, {180, 160}}), graphics = {Text(extent = {{-175, 158}, {175, 72}}, textString = "## Ship entry and landing\nFrom its parking orbit the ship turns retrograde and burns 80 m/s on one engine at the deorbit time. It enters belly-first at 60 degrees (flaps trimmed with Mach), banking to fly over the pad, falls belly-first below Mach 0.7 steering its heading and tilt towards the pad, flips on three engines and lands on one. It is the same ship and the same state as FullMission at 3900 s: the worksheet shoots the deorbit time here.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      __EquaForge(plots = {
        Plot(name = "Altitude", curves = {"ship.airData.h"}),
        Plot(name = "Mach number", curves = {"ship.airData.Mach"}),
        Plot(name = "Angle of attack", curves = {"ship.airData.alphaTotal", "ship.computer.alphaSchedule.y"}),
        Plot(name = "Heat shield", curves = {"ship.heatShield.T"}),
        Plot(name = "Range to go", curves = {"ship.computer.rangeToGo", "ship.computer.crossRange"}),
        Plot(name = "Landing burn", curves = {"ship.computer.landing.sinkRate", "ship.computer.landing.v_ref"})}, plotArrangement = "Grid", linkTime = true,
        animation = Animation(frame = "site.ground", follow = "ship.look.hull", view = "iso")));
  end ShipEntryLanding;

  model FullMission "The whole round trip in one run: lift-off, hot staging, the booster back into the tower, orbit, payload release, deorbit, entry, belly-flop and landing beside the pad"
    parameter Real lat(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the launch pad";
    parameter Real lon(unit = "rad", displayUnit = "deg") = -1.69571 "Longitude of the launch pad";
    parameter Real tDeorbit(unit = "s") = 4108.5 "Time of the ship's deorbit burn: the first-orbit pass over the pad";
    EquaForgeAerospace.Environment.RotatingEarth earth annotation(Placement(transformation(origin = {-150, -20}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeAerospace.Environment.LaunchSite pad(latitude = lat, longitude = lon) "The launch mount" annotation(Placement(transformation(origin = {-100, 40}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.LaunchSite catchPoint(latitude = lat + 1.5e-6, longitude = lon, altitude = 80 - 62) "Where the booster's frame stops in the arms" annotation(Placement(transformation(origin = {-100, -20}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.LaunchSite shipPad(latitude = lat, longitude = lon - 4e-5) "The ship's landing pad, beside the tower" annotation(Placement(transformation(origin = {-100, -80}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.JointsAndMotions.Attachment mount "Holds the stack until release" annotation(Placement(transformation(origin = {-50, 40}, extent = {{-10, -10}, {10, 10}})));
    final parameter Real Rp[3, 3] = EquaForgeVC.Multibody.Frames.fromQ(pad.Q_site);
    final parameter Real rShip0[3](each unit = "m") = pad.r_site + transpose(Rp)*{69, 0, 0};
    Booster booster(r_start = pad.r_site, v_start = cross({0, 0, EquaForgeAerospace.omegaEarth}, pad.r_site), Q_start = pad.Q_site, w_start = Rp*{0, 0, EquaForgeAerospace.omegaEarth}) annotation(Placement(transformation(origin = {20, 20}, extent = {{-30, -30}, {30, 30}})));
    Ship ship(tDeorbit = tDeorbit, r_start = rShip0, v_start = cross({0, 0, EquaForgeAerospace.omegaEarth}, rShip0), Q_start = pad.Q_site, w_start = Rp*{0, 0, EquaForgeAerospace.omegaEarth}) annotation(Placement(transformation(origin = {120, 20}, extent = {{-30, -30}, {30, 30}})));
    LaunchComplex site(latitude = lat) "The site in the 3-D view" annotation(Placement(transformation(origin = {-150, 40}, extent = {{-10, -10}, {10, 10}})));
    Boolean home "The booster is in the tower and the ship on its legs";
    discrete Real tHome(start = 1e9, fixed = true) "When both were home";
  equation
    connect(earth.frame_b, pad.frame_a);
    connect(earth.motion, pad.earth);
    connect(earth.frame_b, catchPoint.frame_a);
    connect(earth.motion, catchPoint.earth);
    connect(earth.frame_b, shipPad.frame_a);
    connect(earth.motion, shipPad.earth);
    connect(pad.frame_b, mount.frame_b);
    connect(pad.motion, mount.carrier);
    connect(pad.frame_b, site.frame_a);
    connect(booster.caught, site.caught);
    connect(mount.held, booster.carrier);
    connect(booster.load, mount.load);
    connect(booster.held, mount.attach);
    connect(catchPoint.motion, booster.catchTarget);
    connect(catchPoint.motion, booster.towerCarrier);
    connect(ship.mass, booster.shipMass);
    connect(ship.load, booster.shipLoad);
    connect(booster.shipCarrier, ship.carrier);
    connect(booster.joined, ship.attach);
    connect(booster.staging, ship.staging);
    connect(shipPad.motion, ship.padTarget);
    connect(shipPad.frame_b, ship.pad);
    // stop a little after both vehicles are home: the ship settles on its legs
    home = booster.caught and ship.landed;
    when home then
      tHome = time;
    end when;
    when home and time > tHome + 15 then
      terminate("both vehicles are home");
    end when;
    annotation(experiment(StopTime = 6500, Interval = 0.5, Tolerance = 1e-7, __EquaForge_Algorithm = "bdf", __EquaForge_OutputIntervals = {{0, 0.5}, {480, 20}, {4080, 1}, {4160, 10}, {6150, 0.5}},
        __EquaForge_Outputs = {"ship.motion.*", "booster.motion.*", "ship.padTarget.*", "booster.catchTarget.*", "*.computer.flight.phase", "ship.landed", "booster.caught", "ship.orbit.*", "ship.track.*", "ship.feed.*.m_l", "ship.header.*.m_l", "ship.feed.propellant", "ship.header.propellant", "booster.feed.propellant", "booster.feed.*.m_l", "ship.legs.load", "ship.computer.landing.*", "booster.computer.landing.*", "ship.computer.rangeToGo", "ship.computer.crossRange", "ship.computer.alphaSchedule.y", "ship.airData.*", "booster.airData.*", "ship.heatShield.T", "ship.shipMass.y.m", "ship.slOne.thrust", "ship.slPair.thrust", "ship.vacRing.thrust", "booster.*Ring.thrust", "booster.ipp.*", "ship.control.error.angle", "booster.control.error.angle"}),
      Diagram(coordinateSystem(extent = {{-180, -110}, {180, 160}}), graphics = {Text(extent = {{-175, 158}, {175, 70}}, textString = "## Full mission\nThe same stack as AscentToOrbit, flown through to the end: the booster is caught 7.7 minutes after lift-off, the ship coasts most of an orbit, burns at the deorbit time on the pass that comes back over the launch site and lands beside the tower about an hour and three quarters after lift-off. The run stops 15 s after both are home. Its results are filtered to the signals the plots and the 3-D view need.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      __EquaForge(plots = {
        Plot(name = "Altitude", curves = {"ship.airData.h", "booster.airData.h"}),
        Plot(name = "Speed", curves = {"ship.airData.speedGround", "booster.airData.speedGround"}),
        Plot(name = "Orbit", curves = {"ship.orbit.periapsis", "ship.orbit.apoapsis"}),
        Plot(name = "Ground track", curves = {"ship.track.latitude", "ship.track.longitude"}),
        Plot(name = "Mass", curves = {"ship.shipMass.y.m", "booster.feed.propellant"}),
        Plot(name = "Heat shield", curves = {"ship.heatShield.T"})}, plotArrangement = "Grid", linkTime = true,
        animation = Animation(frame = "site.ground", follow = "ship.look.hull", view = "iso")));
  end FullMission;
  model TowerCatch "The booster's last minute and a quarter: the fall, the landing burn into the tower, the arms close and take it on its pins, the carriage's shock absorber takes the load"
    parameter Real lat(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the tower";
    parameter Real lon(unit = "rad", displayUnit = "deg") = -1.69571 "Longitude of the tower";
    parameter Real tClose(unit = "s") = 452 "The arms start to close";
    parameter Real armOpen(unit = "rad", displayUnit = "deg") = 1.0 "How far the arms stand open";
    parameter Real armLength(unit = "m") = 24 "Length of each arm";
    parameter Real m_arm(unit = "kg") = 3e4 "Mass of each arm";
    parameter Real m_carriage(unit = "kg") = 5e4 "Mass of the carriage the arms hang on";
    parameter Real c_shock(unit = "N/m") = 3e7 "Stiffness of the carriage's shock absorber";
    parameter Real d_shock(unit = "N.s/m") = 3e6 "Its damping";
    final parameter Real Rmid[3, 3] = EquaForgeVC.Multibody.Frames.planarRotation({0, 0, 1}, EquaForgeAerospace.omegaEarth*440) "The Earth turned to the middle of the segment";
    final parameter Real gTower[3](each unit = "m/s2") = -EquaForgeAerospace.g0*transpose(Rmid)*seat.r_site/sqrt(seat.r_site*seat.r_site) "Local gravity at the tower (it turns with the Earth by 0.3 deg over the segment)";
    final parameter Real s_rest(unit = "m") = 4 "Carriage above its seat, unloaded: the arms at the catch height";
    EquaForgeAerospace.Environment.RotatingEarth earth annotation(Placement(transformation(origin = {-170, -40}, extent = {{-12, -12}, {12, 12}})));
    EquaForgeAerospace.Environment.LaunchSite catchPoint(latitude = lat + 1.5e-6, longitude = lon, altitude = 80 - 62) "Where the booster's frame stops: its pins at the arms" annotation(Placement(transformation(origin = {-120, -100}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.Environment.LaunchSite seat(latitude = lat + 1.5e-6, longitude = lon, altitude = 80 - 4) "The carriage's seat on the tower, 4 m below the arms" annotation(Placement(transformation(origin = {-120, 20}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.JointsAndMotions.Prismatic carriage(n = {1, 0, 0}, initialize = true, s_start = s_rest - (m_carriage + 2*m_arm)*EquaForgeAerospace.g0/c_shock, v_start = 0) "Slides up and down the tower" annotation(Placement(transformation(origin = {-80, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Multibody.ForcesAndMoments.SpringDamper shock(c = c_shock, d = d_shock, s_unstretched = s_rest) "The carriage's shock absorber" annotation(Placement(transformation(origin = {-50, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBody carriageBody(m = m_carriage, I_11 = 2e5, I_22 = 2e5, I_33 = 2e5, g = gTower) annotation(Placement(transformation(origin = {-80, 70}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBodyFrame pivot[2](r = {{0, -armLength/2, 5.5}, {0, -armLength/2, -5.5}}) "The arms' hinges, west of the booster, in line with its pins" annotation(Placement(transformation(origin = {-40, 70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.Sensors.BearingLoad hingeLoad(n = {1, 0, 0}) "What the north arm's hinge carries" annotation(Placement(transformation(origin = {-10, 110}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.JointsAndMotions.Revolute hinge[2](each n = {1, 0, 0}) "The arms swing about the vertical" annotation(Placement(transformation(origin = {20, 70}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.TrapezoidProfile closing[2](distance = {-armOpen, armOpen}, offset = {armOpen, -armOpen}, each vMax = 0.4, each aMax = 0.3, each startTime = tClose) "Close from open to in line with the pins" annotation(Placement(transformation(origin = {-40, 150}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Blocks.FirstOrder smooth[2](each T = 0.2, y_start = {armOpen, -armOpen}) "Smooths the profile's steps in acceleration" annotation(Placement(transformation(origin = {-10, 150}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Mechanics.RotationalPosition armDrive[2] "The arm drives follow the profile" annotation(Placement(transformation(origin = {20, 150}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Sensors.Encoder armEncoder(cpr = 4096, Ts = 0.05) "The north arm's angle as a counter" annotation(Placement(transformation(origin = {60, 150}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBody armBody[2](each m = m_arm, each r_CM = {0, armLength/2, 0}, each I_11 = m_arm*armLength^2/12, each I_22 = 1e4, each I_33 = m_arm*armLength^2/12, each g = gTower) annotation(Placement(transformation(origin = {60, 70}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.BodiesAndFrames.RigidBodyFrame armTop[2](each r = {0, armLength/2, 0}) "The top of each arm's middle, where a pin rests" annotation(Placement(transformation(origin = {60, 30}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.ForcesAndMoments.Contact pinRest[2](each n = {1, 0, 0}, each c = 5e7, each d = 5e6, each d_t = 5e6, each mu = 0.6, each extent = armLength/2) "A pin on its arm (anywhere along it)" annotation(Placement(transformation(origin = {100, 30}, extent = {{-10, -10}, {10, 10}})));
    Booster booster(phase_start = 4, towerHolds = false, r_start = {-543208.1446, -5743086.361, 2813072.326}, v_start = {271.7163761, 1198.637492, -596.0681252}, Q_start = {0.1864435073, 0.1287298481, 0.653808903, -0.72194277}, w_start = {0.0005674538125, 0.0008143279677, -0.001461732665}, m_lox = 89000, m_ch4 = 24461.2) "From the fall at 40 km" annotation(Placement(transformation(origin = {150, -40}, extent = {{-20, -20}, {20, 20}}, rotation = 180)));
    EquaForgeVC.Multibody.BodiesAndFrames.MassProperties noShip(m = 1) "The ship has long gone" annotation(Placement(transformation(origin = {150, -110}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape armShape[2](each shapeType = EquaForgeVC.Visualization.ShapeType.Box, each length = 2, each width = armLength, each height = 2, each position = {-1, armLength/2, 0}, each color = {90, 90, 100}) annotation(Placement(transformation(origin = {100, 100}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape carriageShape(shapeType = EquaForgeVC.Visualization.ShapeType.Box, length = 6, width = 4, height = 16, position = {-1, -armLength/2, 0}, color = {95, 98, 108}) "The carriage the arms hang on" annotation(Placement(transformation(origin = {-120, 70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Environment.LaunchSite pad(latitude = lat, longitude = lon) "The launch pad: the site in the 3-D view hangs from it" annotation(Placement(transformation(origin = {-170, 30}, extent = {{-10, -10}, {10, 10}})));
    LaunchComplex site(latitude = lat, armLength = armLength, arms = false) "The site in the 3-D view (the arms and the carriage are the mechanism's)" annotation(Placement(transformation(origin = {-80, -40}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(earth.frame_b, catchPoint.frame_a);
    connect(earth.motion, catchPoint.earth);
    connect(earth.frame_b, seat.frame_a);
    connect(earth.motion, seat.earth);
    connect(earth.frame_b, pad.frame_a);
    connect(earth.motion, pad.earth);
    connect(pad.frame_b, site.frame_a);
    site.caught = false; // the site's own arms are hidden: these are the mechanism's
    connect(carriage.frame_b, carriageShape.frame_a);
    // the carriage on its shock absorber
    connect(seat.frame_b, carriage.frame_a);
    connect(seat.frame_b, shock.frame_a);
    connect(carriage.frame_b, shock.frame_b);
    connect(carriage.frame_b, carriageBody.frame_a);
    // the arms
    connect(carriage.frame_b, pivot[1].frame_a);
    connect(carriage.frame_b, pivot[2].frame_a);
    connect(pivot[1].frame_b, hingeLoad.frame_a);
    connect(hingeLoad.frame_b, hinge[1].frame_a);
    connect(pivot[2].frame_b, hinge[2].frame_a);
    connect(hinge[1].flange, armEncoder.flange);
    for k in 1:2 loop
      connect(closing[k].s, smooth[k].u);
      connect(smooth[k].y, armDrive[k].phi_ref);
      connect(armDrive[k].flange, hinge[k].flange);
      connect(hinge[k].frame_b, armBody[k].frame_a);
      connect(hinge[k].frame_b, armTop[k].frame_a);
      connect(hinge[k].frame_b, armShape[k].frame_a);
      connect(armTop[k].frame_b, pinRest[k].frame_a);
      connect(pinRest[k].frame_b, booster.pin[k]);
    end for;
    // the booster
    connect(catchPoint.motion, booster.carrier);
    connect(catchPoint.motion, booster.towerCarrier);
    connect(catchPoint.motion, booster.catchTarget);
    connect(noShip.y, booster.shipMass);
    booster.shipLoad.f = zeros(3);
    booster.shipLoad.t = zeros(3);
    annotation(experiment(StartTime = 405, StopTime = 480, Interval = 0.05, Tolerance = 1e-7, __EquaForge_Algorithm = "bdf"),
      Diagram(coordinateSystem(extent = {{-200, -140}, {200, 230}}), graphics = {Text(extent = {{-195, 228}, {195, 168}}, textString = "## Tower catch
The booster's last 75 s with the tower's mechanism: a carriage on a slide (Prismatic) resting on a shock absorber (SpringDamper), two arms on vertical hinges (Revolute) that a trapezoidal profile closes (RotationalPosition, an Encoder counts the angle), and the booster's two pins landing on the arms (Contact). BearingLoad shows what the north hinge carries. The booster is free throughout: it hangs from its pins and swings.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      __EquaForge(plots = {
        Plot(name = "Height above the catch point", curves = {"booster.computer.h"}),
        Plot(name = "Arm angles", curves = {"hinge[1].angle", "hinge[2].angle"}),
        Plot(name = "Pin loads", curves = {"pinRest[1].f_n", "pinRest[2].f_n"}),
        Plot(name = "Carriage", curves = {"carriage.s"}),
        Plot(name = "Hinge bearing", curves = {"hingeLoad.axial", "hingeLoad.radial", "hingeLoad.bending"}),
        Plot(name = "Shock absorber", curves = {"shock.f"})}, plotArrangement = "Grid", linkTime = true,
        animation = Animation(frame = "site.ground", follow = "booster.look.hull", view = "iso")));
  end TowerCatch;
  model OrbitPlanning "The ship's orbit as a point mass from insertion: J2 gravity, an optional circularising burn, three orbits of ground track and the way back to the pad"
    parameter Real r0[3](each unit = "m") = {726291.4323, -5873461.487, 2832163.953} "Position at insertion (FullMission at 460 s)";
    parameter Real v0[3](each unit = "m/s") = {7757.877853, 749.0144402, -461.2265979} "Velocity at insertion";
    parameter Real m(unit = "kg") = 2.95e5 "Mass of the ship with its payload";
    parameter Real tBurn(unit = "s") = 1e9 "Start of a prograde burn (1e9: none)";
    parameter Real dvBurn(unit = "m/s") = 0 "Its velocity change";
    parameter Real F(unit = "N") = 2.65e6 "Thrust of the burn (one engine)";
    parameter Real latPad(unit = "rad", displayUnit = "deg") = 0.45373 "Latitude of the landing pad";
    parameter Real lonPad(unit = "rad", displayUnit = "deg") = -1.69575 "Longitude of the landing pad";
    EquaForgeVC.Multibody.BodiesAndFrames.FreeBody ship(r_start = r0, v_start = v0, r_nominal = 6.6e6, v_nominal = 7.5e3) "The ship, not turning: its frame stays the world frame" annotation(Placement(transformation(origin = {0, 0}, extent = {{-14, -14}, {14, 14}})));
    EquaForgeVC.Multibody.BodiesAndFrames.MassProperties shipMass(m = m, I_11 = 5e6, I_22 = 6e7, I_33 = 6e7) "A point: the thrust acts through the centre of mass, so the ship never turns" annotation(Placement(transformation(origin = {0, -60}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Environment.CentralGravity gravity "Point mass and J2" annotation(Placement(transformation(origin = {-60, 40}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Multibody.ForcesAndMoments.BodyForce burn "The engine, along the velocity while it burns" annotation(Placement(transformation(origin = {-60, -30}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.OrbitalElements orbit annotation(Placement(transformation(origin = {60, 40}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeAerospace.GNC.GroundTrack track(latTarget = latPad, lonTarget = lonPad) annotation(Placement(transformation(origin = {60, -20}, extent = {{-10, -10}, {10, 10}})));
    Real dv(unit = "m/s", start = 0, fixed = true) "Velocity change of the burn so far";
    Boolean burning "The engine runs";
    EquaForgeVC.Multibody.Visualization.AttachedShape marker(shapeType = EquaForgeVC.Visualization.ShapeType.Sphere, length = 150000, color = {240, 140, 40}, trail = 3000) "The ship, drawn 150 km across so it shows beside the Earth" annotation(Placement(transformation(origin = {60, -70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Environment.RotatingEarth earth "The turning Earth: the globe and the pad below the orbit" annotation(Placement(transformation(origin = {-80, -70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape globe(shapeType = EquaForgeVC.Visualization.ShapeType.Sphere, length = 2*EquaForgeAerospace.radiusEarth, color = {45, 100, 170}) "The Earth" annotation(Placement(transformation(origin = {-55, -70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeAerospace.Environment.LaunchSite pad(latitude = latPad, longitude = lonPad) "The landing pad, turning with the Earth" annotation(Placement(transformation(origin = {-30, -70}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Multibody.Visualization.AttachedShape padMarker(shapeType = EquaForgeVC.Visualization.ShapeType.Sphere, length = 300000, color = {220, 40, 40}) "Where the ship has to come home, drawn 300 km across" annotation(Placement(transformation(origin = {30, -85}, extent = {{-6, -6}, {6, 6}})));
  equation
    connect(earth.frame_b, globe.frame_a);
    connect(earth.frame_b, pad.frame_a);
    connect(earth.motion, pad.earth);
    connect(pad.frame_b, padMarker.frame_a);
    connect(shipMass.y, ship.mass);
    connect(ship.frame_a, gravity.frame_a);
    connect(gravity.g, ship.g);
    connect(ship.frame_a, burn.frame_b);
    connect(ship.motion, orbit.vehicle);
    connect(ship.motion, track.vehicle);
    connect(ship.frame_a, marker.frame_a);
    burning = time >= tBurn and dv < dvBurn;
    der(dv) = if burning then F/m else 0;
    burn.f = if burning then F*ship.motion.v/sqrt(ship.motion.v*ship.motion.v) else zeros(3);
    annotation(experiment(StartTime = 460, StopTime = 17000, Interval = 10, Tolerance = 1e-10, __EquaForge_Algorithm = "ck45"),
      Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-95, 98}, {95, 70}}, textString = "## Orbit planning\nThe ship after insertion as a point in J2 gravity (FreeBody, CentralGravity): its orbital elements and ground track over three orbits. A prograde burn (BodyForce) at tBurn with dvBurn tries a Hohmann raise; the worksheet finds the pass that returns to the pad.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      __EquaForge(plots = {
        Plot(name = "Apoapsis and periapsis", curves = {"orbit.apoapsis", "orbit.periapsis"}),
        Plot(name = "Node and perigee", curves = {"orbit.raan", "orbit.argPeriapsis"}),
        Plot(name = "Ground track", curves = {"track.latitude", "track.longitude"}),
        Plot(name = "Distance to the pad", curves = {"track.distance"})}, plotArrangement = "Grid", linkTime = true));
  end OrbitPlanning;

  model AutopilotPlant "The ship's pitch on one engine in the landing burn, for linearisation: gimbal command in, tilt and drift out"
    parameter Real thrust(unit = "N") = 2.2e6 "Thrust of the landing engine";
    parameter Real lever(unit = "m") = 24.6 "From the gimbal to the centre of mass";
    parameter Real J(unit = "kg.m2") = 3.4e7 "Pitch inertia";
    parameter Real m(unit = "kg") = 1.5e5 "Mass";
    parameter Real wAct(unit = "rad/s") = 20 "Bandwidth of the gimbal actuator";
    EquaForgeVC.Interfaces.RealInput gimbalCommand(unit = "rad") "Commanded gimbal angle" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
    EquaForgeVC.Interfaces.RealOutput tilt(unit = "rad") "Tilt of the ship from the vertical" annotation(Placement(transformation(extent = {{100, 30}, {120, 50}})));
    EquaForgeVC.Interfaces.RealOutput drift(unit = "m/s") "Sideways speed" annotation(Placement(transformation(extent = {{100, -50}, {120, -30}})));
    EquaForgeVC.Blocks.SecondOrder actuator(w = wAct, D = 0.9) "Gimbal actuator" annotation(Placement(transformation(origin = {-70, 0}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Blocks.Gain gimbalMoment(k = -thrust*lever) "Moment of the thrust's side component about the centre of mass" annotation(Placement(transformation(origin = {-30, 0}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Mechanics.Torque torque annotation(Placement(transformation(origin = {0, 0}, extent = {{-8, -8}, {8, 8}})));
    EquaForgeVC.Mechanics.Inertia body(J = J) "The ship in pitch" annotation(Placement(transformation(origin = {30, 0}, extent = {{-10, -10}, {10, 10}})));
    EquaForgeVC.Mechanics.AngleSensor angle annotation(Placement(transformation(origin = {65, 40}, extent = {{-8, -8}, {8, 8}})));
    Real v(unit = "m/s", start = 0, fixed = true) "Sideways speed";
  equation
    connect(gimbalCommand, actuator.u);
    connect(actuator.y, gimbalMoment.u);
    connect(gimbalMoment.y, torque.tau);
    connect(torque.flange, body.flange_a);
    connect(body.flange_b, angle.flange);
    connect(angle.phi, tilt);
    // the thrust leans by the tilt plus the gimbal angle: its side component pushes the ship (the gimbal's own push
    // comes first and the wrong way, the tail swinging out before the nose turns)
    m*der(v) = thrust*(tilt + actuator.y);
    drift = v;
    annotation(experiment(StopTime = 10, Interval = 0.01),
      Diagram(coordinateSystem(extent = {{-100, -60}, {120, 110}}), graphics = {Text(extent = {{-95, 108}, {115, 72}}, textString = "## Autopilot plant\nThe ship on one engine as the attitude loop sees it: the gimbal actuator (SecondOrder), the moment of the thrust's side component (Gain, Torque) on the pitch inertia (Inertia), and the sideways speed the tilted thrust gives. ef.linearize turns it into the transfer functions the worksheet designs the loop on.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      __EquaForge(plots = {
        Plot(name = "Tilt", curves = {"tilt"}),
        Plot(name = "Drift", curves = {"drift"}),
        Plot(name = "Gimbal", curves = {"actuator.y"})}, plotArrangement = "Grid", linkTime = true));
  end AutopilotPlant;

  model Descent3DOF "The landing burn as a point mass in the vertical plane: the problem ef.optimal_control solves for the least propellant"
    parameter Real Fmax(unit = "N") = 2.5e6 "Full thrust of the landing engine at sea level";
    parameter Real Isp(unit = "s") = 330 "Specific impulse at sea level";
    parameter Real x0(unit = "m") = -120 "Start: downrange of the pad";
    parameter Real h0(unit = "m") = 700 "Start: height";
    parameter Real vx0(unit = "m/s") = 12 "Start: sideways speed";
    parameter Real vh0(unit = "m/s") = -65 "Start: vertical speed";
    parameter Real m0(unit = "kg") = 1.55e5 "Start: mass";
    EquaForgeVC.Interfaces.RealInput throttle(start = 0.7) "Share of full thrust (0.4 to 1)" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
    EquaForgeVC.Interfaces.RealInput tilt(unit = "rad", start = 0) "Thrust direction from the vertical" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
    Real x(unit = "m", start = x0, fixed = true) "Downrange of the pad";
    Real h(unit = "m", start = h0, fixed = true) "Height";
    Real vx(unit = "m/s", start = vx0, fixed = true) "Sideways speed";
    Real vh(unit = "m/s", start = vh0, fixed = true) "Vertical speed";
    Real m(unit = "kg", start = m0, fixed = true, nominal = 1e5) "Mass";
  equation
    der(x) = vx;
    der(h) = vh;
    der(vx) = Fmax*throttle*sin(tilt)/m;
    der(vh) = Fmax*throttle*cos(tilt)/m - EquaForgeAerospace.g0;
    der(m) = -Fmax*throttle/(Isp*EquaForgeAerospace.g0);
    annotation(experiment(StopTime = 20, Interval = 0.1),
      Diagram(graphics = {Text(extent = {{-90, 92}, {90, 10}}, textString = "## Fuel-optimal landing burn\nA point mass in the vertical plane, written as equations: der(x) = vx, der(h) = vh, der(vx) = Fmax throttle sin(tilt)/m, der(vh) = Fmax throttle cos(tilt)/m - g, der(m) = -Fmax throttle/(Isp g). Its two inputs are what ef.optimal_control chooses in the worksheet: the throttle and the tilt that bring it to rest on the pad with the most propellant left.", fontSize = 8, horizontalAlignment = TextAlignment.Left, textColor = {0, 0, 0}, __EquaForgeKind = "note", __EquaForgeTheme = true)}),
      Documentation(info = "<html><p>Point mass, thrust along a commanded direction, flat ground, no air. The worksheet asks for the throttle and tilt that bring it to rest on the pad with the most propellant left, and sweeps the burn time.</p></html>"),
      __EquaForge(plots = {
        Plot(name = "Height", curves = {"h"}),
        Plot(name = "Speeds", curves = {"vh", "vx"}),
        Plot(name = "Mass", curves = {"m"})}, plotArrangement = "Grid", linkTime = true));
  end Descent3DOF;
  annotation(Documentation(info = "<html><p>A StarVessel round trip on the turning Earth, from the pad to orbit and back: the booster returns to the tower that launched it and is caught in its arms, the ship lands on its legs beside it after most of an orbit. Both stages are 6-DOF free bodies with their propellant feed, engines, actuators, aerodynamics, heat shield and flight computers, built from <code>EquaForgeVC.Multibody</code> and <code>EquaForgeAerospace</code>.</p><p>The vehicle data are illustrative, rounded from public estimates for a fully reusable two-stage launcher; they are not any manufacturer's data.</p><p>Start with <code>FullMission</code> (the whole flight, its 3-D view) and the worksheet <code>StarVesselMission_Analysis.ipynb</code> beside this file. The other models are its segments: <code>AscentToOrbit</code>, <code>BoosterReturn</code>, <code>TowerCatch</code>, <code>OrbitPlanning</code>, <code>ShipEntryLanding</code>, and the reduced models <code>AutopilotPlant</code> (linearisation) and <code>Descent3DOF</code> (optimal control).</p></html>"));
end StarVesselMission;

within ;
package Dymola_Skill_Tutorial
  "Dymola Modeling Skills"
  extends Modelica.Icons.Package;
  //Get the system path of current package
  constant String LibrarySystemPath=classDirectory();
  package Example_1
    extends Modelica.Icons.ExamplesPackage;
    model Test1 "Test Model"
      extends Modelica.Icons.Example;
      parameter Real a=1;
        Real x;
        Real y;
    protected
        parameter Real table[:, :]=ones(300, 100);
    equation
        x = a*sum(table);
        x = der(y);
      annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
            coordinateSystem(preserveAspectRatio=false)));
    end Test1;
  end Example_1;

  package Example_2
    extends Modelica.Icons.ExamplesPackage;
    model PumpingSystem "Model of a pumping system for drinking water"
      extends Modelica.Icons.Example;

      replaceable package Medium = Modelica.Media.Water.StandardWaterOnePhase
        constrainedby Modelica.Media.Interfaces.PartialMedium;
      //replaceable package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater
      //  constrainedby Modelica.Media.Interfaces.PartialMedium;

      Modelica.Fluid.Sources.FixedBoundary source(
        nPorts = 1,
        use_T=true,
        T=Modelica.SIunits.Conversions.from_degC(20),
        p=system.p_ambient,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{-100,-80},{-80,-60}})));

      Modelica.Fluid.Pipes.StaticPipe pipe(
        allowFlowReversal=true,
        length=100,
        height_ab=50,
        diameter=0.3,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(
            origin={-30,-51},
            extent={{-9,-10},{11,10}},
            rotation=90)));

      Modelica.Fluid.Machines.PrescribedPump pumps(
        checkValve=true,
        N_nominal=1200,
        redeclare function flowCharacteristic =
            Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow
            (V_flow_nominal={0,0.25,0.5}, head_nominal={100,60,0}),
        use_N_in=true,
        nParallel=1,
        energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
        V(displayUnit="l") = 0.05,
        massDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
        redeclare package Medium = Medium,
        p_b_start=600000,
        T_start=system.T_start)
        annotation (Placement(transformation(extent={{-68,-80},{-48,-60}})));

      Modelica.Fluid.Vessels.OpenTank reservoir(
        T_start=Modelica.SIunits.Conversions.from_degC(20),
        use_portsData=true,
        crossArea=50,
        level_start=2.2,
        height=3,
        nPorts=3,
        portsData={Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter=0.3),
            Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter=0.3),
            Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter=0.01)},
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{-20,-16},{0,4}})));

      Modelica.Fluid.Valves.ValveLinear userValve(
        allowFlowReversal=false,
        dp_nominal=200000,
        m_flow_nominal=400,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{58,-38},{74,-22}})));
      Modelica.Fluid.Sources.FixedBoundary sink(
        p=system.p_ambient,
        T=system.T_ambient,
        nPorts=2,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{100,-40},{80,-20}})));
      Modelica.Blocks.Sources.Step valveOpening(startTime=200, offset=1e-6)
        annotation (Placement(transformation(extent={{56,0},{76,20}})));
      Modelica.Blocks.Sources.Constant RelativePressureSetPoint(k=2e4)
        annotation (Placement(transformation(extent={{-100,60},{-80,80}})));
      Modelica.Blocks.Logical.OnOffController controller(bandwidth=4000,
          pre_y_start=false)
                            annotation (Placement(transformation(extent={{-40,60},{
                -20,80}})));
      Modelica.Blocks.Logical.TriggeredTrapezoid PumpRPMGenerator(
        rising=3,
        falling=3,
        amplitude=1200,
        offset=0.001) annotation (Placement(transformation(extent={{0,60},{20,80}})));
      Modelica.Fluid.Sensors.RelativePressure reservoirPressure(redeclare
          package Medium =
                   Medium)
        annotation (Placement(transformation(extent={{10,-12},{30,-32}})));
      Modelica.Blocks.Continuous.FirstOrder PT1(
        T=2,
        initType=Modelica.Blocks.Types.Init.InitialState,
        y_start=0)
        annotation (Placement(transformation(extent={{40,60},{60,80}})));

      inner Modelica.Fluid.System system(energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial)
                                       annotation (Placement(transformation(extent=
                {{60,-96},{80,-76}})));
    equation
      connect(userValve.port_b, sink.ports[1]) annotation (Line(points={{74,-30},
              {77,-30},{77,-28},{80,-28}}, color={0,127,255}));
      connect(source.ports[1], pumps.port_a) annotation (Line(points={{-80,-70},{
              -74,-70},{-68,-70}}, color={0,127,255}));
      connect(valveOpening.y, userValve.opening) annotation (Line(points={{77,10},{
              98,10},{98,-12},{66,-12},{66,-23.6}}, color={0,0,127}));
      connect(RelativePressureSetPoint.y, controller.reference)
                                                        annotation (Line(points={{
              -79,70},{-60,70},{-60,76},{-42,76}}, color={0,0,127}));
      connect(controller.y, PumpRPMGenerator.u)
        annotation (Line(points={{-19,70},{-2,70}}, color={255,0,255}));
      connect(reservoirPressure.p_rel, controller.u) annotation (Line(points={{20,
              -13},{20,50},{-52,50},{-52,64},{-42,64}}, color={0,0,127}));
      connect(reservoirPressure.port_b, sink.ports[2]) annotation (Line(
          points={{30,-22},{44,-22},{44,-48},{80,-48},{80,-32}},
          color={0,127,255},
          pattern=LinePattern.Dot));
      connect(PumpRPMGenerator.y, PT1.u)
        annotation (Line(points={{21,70},{38,70}}, color={0,0,127}));
      connect(PT1.y, pumps.N_in) annotation (Line(points={{61,70},{74,70},{74,30},{
              -58,30},{-58,-60}}, color={0,0,127}));
      connect(pipe.port_a, pumps.port_b) annotation (Line(points={{-30,-60},
              {-30,-70},{-48,-70}}, color={0,127,255}));
      connect(reservoir.ports[1], pipe.port_b) annotation (Line(
          points={{-12.6667,-16},{-12.6667,-30},{-30,-30},{-30,-40}}, color={0,127,255}));
      connect(reservoir.ports[3], reservoirPressure.port_a) annotation (Line(
          points={{-7.33333,-16},{-7,-16},{-7,-22},{10,-22}},
          color={0,127,255},
          pattern=LinePattern.Dot));
      connect(reservoir.ports[2], userValve.port_a) annotation (Line(
          points={{-10,-16},{-10,-30},{58,-30}}, color={0,127,255}));
      annotation (
        Documentation(info="<html>
<p>
Water is pumped from a source by a pump (fitted with check valves), through a pipe whose outlet is 50 m higher than the source, into a reservoir. The users are represented by an equivalent valve, connected to the reservoir.
</p>
<p>
The water controller is a simple on-off controller, regulating on the gauge pressure measured at the base of the tower; the output of the controller is the rotational speed of the pump, which is represented by the output of a first-order system. A small but nonzero rotational speed is used to represent the standby state of the pumps, in order to avoid singularities in the flow characteristic.
</p>
<p>
Simulate for 2000 s. When the valve is opened at time t=200, the pump starts turning on and off to keep the reservoir level around 2 meters, which roughly corresponds to a gauge pressure of 200 mbar.
</p>

<img src=\"modelica://Modelica/Resources/Images/Fluid/Examples/PumpingSystem.png\" border=\"1\"
     alt=\"PumpingSystem.png\">
</html>",     revisions="<html>
<ul>
<li><em>Jan 2009</em>
    by R&uuml;diger Franke:<br>
       Reduce diameters of pipe and reservoir ports; use separate port for measurement of reservoirPressure, avoiding disturbances due to pressure losses.</li>
<li><em>1 Oct 2007</em>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Parameters updated.</li>
<li><em>2 Nov 2005</em>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Created.</li>
</ul>
</html>"),
        experiment(
          StopTime=2000,
          Interval=0.4,
          Tolerance=1e-006));
    end PumpingSystem;
  end Example_2;

  package Example_3
    extends Modelica.Icons.ExamplesPackage;
    model Test3_1
      extends Modelica.Icons.Example;
      Modelica.Blocks.Tables.CombiTable1D combiTable1D(
        tableOnFile=true,
        tableName="data",
        fileName=LibrarySystemPath + "data/Test3.txt",
        columns={2})
        annotation (Placement(transformation(extent={{32,0},{52,20}})));
      Modelica.Blocks.Sources.Clock clock
        annotation (Placement(transformation(extent={{-50,0},{-30,20}})));
    equation
      connect(clock.y, combiTable1D.u[1]) annotation (Line(
          points={{-29,10},{30,10}},
          color={0,0,127},
          smooth=Smooth.None));
    end Test3_1;

    model Test3_2
      extends Modelica.Icons.Example;
      Modelica.Blocks.Tables.CombiTable1D combiTable1D(
        tableOnFile=false,
        table=csvfile.getRealArray2D(3, 2),
        tableName="data",
        fileName=LibrarySystemPath + "data/Test3.txt",
        columns={2})
        annotation (Placement(transformation(extent={{36,8},{56,28}})));
      Modelica.Blocks.Sources.Clock clock
        annotation (Placement(transformation(extent={{-46,8},{-26,28}})));
      inner parameter ExternData.CSVFile csvfile(fileName=
            Modelica.Utilities.Files.loadResource(
            "modelica://Dymola_Skill_Tutorial/data/Test3.csv"))                                                                                       "CSV file" annotation(Placement(transformation(extent={{-48,-30},
                {-28,-10}})));
    equation
      connect(clock.y, combiTable1D.u[1]) annotation (Line(
          points={{-25,18},{34,18}},
          color={0,0,127},
          smooth=Smooth.None));
    end Test3_2;
  end Example_3;

  package Example_4
    extends Modelica.Icons.ExamplesPackage;
    function MyFunction "Opens some other libraries"
      extends Modelica.Icons.Function;
      // Script to Open Some Other Libraries
    algorithm
      //Specify Library Path
      DymolaCommands.SimulatorAPI.openModel(
          LibrarySystemPath+"FailureModes\package.mo", changeDirectory=false);
    annotation(__Dymola_interactive=true);
    end MyFunction;

    function MyFunctionshortcut =
      Dymola_Skill_Tutorial.Example_4.MyFunction
    annotation ();
    function DymolaCommandshortcut =
      DymolaCommands.SimulatorAPI.openModel (
          path=LibrarySystemPath+"FailureModes\package.mo", changeDirectory=false)
    annotation ();
  end Example_4;

  package Example_5
    extends Modelica.Icons.ExamplesPackage;

    model DynamicEffect
      extends Modelica.Icons.Example;
      Modelica.Blocks.Tables.CombiTable1D combiTable1D(
        tableOnFile=true,
        tableName="data",
        fileName=LibrarySystemPath + "data/Test3.txt",
        columns={2})
        annotation (Placement(transformation(extent={{32,0},{52,20}})));
      Modelica.Blocks.Sources.Clock clock
        annotation (Placement(transformation(extent={{-50,0},{-30,20}})));
    equation
      connect(clock.y, combiTable1D.u[1]) annotation (Line(
          points={{-29,10},{30,10}},
          color={0,0,127},
          smooth=Smooth.None));
      annotation (Diagram(graphics={Rectangle(
              extent={{-44,-24},{34,-68}},
              lineColor={28,108,200},
              fillColor=DynamicSelect({28,108,200},{28,108,combiTable1D.y[1]*200}),
              fillPattern=FillPattern.Solid)}));
    end DynamicEffect;
  end Example_5;

  package Example_6
    extends Modelica.Icons.ExamplesPackage;
    model Test6_1 "Test Model"
      extends Modelica.Icons.Example;
      parameter Real a=1;
      parameter Real b=1;
        Real x;
        Real y;
    protected
        parameter Real table[:,:]= ones(300, 100);
    equation
        x = a*sum(table);
        x = b*der(y);
      annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
            coordinateSystem(preserveAspectRatio=false)));
    end Test6_1;

    model Test6_2
      extends Test6_1(a=2);
    end Test6_2;

    model Test6_3
      extends Test6_2(b=2);
    end Test6_3;

    model PumpingSystem "Model of a pumping system for drinking water"
      extends Modelica.Icons.Example;

      replaceable package Medium = Modelica.Media.Water.StandardWaterOnePhase
        constrainedby Modelica.Media.Interfaces.PartialMedium;
      //replaceable package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater
      //  constrainedby Modelica.Media.Interfaces.PartialMedium;

      Modelica.Fluid.Sources.FixedBoundary source(
        nPorts = 1,
        use_T=true,
        T=Modelica.SIunits.Conversions.from_degC(20),
        p=system.p_ambient,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{-100,-80},{-80,-60}})));

      Modelica.Fluid.Pipes.StaticPipe pipe(
        allowFlowReversal=true,
        length=100,
        height_ab=50,
        diameter=0.3,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(
            origin={-30,-51},
            extent={{-9,-10},{11,10}},
            rotation=90)));

      Modelica.Fluid.Machines.PrescribedPump pumps(
        checkValve=true,
        N_nominal=1200,
        redeclare function flowCharacteristic =
            Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow
            (V_flow_nominal={0,0.25,0.5}, head_nominal={100,60,0}),
        use_N_in=true,
        nParallel=1,
        energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
        V(displayUnit="l") = 0.05,
        massDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
        redeclare package Medium = Medium,
        p_b_start=600000,
        T_start=system.T_start)
        annotation (Placement(transformation(extent={{-68,-80},{-48,-60}})));

      Modelica.Fluid.Vessels.OpenTank reservoir(
        T_start=Modelica.SIunits.Conversions.from_degC(20),
        use_portsData=true,
        crossArea=50,
        level_start=2.2,
        height=3,
        nPorts=3,
        portsData={Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter=0.3),
            Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter=0.3),
            Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter=0.01)},
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{-20,-16},{0,4}})));

      Modelica.Fluid.Valves.ValveLinear userValve(
        allowFlowReversal=false,
        dp_nominal=200000,
        m_flow_nominal=400,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{58,-38},{74,-22}})));
      Modelica.Fluid.Sources.FixedBoundary sink(
        p=system.p_ambient,
        T=system.T_ambient,
        nPorts=2,
        redeclare package Medium = Medium)
        annotation (Placement(transformation(extent={{100,-40},{80,-20}})));
      Modelica.Blocks.Sources.Step valveOpening(startTime=200, offset=1e-6)
        annotation (Placement(transformation(extent={{56,0},{76,20}})));
      Modelica.Blocks.Sources.Constant RelativePressureSetPoint(k=2e4)
        annotation (Placement(transformation(extent={{-100,60},{-80,80}})));
      Modelica.Blocks.Logical.OnOffController controller(bandwidth=4000,
          pre_y_start=false)
                            annotation (Placement(transformation(extent={{-40,60},{
                -20,80}})));
      Modelica.Blocks.Logical.TriggeredTrapezoid PumpRPMGenerator(
        rising=3,
        falling=3,
        amplitude=1200,
        offset=0.001) annotation (Placement(transformation(extent={{0,60},{20,80}})));
      Modelica.Fluid.Sensors.RelativePressure reservoirPressure(redeclare
          package Medium =
                   Medium)
        annotation (Placement(transformation(extent={{10,-12},{30,-32}})));
      Modelica.Blocks.Continuous.FirstOrder PT1(
        T=2,
        initType=Modelica.Blocks.Types.Init.InitialState,
        y_start=0)
        annotation (Placement(transformation(extent={{40,60},{60,80}})));

      inner Modelica.Fluid.System system(energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial)
                                       annotation (Placement(transformation(extent=
                {{60,-96},{80,-76}})));
    equation
      connect(userValve.port_b, sink.ports[1]) annotation (Line(points={{74,-30},
              {77,-30},{77,-28},{80,-28}}, color={0,127,255}));
      connect(source.ports[1], pumps.port_a) annotation (Line(points={{-80,-70},{
              -74,-70},{-68,-70}}, color={0,127,255}));
      connect(valveOpening.y, userValve.opening) annotation (Line(points={{77,10},{
              98,10},{98,-12},{66,-12},{66,-23.6}}, color={0,0,127}));
      connect(RelativePressureSetPoint.y, controller.reference)
                                                        annotation (Line(points={{
              -79,70},{-60,70},{-60,76},{-42,76}}, color={0,0,127}));
      connect(controller.y, PumpRPMGenerator.u)
        annotation (Line(points={{-19,70},{-2,70}}, color={255,0,255}));
      connect(reservoirPressure.p_rel, controller.u) annotation (Line(points={{20,
              -13},{20,50},{-52,50},{-52,64},{-42,64}}, color={0,0,127}));
      connect(reservoirPressure.port_b, sink.ports[2]) annotation (Line(
          points={{30,-22},{44,-22},{44,-48},{80,-48},{80,-32}},
          color={0,127,255},
          pattern=LinePattern.Dot));
      connect(PumpRPMGenerator.y, PT1.u)
        annotation (Line(points={{21,70},{38,70}}, color={0,0,127}));
      connect(PT1.y, pumps.N_in) annotation (Line(points={{61,70},{74,70},{74,30},{
              -58,30},{-58,-60}}, color={0,0,127}));
      connect(pipe.port_a, pumps.port_b) annotation (Line(points={{-30,-60},
              {-30,-70},{-48,-70}}, color={0,127,255}));
      connect(reservoir.ports[1], pipe.port_b) annotation (Line(
          points={{-12.6667,-16},{-12.6667,-30},{-30,-30},{-30,-40}}, color={0,127,255}));
      connect(reservoir.ports[3], reservoirPressure.port_a) annotation (Line(
          points={{-7.33333,-16},{-7,-16},{-7,-22},{10,-22}},
          color={0,127,255},
          pattern=LinePattern.Dot));
      connect(reservoir.ports[2], userValve.port_a) annotation (Line(
          points={{-10,-16},{-10,-30},{58,-30}}, color={0,127,255}));
      annotation (
        Documentation(info="<html>
<p>
Water is pumped from a source by a pump (fitted with check valves), through a pipe whose outlet is 50 m higher than the source, into a reservoir. The users are represented by an equivalent valve, connected to the reservoir.
</p>
<p>
The water controller is a simple on-off controller, regulating on the gauge pressure measured at the base of the tower; the output of the controller is the rotational speed of the pump, which is represented by the output of a first-order system. A small but nonzero rotational speed is used to represent the standby state of the pumps, in order to avoid singularities in the flow characteristic.
</p>
<p>
Simulate for 2000 s. When the valve is opened at time t=200, the pump starts turning on and off to keep the reservoir level around 2 meters, which roughly corresponds to a gauge pressure of 200 mbar.
</p>

<img src=\"modelica://Modelica/Resources/Images/Fluid/Examples/PumpingSystem.png\" border=\"1\"
     alt=\"PumpingSystem.png\">
</html>",     revisions="<html>
<ul>
<li><em>Jan 2009</em>
    by R&uuml;diger Franke:<br>
       Reduce diameters of pipe and reservoir ports; use separate port for measurement of reservoirPressure, avoiding disturbances due to pressure losses.</li>
<li><em>1 Oct 2007</em>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Parameters updated.</li>
<li><em>2 Nov 2005</em>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Created.</li>
</ul>
</html>"),
        experiment(
          StopTime=2000,
          Interval=0.4,
          Tolerance=1e-006));
    end PumpingSystem;

    model HighPass "High-pass filter"
      extends Modelica.Icons.Example;
      import Modelica.Constants.pi;
      parameter Modelica.SIunits.Voltage Vps=+15 "Positive supply";
      parameter Modelica.SIunits.Voltage Vns=-15 "Negative supply";
      parameter Modelica.SIunits.Voltage Vin=5 "Amplitude of input voltage";
      parameter Modelica.SIunits.Frequency f=10 "Frequency of input voltage";
      parameter Real k=1 "Desired amplification";
      parameter Modelica.SIunits.Resistance R1=1000 "Arbitrary resistance";
      parameter Modelica.SIunits.Resistance R2=k*R1
        "Calculated resistance to reach k";
      parameter Modelica.SIunits.Frequency fG=f/10
        "Limiting frequency, as an example coupled to f";
      parameter Modelica.SIunits.Capacitance C=1/(2*pi*fG*R1)
        "Calculated capacitance to reach fG";
      Modelica.Electrical.Analog.Ideal.IdealizedOpAmpLimted opAmp(
        Vps=Vps,
        Vns=Vns,
        out(i(start=0)))
        annotation (Placement(transformation(extent={{22,10},{42,30}})));
      Modelica.Electrical.Analog.Basic.Ground ground
        annotation (Placement(transformation(extent={{2,-80},{22,-60}})));
      Modelica.Electrical.Analog.Sources.TrapezoidVoltage vIn(
        rising=0.2/f,
        width=0.3/f,
        falling=0.2/f,
        period=1/f,
        nperiod=-1,
        startTime=-(vIn.rising + vIn.width/2),
        V=Vin,
        offset=0) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-58,20})));
      Modelica.Electrical.Analog.Sensors.VoltageSensor vOut annotation (Placement(
            transformation(
            extent={{-10,10},{10,-10}},
            rotation=270,
            origin={72,0})));
      Modelica.Electrical.Analog.Basic.Resistor r1(R=R1)
        annotation (Placement(transformation(extent={{-18,40},{2,60}})));
      Modelica.Electrical.Analog.Basic.Resistor r2(R=R2)
        annotation (Placement(transformation(extent={{42,40},{22,60}})));
      Modelica.Electrical.Analog.Basic.Capacitor c(C=C, v(fixed=true, start=0))
        annotation (Placement(transformation(extent={{-48,40},{-28,60}})));
    equation
      connect(r1.n, r2.n) annotation (Line(
          points={{2,50},{22,50}},  color={0,0,255}));
      connect(r2.n, opAmp.in_n) annotation (Line(
          points={{22,50},{12,50},{12,26},{22,26}},
                                                  color={0,0,255}));
      connect(r2.p, opAmp.out) annotation (Line(
          points={{42,50},{52,50},{52,20},{42,20}},
                                                  color={0,0,255}));
      connect(c.n, r1.p) annotation (Line(
          points={{-28,50},{-18,50}}, color={0,0,255}));
      connect(ground.p, opAmp.in_p) annotation (Line(
          points={{12,-60},{12,14},{22,14}},  color={0,0,255}));
      connect(vIn.p, c.p) annotation (Line(
          points={{-58,30},{-58,50},{-48,50}}, color={0,0,255}));
      connect(ground.p, vIn.n) annotation (Line(
          points={{12,-60},{-58,-60},{-58,10}},   color={0,0,255}));
      connect(opAmp.out, vOut.p) annotation (Line(
          points={{42,20},{72,20},{72,10}},color={0,0,255}));
      connect(ground.p, vOut.n) annotation (Line(
          points={{12,-60},{72,-60},{72,-10}},  color={0,0,255}));
      annotation (Documentation(info=
                     "<html>
                         <p>This is a (inverting) high pass filter. Resistance R1 can be chosen, resistance R2 is defined by the desired amplification k, capacitance C is defined by the desired cut-off frequency.</p>
                         <p>The example is taken from: U. Tietze and C. Schenk, Halbleiter-Schaltungstechnik (German), 11th edition, Springer 1999, Chapter 13.3</p>
                         </html>"),
        experiment(
          StartTime=0,
          StopTime=1,
          Tolerance=1e-006,
          Interval=0.001));
    end HighPass;
  end Example_6;

  package Example_7
    extends Modelica.Icons.ExamplesPackage;
    model Test7 "Test Model"
      extends Modelica.Icons.Example;
      parameter Real a=1;
      parameter Real b=1;
      parameter Real ma[2,2]=[1,2;
                              2,3];
        Real x;
        Real y;
    protected
        parameter Real table[:,:]= ones(300, 100);
    equation
        x = a*sum(table);
        x = b*der(y);
    algorithm
      when terminal() then
        Modelica.Utilities.Streams.print("Simulation result was:"+String(x), "Test7.txt");
        Modelica.Utilities.Streams.writeRealMatrix("Test7_1.mat","mA",ma);
        KeyWordIO.writeRealVariables("Test7.csv",{"a"},{a},append=true);
      end when;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
            coordinateSystem(preserveAspectRatio=false)));
    end Test7;
  end Example_7;

  package Example_8 "AutomateModelExperimentation"
    extends Modelica.Icons.ExamplesPackage;
    model ModularRC "Model of molular RC circuit"
      extends Modelica.Icons.Example;
      //Added Section
      output Modelica.SIunits.Voltage V_in "Input voltage";
      output Modelica.SIunits.Voltage V_R "Resistor voltage";
      output Modelica.SIunits.Voltage V_C "Capacitor voltage";

      Modelica.Electrical.Analog.Basic.Resistor Resistance(
        alpha=1e-3,
        i(start=0),
        useHeatPort=false,
        R=1,
        T_ref=293.15) annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=0,
            origin={-22,20})));
      Modelica.Electrical.Analog.Basic.Ground G annotation (Placement(
            transformation(extent={{-10,-54},{10,-34}}, rotation=0)));
      Modelica.Electrical.Analog.Sources.CosineVoltage Vin(freqHz=0, V=4.2) annotation (
          Placement(transformation(
            origin={-50,0},
            extent={{-10,-10},{10,10}},
            rotation=270)));

      Modelica.Electrical.Analog.Basic.Capacitor capacitor(C=1)
        annotation (Placement(transformation(extent={{10,10},{30,30}})));
      Modelica.Electrical.Analog.Sensors.VoltageSensor VR annotation (Placement(
            transformation(
            extent={{10,-10},{-10,10}},
            rotation=180,
            origin={-22,48})));
      Modelica.Electrical.Analog.Sensors.VoltageSensor VC annotation (Placement(
            transformation(
            extent={{10,-10},{-10,10}},
            rotation=180,
            origin={20,48})));
    equation

      //Added Section
      V_in = Vin.v;
      V_R = VR.v;
      V_C = VC.v;

      connect(Vin.n, G.p) annotation (Line(points={{-50,-10},{-50,-20},{0,-20},{0,-34}},
            color={0,0,255}));

      connect(Vin.p, Resistance.p) annotation (Line(
          points={{-50,10},{-50,20},{-32,20}},
          color={0,0,255},
          smooth=Smooth.None));

      connect(Resistance.n, capacitor.p)
        annotation (Line(points={{-12,20},{-12,20},{10,20}}, color={0,0,255}));
      connect(capacitor.n, G.p) annotation (Line(points={{30,20},{40,20},{40,-20},{
              0,-20},{0,-34}}, color={0,0,255}));
      connect(VC.p, capacitor.p)
        annotation (Line(points={{10,48},{4,48},{4,20},{10,20}}, color={0,0,255}));
      connect(VC.n, G.p) annotation (Line(points={{30,48},{36,48},{36,20},{40,20},{
              40,-20},{0,-20},{0,-34}}, color={0,0,255}));
      connect(VR.p, Resistance.p) annotation (Line(points={{-32,48},{-40,48},{-40,
              20},{-32,20}}, color={0,0,255}));
      connect(VR.n, capacitor.p) annotation (Line(points={{-12,48},{-6,48},{-6,20},
              {10,20}},color={0,0,255}));
      annotation (
        Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                100}}), graphics={Text(
              extent={{-40,-62},{32,-70}},
              lineColor={0,0,255},
              textString="Linear RC Circuit")}),
        Documentation(info="<html>
<p>A simple resistor-capacitor (RC) circuit consists of a resistor (R), a capacitor (C) and an input voltage (V<sub>in</sub>). The electrical elements (components) of this circuit are linear. This model is created for the article</p>
</html>"),
        experiment(StopTime=30, Tolerance=1e-005),
        __Dymola_experimentSetupOutput);
    end ModularRC;

    function ModelExperiment

      // Define model to be experimented
      input String modelName=
          "Dymola_Skill_Tutorial.Example_8.ModularRC"
        "Model to be simulated" annotation (dialog(enable=false));
      // Define input parameters to be modified during iteration
      input Modelica.SIunits.Voltage Vin_v=4.2 "Input voltage";
      input Modelica.SIunits.Frequency Vin_freqHz[:]={0,0.03183,1.59}
        "Excitation frequency";
      input Real ts=30 "Simulation time [s]";

      // Define protected variables
    protected
      Boolean translate;

    algorithm

      //Step 1: Translate the model
      translate := translateModel(modelName);

      // Step 2: Check the selected model is top-level model
      if translate then
        Modelica.Utilities.Streams.print("\n");
        Modelica.Utilities.Streams.print("Baseline translation successful");
        Modelica.Utilities.Streams.print("\n");

      end if;

      //Step 3: Run a parametric sweep with input variable, Vin_freqHz
      //& Store result files of each iteration separately

      for i in 1:size(Vin_freqHz, 1) loop
        simulateExtendedModel(
          modelName,
          stopTime=ts,
          method="dassl",
          outputInterval=1e-3,
          initialNames={"Vin.freqHz","Vin.V"},
          initialValues={Vin_freqHz[i],Vin_v},
          resultFile="Result " + String(i));
      end for;

      // Create a Plot Setup //
      // 1. Remove any existing plot window
      removePlots();
      Advanced.FilenameInLegend := false;
      Advanced.SequenceInLegend := true;
      Advanced.PlotLegendTooltip := true;
      Advanced.ShowPlotTooltip := true;
      Advanced.FullPlotTooltip := true;
      Advanced.DefaultAutoErase := true;
      Advanced.Legend.Horizontal := true;
      Advanced.Legend.Frame := false;
      Advanced.Legend.Transparent := true;
      Advanced.Legend.Location := 1;
      // 2. Plot Steady-State simulation
      createPlot(
        id=1,
        position={(-3),(-28),784,514},
        y={"V_in","V_R","V_C"},
        heading="Steady-State Simulation",
        range={0,20.0,1.5,(-0.5)},
        autoscale=true,
        autoerase=false,
        autoreplot=true,
        description=false,
        legends={"Vin","VR","VC"},
        color=true,
        online=false,
        filename="Result 1.mat",
        leftTitle="Voltage [v]",
        bottomTitle="Time [s]",
        leftTitleType=1,
        bottomTitleType=1);

      // 3. Low Frequency Input Simulation
      createPlot(
        id=2,
        position={(-3),(-28),784,514},
        y={"V_in","V_R","V_C"},
        heading="Low Frequency Input Simulation",
        range={0,20.0,1.5,(-0.5)},
        autoscale=true,
        autoerase=false,
        autoreplot=true,
        description=false,
        legends={"Vin","VR","VC"},
        color=true,
        online=false,
        filename="Result 2.mat",
        leftTitle="Voltage [v]",
        bottomTitle="Time [s]",
        leftTitleType=1,
        bottomTitleType=1);

      // 4. High Frequency Input Simulation
      createPlot(
        id=3,
        position={(-3),(-28),784,514},
        y={"V_in","V_R","V_C"},
        heading="High Frequency Input Simulation",
        range={0,20.0,1.5,(-0.5)},
        autoscale=true,
        autoerase=false,
        autoreplot=true,
        description=false,
        legends={"Vin","VR","VC"},
        color=true,
        online=false,
        filename="Result 3.mat",
        leftTitle="Voltage [v]",
        bottomTitle="Time [s]",
        leftTitleType=1,
        bottomTitleType=1);

      annotation (__Dymola_interactive=true, __Dymola_Commands(file=
              "Scripts/Steady-State.mos" "Steady-State", file=
              "Scripts/Steady-State.mos" "Steady-State"),
        Documentation(info="<html>
<p>Flow chart of the \"ModelExperiment\" function.</p>
<p>
<img src=\"modelica://Dymola_Skill_Tutorial/data/AutomationWorkFlow.png\">
</p>
</html>"));
    end ModelExperiment;
  annotation (                                 Documentation(info="<html>
<p>This Modelica package is created for illustration about how to automate experiment workflow.</p>
</html>"),   conversion(noneFromVersion=""));
  end Example_8;

  package CompareText
    "An example show how to use text editor to compare differences in two models"
    extends Modelica.Icons.ExamplesPackage;
    model Failure
      extends Modelica.Icons.Example;
      Modelica.Fluid.Sources.FixedBoundary inletBoundary(
        p=500000,
        T=298.15,
        redeclare package Medium = Medium,
        nPorts=1)
        annotation (Placement(transformation(extent={{-66,-12},{-46,8}})));
      replaceable package Medium = Modelica.Media.Water.StandardWater annotation (
          __Dymola_choicesAllMatching=true);
      Modelica.Fluid.Sources.FixedBoundary outletBoundary1(
        p=500000,
        T=298.15,
        redeclare package Medium = Medium,
        nPorts=1) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={70,-2})));
      inner Modelica.Fluid.System system(allowFlowReversal=false, m_flow_start=10)
        annotation (Placement(transformation(extent={{50,14},{70,34}})));
      Modelica.Fluid.Machines.PrescribedPump pump(
        redeclare package Medium = Medium,
        p_b_start=600000,
        redeclare function flowCharacteristic =
            Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow,
        N_nominal=1200,
        checkValve=true,
        V=50,
        energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
        massDynamics=Modelica.Fluid.Types.Dynamics.DynamicFreeInitial)
        annotation (Placement(transformation(extent={{-10,-12},{10,8}})));
    equation
      connect(inletBoundary.ports[1], pump.port_a)
        annotation (Line(points={{-46,-2},{-10,-2}}, color={0,127,255}));
      connect(pump.port_b, outletBoundary1.ports[1])
        annotation (Line(points={{10,-2},{60,-2}}, color={0,127,255}));
      annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
            coordinateSystem(preserveAspectRatio=false)));
    end Failure;

    model Success
      extends Modelica.Icons.Example;
      Modelica.Fluid.Sources.FixedBoundary inletBoundary(
        p=500000,
        T=298.15,
        redeclare package Medium = Medium,
        nPorts=1)
        annotation (Placement(transformation(extent={{-70,-8},{-50,12}})));
      replaceable package Medium = Modelica.Media.Water.StandardWater annotation (
          __Dymola_choicesAllMatching=true);
      Modelica.Fluid.Sources.FixedBoundary outletBoundary(
        p=500000,
        T=298.15,
        redeclare package Medium = Medium,
        nPorts=1) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={66,2})));
      inner Modelica.Fluid.System system(allowFlowReversal=false, m_flow_start=10)
        annotation (Placement(transformation(extent={{46,18},{66,38}})));
      Modelica.Fluid.Machines.PrescribedPump pump(
        checkValve=true,
        N_nominal=1200,
        redeclare function flowCharacteristic =
            Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow
            (V_flow_nominal={0,0.25,0.5}, head_nominal={100,60,0}),
        nParallel=1,
        energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
        V(displayUnit="l") = 0.05,
        massDynamics=Modelica.Fluid.Types.Dynamics.DynamicFreeInitial,
        redeclare package Medium = Medium,
        p_b_start=600000,
        T_start=system.T_start)
        annotation (Placement(transformation(extent={{-16,-8},{4,12}})));
    equation
      connect(inletBoundary.ports[1], pump.port_a)
        annotation (Line(points={{-50,2},{-16,2}}, color={0,127,255}));
      connect(outletBoundary.ports[1], pump.port_b)
        annotation (Line(points={{56,2},{4,2}}, color={0,127,255}));
      annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
            coordinateSystem(preserveAspectRatio=false)));
    end Success;
    annotation (Documentation(info="<html>
<p>Here is the screenshot of comparing differences between two models in Visual Studio Code editor.</p>
<p>
<img src=\"modelica://Dymola_Skill_Tutorial/data/compareText.png\">
</p>

</html>"));
  end CompareText;
  annotation (uses(Modelica(version="3.2.3"),
              ExternData(version="2.5.0"),
              DymolaCommands(version="1.9"),
      KeyWordIO(version="0.X.X")),
              __Dymola_menu=true,
              Protection(hideFromBrowser=false));

end Dymola_Skill_Tutorial;

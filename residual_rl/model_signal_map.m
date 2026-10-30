function m = model_signal_map(model)
% Archive-verified relative paths. Runtime verification MUST precede wiring.
if nargin<1, c=residual_config(); model=c.sourceName; end
m.rawOrder={'omega(1:4)','Vd(1:4)','Pfiltered(1:4)','Qfiltered(1:4)','Vq(1:4)'};
m.units={'rad/s','V phase-peak dq','W','var','V phase-peak dq'};
m.rawDimension=20; m.observationDimension=42;
m.voltageMagnitude='hypot(Vd,Vq); not an RMS sensor';
m.frequencyIntegrators={'Integrator','Integrator1','Integrator2','Integrator3'};
m.voltageIntegrators={'Integrator4','Integrator5','Integrator6','Integrator7'};
for i=1:4
 d=[model '/DG' num2str(i)]; m.dg{i}=d;
 m.frequency{i}=[d '/w' num2str(i)]; m.P{i}=[d '/P' num2str(i)];
 m.Vd{i}=[d '/Vd' num2str(i)]; m.Q{i}=[d '/Q' num2str(i)];
 m.measurementSources{i}={[d '/Sum2'],[d '/Demux'], ...
     [d '/From32'],[d '/From33'],[d '/Demux']};
 m.measurementPorts{i}=[1 1 1 1 2];
 m.omegaInjection{i}=[d '/Sum2']; m.voltageInjection{i}=[d '/Sum6'];
 m.omegaGain{i}=[d '/Gain']; m.voltageGain{i}=[d '/Gain9'];
 m.vqCandidate{i}=[d '/Demux:2'];
 m.chart{i}=[model '/dw' num2str(i)];
end
m.load=[model '/Load 5']; m.breaker=[model '/Three-Phase Breaker1'];
m.powergui=[model '/powergui']; m.status='STATIC VERIFIED; compiled units/sample times pending';
end

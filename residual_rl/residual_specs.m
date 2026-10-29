function [obsInfo,actInfo] = residual_specs(c)
obsInfo=rlNumericSpec([c.obsDim 1],'LowerLimit',-c.obsClip,'UpperLimit',c.obsClip);
obsInfo.Name='normalized_frequency_voltage_sharing_memory_states_priorities';
actInfo=rlNumericSpec([8 1],'LowerLimit',-1,'UpperLimit',1);
actInfo.Name='normalized_frequency_voltage_residual';
end

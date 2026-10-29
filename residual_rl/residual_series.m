function [t,y] = residual_series(out,name,width)
s=out.get(name); t=s.Time(:); y=squeeze(s.Data);
if size(y,1)~=numel(t), y=y.'; end
assert(size(y,1)==numel(t) && size(y,2)==width,['Invalid log: ' name]);
assert(all(isfinite(y),'all') && all(diff(t)>0),['Nonfinite or unordered log: ' name]);
end

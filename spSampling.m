function [sampInds,SPinds,SPim] = spSampling(rgbim,N)
% Build superpixel (SP) map from the RGB image and take 1 sample for each SP center-of-mass

h = size(rgbim,1);
w = size(rgbim,2);
Npix = h*w;

[LabelSP,Nsp] = superpixels(rgbim,N,'Compactness',20,'Method','slic');
SPinds = cell(1,Nsp);
for s = 1:Nsp
    SPinds{s} = find(LabelSP==s);
end
SPbounadries = boundarymask(LabelSP);
SPim = imoverlay(rgbim,SPbounadries,'cyan');

sampInds = [];
for c = 1:Nsp
    inds = SPinds{c};
    % sample pixel which is closest to SP center of mass
    [I,J] = ind2sub([h w],inds);
    avg_IJ = round(mean([I,J])); % SP COM
    avg_IJ_mat = repmat(avg_IJ,length(inds),1);
    [~,minind_loc] = min(sum((I-avg_IJ_mat(:,1)).^2,2)+sum((J-avg_IJ_mat(:,2)).^2,2));
    sampind = inds(minind_loc);
    sampInds = [sampInds; sampind];
end

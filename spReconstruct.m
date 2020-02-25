function depth = spReconstruct(depth_mat,samp_inds,SPinds,sigma, deg)
% Zero order in each SP + Bilateral filter

[h,w] = size(depth_mat);
depth = zeros(h,w);
Nsp = length(samp_inds);

for c = 1:Nsp
    inds = SPinds{c};
    depth(inds) = depth_mat(samp_inds(c));
end

depth = exp(imbilatfilt(log(1+depth), deg, sigma))-1;


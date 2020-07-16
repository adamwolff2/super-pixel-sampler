function [SPimfull, SampMask, Nsamples] = mask_spSampling_sparse(rgbim,N,depthim,fileID)

% Assuming already cropped images from KITTI dataset (352x1216)
h_orig = size(rgbim,1);
w_orig = size(rgbim,2);
Npix = h_orig*w_orig;
depthim = logical(depthim); % binary

% Crop sky (where there are no samples)
[Y, X] = ind2sub([h_orig w_orig], find(depthim==1));
rgbim_sky_crop = rgbim(min(Y)-1:end, :, :);
depthim_sky_crop = depthim(min(Y)-1:end, :);
h_crop = size(rgbim_sky_crop,1);
w_crop = size(rgbim_sky_crop,2);

% If small, the script will take longer but it will be more "SP accurate" (less random samples)
switch N
    case 256
        jump = 50;  
    case 512
        jump = 50;
    case 1024
        jump = 75;
    case 2048
        jump = 100;
    case 4096
        jump = 200;
    otherwise
        disp('Add another budget value, exiting...')
        return
end

% Find initial desired number of SPs (up to some threshold - 0.02*N)
N_actual_samples = 0;
try_budget = N;
while N_actual_samples < (N - 0.02*N) % N + 2%
    [LabelSP,Nsp] = superpixels(rgbim_sky_crop,try_budget,'Compactness',20,'Method','slic'); % each pixel is assigned to a SP (via a number)
    SPinds = cell(1,Nsp);
    for s = 1:Nsp
        SPinds{s} = find(LabelSP==s); % all the indices of the pixels that are related to a certain SP
    end

    LabelSP_valid = LabelSP;
    LabelSP_valid(depthim_sky_crop==0) = 0; % we don't want to use non-valid GT pixels for center of mass
    SPinds_valid = cell(1,Nsp);
    for s = 1:Nsp
        SPinds_valid{s} = find(LabelSP_valid==s); % all the indices of the pixels that are related to a certain SP
    end
    N_actual_samples = sum(~cellfun(@isempty,SPinds_valid),2);  % non zero cells

    if N_actual_samples > N  % went too far, take last one
        [LabelSP,Nsp] = superpixels(rgbim_sky_crop,try_budget-jump,'Compactness',20,'Method','slic');
        SPinds = cell(1,Nsp);
        for s = 1:Nsp
            SPinds{s} = find(LabelSP==s); % all the indices of the pixels that are related to a certain SP
        end

        LabelSP_valid = LabelSP;
        LabelSP_valid(depthim_sky_crop==0) = 0; % we don't want to use non-valid GT pixels for center of mass
        SPinds_valid = cell(1,Nsp);
        for s = 1:Nsp
            SPinds_valid{s} = find(LabelSP_valid==s); % all the indices of the pixels that are related to a certain SP
        end
        break
    end
    try_budget = try_budget + jump;
end

SPbounadries = boundarymask(LabelSP);
SPim = imoverlay(rgbim(min(Y)-1:end, :, :),SPbounadries,'cyan');
SPimfull = cat(1, rgbim(1:min(Y)-2, :, :), SPim);

% Ignore SP without valid depth pixels, and take closest valid depth pixel as an estimation for the SP's center of mass
SampMask_tmp = logical(zeros(size(rgbim_sky_crop,1),size(rgbim_sky_crop,2)));
for c = 1:Nsp
    if isempty(SPinds_valid{c})  % no valid pixels in SP
        continue
    end

    inds = SPinds{c}; % all the pixels that are related to this SP

    % get SP's center of mass
    [subI,subJ] = ind2sub([h_crop w_crop],inds); % linear indix to subscripts (row & col)
    avg_sub = round(mean([subI,subJ]));
    avg_sub_mat = repmat(avg_sub,length(inds),1);
    [~,avg_subI] = min(sum((subI-avg_sub_mat(:,1)).^2,2));
    [~,avg_subJ] = min(sum((subJ-avg_sub_mat(:,2)).^2,2));
    avg_subI = subI(avg_subI); % Y
    avg_subJ = subJ(avg_subJ); % X

    % get closest valid sample - due to KITTI's sparsity
    [subI_valid subJ_valid] = ind2sub([h_crop w_crop],SPinds_valid{c});
    indices_valid = [];
    for i = 1:size(subI_valid, 1)
        indices_valid = [indices_valid ; [subI_valid(i) subJ_valid(i)]];
    end

    [val,indx] = min(pdist2([avg_subI avg_subJ], indices_valid, 'euclidean'));
    SampMask_tmp(subI_valid(indx), subJ_valid(indx)) = 1;
end

% Create a final sample map
chosen_samples = length(find(SampMask_tmp));
if chosen_samples > N
    fprintf('ERROR mask_Sampling: too many samples (%d instead of %d)', chosen_samples, N)
    return
elseif chosen_samples < N  % not enough, take random
    GTim_samples_left = depthim_sky_crop - SampMask_tmp;
    non_zero_indices = find(GTim_samples_left);
    rand_samples = randsample(non_zero_indices,N-chosen_samples,false);  % without replacement 
    [subI_rand,subJ_rand] = ind2sub([h_crop w_crop],rand_samples);
    for j = 1:size(rand_samples, 1)
        SampMask_tmp(subI_rand(j), subJ_rand(j)) = 1;
    end
end

fprintf(fileID,'Random Samples taken for this image: %d \n',N-chosen_samples);
SampMask = cat(1, zeros(h_orig-h_crop, w_orig), SampMask_tmp);  % add the sky (no samples there)
Nsamples = length(find(SampMask));
%imshow(imoverlay(SPbounadries, SampMask_tmp, 'red')) % visualization
%imshow(imoverlay(cat(1, boolean(zeros(size(depthim(1:min(Y)-2, :, :)))),SPbounadries), SampMask, 'red')); % visualization



clc; clear all; close;
tic
% general parameters + input paths (KITTI's original files). We'll choose budget of samples from the 'samples_path' images
budget = 256;   % num of desired samples
is_KITTI = true;
Kheight = 352; Kwidth = 1216;  % KITTI's crop (most NN do a bottom crop so we don't want samples to be in those areas)
general_path = 'D:\shacharp\Kitti';
RGB_path = join([general_path, '\data_rgb\train\']); % \depth_selection\val_selection_cropped\image\
samples_path = join([general_path, '\data_depth_annotated\train\']); % \depth_selection\val_selection_cropped\groundtruth_depth\
train_valselect = 'val_select';  % 'train, 'val_select'

% output - where the new depth images (the new input) will be saved
depth_res_path = join([general_path, '\results\', num2str(budget)]);

% log - write how many random samples were taken (instead of SPs) to complete the desired budget
fileID = fopen(join([general_path,'\', train_valselect, '_random_samples.txt']),'w');

if strcmp(train_valselect, 'train')
    print_thresh = 1000;
else  % val_select
    print_thresh = 100;
end

rgbds = imageDatastore(RGB_path,'IncludeSubfolders',true,'FileExtensions','.png');
depthds = imageDatastore(samples_path,'IncludeSubfolders',true,'FileExtensions','.png');
tot_rgbs=length(rgbds.Files);
tot_depths=length(depthds.Files);
if tot_rgbs ~= tot_depths  % the number of rgb images should match the number of input depth images
    disp('ERROR: the amount of the RGB images is not the same as the amount of the depth images. Exiting...')
    return
end
    
% main
pix=zeros(tot_rgbs,1);
for k=1:tot_rgbs
    % RGB
    [rgb_img,info_rgb] = readimage(rgbds,k);
    if is_KITTI  % bottom crop
        ii = size(rgb_img, 1) - Kheight;
        jj = round((size(rgb_img, 2) - Kwidth) / 2);
        rgb_img = rgb_img(ii+1:ii + Kheight, jj+1:jj + Kwidth, :);
    end
    
    % Depth
    [depth_img,info_depth] = readimage(depthds,k);
    if is_KITTI  % bottom crop
        ii = size(depth_img, 1) - Kheight;
        jj = round((size(depth_img, 2) - Kwidth) / 2);
        depth_img = depth_img(ii+1:ii + Kheight, jj+1:jj + Kwidth);
    end
    
    % check files consistency
    rgb_splitted_path=strsplit(info_rgb.Filename, '\'); 
    depth_splitted_path=strsplit(info_depth.Filename, '\'); 
    if strcmp(train_valselect, 'train')
        rgb_identifier = join([rgb_splitted_path(end-3), rgb_splitted_path(end-2), rgb_splitted_path(end)]);
        depth_identifier = join([depth_splitted_path(end-4), depth_splitted_path(end-1), depth_splitted_path(end)]);
    else  % val_select
        rgb_identifier = strrep(rgb_splitted_path(end), 'sync_image', 'sync_groundtruth_depth');
        depth_identifier = depth_splitted_path(end);
    end
    if ~strcmp(rgb_identifier, depth_identifier)
        disp('ERROR: the RGB image and the depth image are not related, different names. Exiting...')
        return
    end
    
    % where to save the new depth input (samples pattern)
    splitted_path_to_images=strsplit(info_depth.Filename, '\'); 
    if strcmp(train_valselect, 'train')
        path_to_images=join([depth_res_path, '\', strjoin(splitted_path_to_images(end-6:end), '\')]);
    else
        path_to_images=join([depth_res_path, '\', strjoin(splitted_path_to_images(end-3:end), '\')]);
    end
    if ~exist(path_to_images, 'dir')
        mkdir(path_to_images)
    end
    
    % SP sample
    [~, SampMask, Nsamp] = mask_spSampling(rgb_img, budget,depth_img,fileID);
    sparse = depth_img .* uint16(SampMask);
    pix(k) = Nsamp;  % samples taken per image
    imwrite(sparse, path_to_images)
    
    if mod(k-1,print_thresh) == 0
        disp([num2str(k/tot_rgbs*100), '%'])
        toc
        tic
    end
end
mean_pix = mean(pix); % avg for all the images
disp(['Mean Saples: ', num2str(mean_pix)])
fclose(fileID);

if strcmp(train_valselect, 'train')
    res_path = splitted_path_to_images(1:end-5);
else
    res_path = splitted_path_to_images(1:end-1);
end
resultsds = imageDatastore(strjoin(res_path, '\'),'IncludeSubfolders',true,'FileExtensions','.png');
disp(['Check result path: ', strjoin(res_path, '\'), ' for desired budget'])
corrupted = 0;
for k=1:length(resultsds.Files)
    [depth_res_img,info_res_depth] = readimage(resultsds,k);
    if length(find(depth_res_img)) ~= budget
        corrupted = corrupted + 1;
    end
end
disp(['Total of ', num2str(corrupted), '\', num2str(length(resultsds.Files)), ' files with less than ', num2str(budget), ' samples'])

toc
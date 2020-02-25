%%
close all
clear
%% Load data
RGB_im = imread('NYUv2_0883_rgb.png');
GT_im = imread('NYUv2_0883_gt.png');
figure; subplot(2,2,1); imshow(RGB_im); title('RGB');
subplot(2,2,2); imshow(GT_im,[]); title('Ground Truth Depth'); colormap('jet'); colorbar
[M,N,~] = size(RGB_im);

%% Define hyperparameters
number_of_SP = 400;
deg = 0.55; sigma = 1.8; % Bilateral-filter params

%% Sampling step
[samp_inds, SPinds, SPim] = spSampling(RGB_im, number_of_SP);
[samp_inds_y, samp_inds_x] = ind2sub([M,N], samp_inds);
subplot(2,2,3); imshow(SPim)
title(['Sampling Map: ', num2str(number_of_SP), ' samples'])  
hold on
plot(samp_inds_x, samp_inds_y, 'r.', 'MarkerSize', 15)

%% Get samples depth
depth_mat = zeros(M,N);
depth_mat(samp_inds) = GT_im(samp_inds);

%% Reconstruction step
sampmap = zeros(M,N);
sampmap(samp_inds) = 1;
depthSP = spReconstruct(depth_mat, samp_inds, SPinds, sigma, deg);
subplot(2,2,4); 
imshow(depthSP,[]); title('SP & Bilateral Reconstruction'); colormap('jet'); colorbar

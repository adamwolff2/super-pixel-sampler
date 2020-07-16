# super-pixel-sampler

This repo offers a MATLAB implementation of the SPS algorithm presented in the ICRA 2020 paper: "Super-Pixel Sampler: a Data-driven Approach for Depth Sampling and Reconstruction" by Adam Wolff, Shachar Praisler, Ilya Tcenov and Guy Gilboa. A video demonstration is available on YouTube: https://www.youtube.com/watch?v=7_DDCXL25uE&feature=youtu.be.


**Updates:**

**16/7/2020** - added scripts for sampling KITTI depth completion benchmark (i.e sparse samples) in sample_kitti folder



**Requierments:**

- MATLAB version 2018a or later.


**Usage:**

See example.m for usage example. Note that the Bilateral filter parameters should be manually adjusted and are dependent on amount of samples and depth range. The code should output the following figure:
![Image description](https://github.com/adamwolff2/image-guided-depth-sampling/blob/master/Results.jpg)


**Enjoy!**

clc
clear

% example
img = imread('sample_img.bmp');

img_final = img_correction(img);

figure
subplot(1,2,1)
imshow(img)
title('Before')
subplot(1,2,2)
imshow(img_final)
title('After')
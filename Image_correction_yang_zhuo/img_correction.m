function img_final = img_correction(img)

s = size(img);
% correct xy coordinate 
img_crt = flip(img, 2);
img_crt = imrotate(img_crt, 83.4, 'bilinear');

% crop to initial size
c = round(size(img_crt)/2);
img_final = img_crt(c(1)-(s(1)/2-1):c(1)+s(1)/2, c(2)-(s(2)/2-1):c(2)+s(2)/2);
% Write metadata file that includes 
% all angles to be rotated (i.e. negative orientation)
% and all centroids 
close all
clear all

meta_path = 'centroid_angle.txt';
data_dir = '08-AutoEncoder/data/meltpool/Meltpool_Camera_(partial)';
new_data_dir = '08-AutoEncoder/data/meltpool/Meltpool_Camera_(partial)_processed';
threshold = 0.15; % 0.1 if you want splatter. 0.6 if just meltpool
VISUAL = 0; % change to 1 if want to plot 
center_crop_size = 55; % center crop size (actual size is 1 larger than this).

% write file header
file = fopen(meta_path, 'w+');
fprintf(file, '%s %s %s %s\n', 'image_path', 'centroid_x', 'centroid_y', 'angle');

image_path = 'MIA_L0001/frame01113.bmp';

% loop over all images
folders = dir(data_dir);
for i = 1:length(folders)
    folder = folders(i).name;
    if folders(i).isdir && ~strcmp(folder, '.') && ~strcmp(folder, '..')
        ims = dir(fullfile(data_dir, folder, '*.bmp'));
        for j = 1:length(ims)
            image_path = fullfile(folder, ims(j).name);
            
            % binarize the image based on threshold
            I = imread(fullfile(data_dir, image_path));
            BW = im2bw(I, threshold);
            
            if VISUAL
                close all
                subplot(2,2,1);
                imshow(I);
                subplot(2,2,2);
                imshow(BW);
                subplot(2,2,3);
                imshow(BW);
                hold on
            end
            
            % calculate orientation using regionprops
            stats = regionprops(BW,'Orientation','Centroid','BoundingBox');
            if ~isempty(stats)
                % if multiple regions identified, pick the largest one
                if length(stats) > 1
                    largestBBarea = 0;
                    region_num = 0;
                    for i = 1:length(stats)
                        BBarea = prod(stats(i).BoundingBox(3),stats(i).BoundingBox(4));
                        if BBarea > largestBBarea
                            largestBBarea = BBarea;
                            region_num = i;
                        end
                    end
                    stats = stats(region_num);
                end
                
                o = stats.Orientation;
                c = stats.Centroid;
                BB = stats.BoundingBox;
                
                % shift to centroid
                size_of_cropped = min(c)*2;
                rect = [c-min(c), size_of_cropped, size_of_cropped];
                I2 = imcrop(I, rect);
                
                % rotate
                x = c(1) + 10 * cosd(o);
                y = c(2) - 10 * sind(o);
                I2 = imrotate(I2, -o, 'bicubic', 'loose');
                
                % crop to crop_size x crop_size
                rect = [size(I2)/2-center_crop_size/2, center_crop_size, center_crop_size];
                I2 = imcrop(I2, rect);
                
                if VISUAL
                    
                    line([c(1) x],[c(2) y]);
                    rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2);
                    subplot(2,2,4)
                    imshow(I2)
                    
                end
                
                % write to txt file
                co = [c,-o]; %negative because it's angle to be rotated
                fprintf(file, '%s %4.4f %4.4f %4.4f\n', image_path, co);
                
                % save to new directory
                new_path = fullfile(new_data_dir, image_path);
                imwrite(I2, new_path);
            end
        end
    end
end


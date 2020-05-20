% Write metadata file that includes 
% all angles to be rotated (i.e. negative orientation)
% and all centroids 

% may need to first create a new data directory. But no need to copy all
% images before running for the first time. 

close all
clear all

meta_path = 'centroid_angle.txt';
data_dir = '08-AutoEncoder/data/meltpool/Meltpool_Camera_(partial)';
new_data_dir = '08-AutoEncoder/data/meltpool/Meltpool_Camera_(partial)_processed';
thres_w_splatter = 0.15; % 0.1 if you want splatter. 0.6 if just meltpool
thres_no_splatter = 0.6;
VISUAL = 1; % change to 1 if want to plot 
% center_crop_size = 55; % center crop size (actual size is 1 larger than this i.e. 56x56). 
center_crop_size = 99; % center crop size (actual size is 1 larger than this i.e. 56x56). 

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
            image_path = fullfile(folder, ims(j).name); %ims(j).name is "framexxxxx.bmp"
            
            % binarize the image based on threshold
            I = imread(fullfile(data_dir, image_path));
            BW_w_splatter = im2bw(I, thres_w_splatter);
            
            if VISUAL
                close all
                subplot(2,2,1);
                imshow(I);
                subplot(2,2,2);
                imshow(BW_w_splatter);
                subplot(2,2,3);
                imshow(BW_w_splatter);
                hold on
            end
            
            % calculate orientation using regionprops
            stats_w_splatter = regionprops(BW_w_splatter,'Orientation','Centroid','BoundingBox');
            stats_no_splatter = regionprops(im2bw(I, thres_no_splatter),'Orientation','Centroid','BoundingBox');
            
            if ~isempty(stats_w_splatter)
                % if multiple regions identified, pick the largest one
                if length(stats_w_splatter) > 1
                    largestBBarea = 0;
                    region_num = 0;
                    for k = 1:length(stats_w_splatter)
                        BBarea = prod(stats_w_splatter(k).BoundingBox(3),stats_w_splatter(k).BoundingBox(4));
                        if BBarea > largestBBarea
                            largestBBarea = BBarea;
                            region_num = k;
                        end
                    end
                    stats_w_splatter = stats_w_splatter(region_num);
                end
                
                o = stats_w_splatter.Orientation;
                c = stats_w_splatter.Centroid;
                BB = stats_w_splatter.BoundingBox;
                
                % shift to centroid centered
                if length(stats_no_splatter) > 1
                    largestBBarea = 0;
                    region_num = 0;
                    for k = 1:length(stats_no_splatter)
                        BBarea = prod(stats_no_splatter(k).BoundingBox(3),stats_no_splatter(k).BoundingBox(4));
                        if BBarea > largestBBarea
                            largestBBarea = BBarea;
                            region_num = k;
                        end
                    end
                    stats_no_splatter = stats_no_splatter(region_num);
                end
                
                if isempty(stats_no_splatter)
                    c_mp_only = c; % if threshold is too high causing all black image, just use lower threshold's centroid
                else
                    c_mp_only = stats_no_splatter.Centroid;
                end
                size_of_cropped = min(c_mp_only)*2;
                rect = [c_mp_only-size_of_cropped/2, size_of_cropped, size_of_cropped];
                I2 = imcrop(I, rect);
                
                % rotate so that centre axis is always horizontal 
                % i.e. after this, all comet tails are either left or right
                x = c(1) + 10 * cosd(o);
                y = c(2) - 10 * sind(o);
                I2 = imrotate(I2, -o, 'bicubic', 'loose');
                
                % rotate again (center-rotate 180 if comet tail is pointing to the right)
                if ~isempty(stats_no_splatter)
                    % 1) get BW splatter and no splatter inside BB
                    I_BB = imrotate(imcrop(I, BB), -o, 'bicubic', 'loose');
                    BW_BB_w_splatter = im2bw(I_BB,thres_w_splatter);
                    BW_BB_no_splatter = im2bw(I_BB,thres_no_splatter);

                    % 2) determine tail direction and
                    % Rotate 
                    [~, cols] = find(BW_BB_w_splatter);
                    right_col_tail = max(cols);
                    left_col_tail = min(cols);
                    [rows, cols] = find(BW_BB_no_splatter);
                    right_col_core = max(cols);
                    left_col_core = min(cols); 

                    if (abs(right_col_tail-right_col_core) > abs(left_col_tail-left_col_core))
                        % more tail to the right than to the left
                        I2 = imrotate(I2, 180, 'bicubic', 'loose');
                    end 
                end
                % center crop to crop_size x crop_size
                rect = [size(I2)/2-center_crop_size/2, center_crop_size, center_crop_size];
                I2 = imcrop(I2, rect);
                
                if VISUAL
                    
                    line([c(1) x],[c(2) y]);
                    rectangle('Position', BB,'EdgeColor','r','LineWidth',2);
                    subplot(2,2,4)
                    imshow(I2)
                    
                end
                
                % write to txt file
                co = [c,-o]; %negative because it's angle to be rotated
                fprintf(file, '%s %4.4f %4.4f %4.4f\n', image_path, co);
                I = I2;
            end
            % save to new directory
            new_path = fullfile(new_data_dir, image_path);
            imwrite(I, new_path);
        end
    end
end

% Write metadata file that includes 
% all angles to be rotated (i.e. negative orientation)
% and all centroids 
close all
clear all

meta_path = 'centroid_angle.txt';
data_dir = '08-AutoEncoder/data/meltpool/Meltpool_Camera_(partial)';
image_path = 'MIA_L0001/frame00273.bmp';
threshold = 0.15; % 0.1 if you want splatter. 0.6 if just meltpool
VISUAL = 0; % change to 1 if want to plot 

% write file header
file = fopen(meta_path, 'w+');
fprintf(file, '%s %s %s %s\n', 'image_path', 'centroid_x', 'centroid_y', 'angle');

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
                o = stats.Orientation;
                c = stats.Centroid;
                BB = stats.BoundingBox;

                if VISUAL
                    subplot(2,2,4)
                    % shift to centroid
                    size_of_cropped = min(c)*2;
                    rect = [c-min(c), size_of_cropped, size_of_cropped];
                    I2 = imcrop(I, rect);

                    % rotate
                    x = c(1) + 10 * cosd(o);
                    y = c(2) - 10 * sind(o);
                    line([c(1) x],[c(2) y]);
                    rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2);
                    I2 = imrotate(I2, -o, 'nearest', 'crop');
                    imshow(I2)

                end

                % write to txt file 
                co = [c,-o]; %negative because it's angle to be rotated
                fprintf(file, '%s %4.4f %4.4f %4.4f\n', image_path, co); 
            end
        end
    end
end


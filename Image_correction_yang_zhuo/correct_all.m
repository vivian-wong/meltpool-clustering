meta_path = 'centroid_angle.txt';
data_dir = '../08-AutoEncoder/data/meltpool/Meltpool_Camera_(partial)';
new_data_dir = '../08-AutoEncoder/data/meltpool/Meltpool_Camera_(partial)_yangzhuo_processed';
thres_w_splatter = 0.15; % 0.1 if you want splatter. 0.6 if just meltpool
thres_no_splatter = 0.6;
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
            image_path = fullfile(folder, ims(j).name); %ims(j).name is "framexxxxx.bmp"
            img = imread(fullfile(data_dir, image_path));
            img_final = img_correction(img);
        end
    end
end

            
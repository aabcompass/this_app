function exit_code = this(path, Ts, is_full)
   
    disp('JEM-EUSO .dat to .mat preprocessor'); 

    this_ver = "7";
    this_sub_ver = "1";

    
    % Задание параметров программы
    %clear; 
    %level=3; %  Data type {raw=1, 1st integrated=2, 2nd integrated=3}
    frame_step=1; % 1 - show all frames, 2 - show ever 2nd frame, etc
    do_flat=0;  % do flat fielding. Applicable Only for MLT.
    mode_2d = 1; % show pictures
      mode_mlt = 1; % show only one EC unit used in MLT
        bad_pixel_removal = 1; %  replace a bad pixel in MLT by neighbour one
      do_rescale = 1; %  do division D2 by 128, D3 by 128*128
      fix_color_map = 0; % 1 - fixed color map, 0 - autoscale color map
        colorbar_lim = 12; %установить предел цветовой шкалы / set colorbar limit
      do_gif = 0; %generate .gif (one file per 128 frames)
    mode_lightcurve = 1; % show light curves
      mode_fft = 0; % show FFT of light curves
      one_pixel = 0; % 0 - show lightcurves for sum of pixels in frame, 1 - show lightcurve for the specified pix.
        pixel_x = 5; pixel_y = 35; % specify pixel

    only_triggered = 0; % show only triggered data (also periodic)

    n_active_pixels = 256; % needed for lightcurves.
    
    
    spb_2_48x48 = 0;
    
    

    listing = dir([path '/frm*sp*.dat'])
    
    period_us = 1000; %Tuloma SP channel
    frame_size=16; % задать число пикселей ФПУ / number of pixels on FS
    num_of_frames=determine_n_frames(listing, frame_size*4)%5000; % задать число фреймов в пакете / number of frames per packet
    magic_word = [hex2dec('00') hex2dec('10') hex2dec('1E') hex2dec('5A')];

    


    
    cw90 = 3; % поворот МАФЭУ на 90 градусов по часовой стрелки 
    ccw90 = 1;% поворот МАФЭУ на 90 градусов против часовой стрелки
    cw180 = 2;% поворот МАФЭУ на 180 градусов
    
    % Некоторые МАФЭУ (8х)по техническим причинам повернуты. 
    current_frame_global = 0;
    pdm_2d_rot_global_cnt = 0;
    norm_file_cnt = 1;
    gif_cnt = 0;
    
    if(numel(listing) == 0) 
        display('No .dat files found in the specified folder');
        exit_code = -1;
        return;
    end
    
    if(is_full == '1')
        sp_global = zeros(16, numel(listing)*num_of_frames);
    else
        sp_global = zeros(5, numel(listing)*num_of_frames);
    end
    unixtime_global = uint32(zeros(1, numel(listing)));
    D_tushv_global  = uint8(zeros(1, numel(listing)))*12;
    unixtime_dbl_global = zeros(1,numel(listing)*num_of_frames);
    ngtu_global = uint32(zeros(1, numel(listing)));
    sizeof_point = 4;
    rotation_needed = 1;

    for filename_cntr = 1:numel(listing) % указание на номера файлов, из которых будет произведено чтение
        %цикл, выполняющийся для каждого файла. 

        lst = listing(filename_cntr,1);
        filename = [path '/' lst.name]; 
        short_filename = [lst.name];
        dir_fn = dir(filename);
        filesize = dir_fn.bytes;

        fid = fopen(filename);

        fprintf('%s\n',filename);

        cpu_file = uint8(fread(fid, inf)); %прочитать файл в память / read file to memory
        fclose(fid); %закрыть файл / close file
        size_frame_file = size(cpu_file); % опрелелить размер прочитанных данных / get data size

        addrs = strfind(cpu_file',magic_word);        
        sections(1:numel(addrs)) = addrs;
        
        
        numel_section = numel(sections);
        
        
        for i=1:numel_section
            tmp=uint8(cpu_file(sections(i)+28 : sections(i)+28+4*frame_size*num_of_frames-1)); 
            D_bytes(i,1:size(tmp)) = tmp(:);                                       
            D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
            D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
            D_tushv(1:8)  = cpu_file(sections(i)+16:sections(i)+23);
        end
        

        unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
        ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
        D_tushv_global(norm_file_cnt*8-7:norm_file_cnt*8) = D_tushv;
        norm_file_cnt = norm_file_cnt+1;   
        

        datasize = sizeof_point*frame_size*num_of_frames;
        for packet=1:1:numel_section
            frame_data = reshape(D_bytes(packet,1:datasize), [1 datasize]); % выбрать из всех данных, полученных из файла, блок, содержащий изображение / take subarray with only image data
            frame_data_cast = typecast(frame_data(:), 'uint32'); %преобразовать представление данных к  uint32 // convert to uint32
            frames = reshape(frame_data_cast, [frame_size num_of_frames]); % перегруппировать массив из одномерного в двумерный
            if(is_full == '1')
                sp_global(:,(filename_cntr-1)*num_of_frames+1:filename_cntr*num_of_frames) = frames;
            else
                sp_global(:,(filename_cntr-1)*num_of_frames+1:filename_cntr*num_of_frames) = frames([1,2,5,6,16],:);
            end
        end
    end
    
    
    unixtime_global_numel=numel(unixtime_global);
    
    
    disp 'Generate double unix time'
    
    if(filename_cntr > 1)
        dngtu=diff(double(ngtu_global));
        ngtu_u64_global = uint64(zeros(1, numel(ngtu_global)));
        ovflw_cnt = 0;
        ngtu_u64_global(1) = double(ngtu_global(1));
        ngtu_u64_global(2) = double(ngtu_global(2));
        for i=1:numel(ngtu_global)-2
            if(dngtu(i+1) - dngtu(i) < -1e9) 
                ovflw_cnt = ovflw_cnt + 1;
            end
            ngtu_u64_global(i+2) = uint64(ngtu_global(i+2)) + ovflw_cnt*2^32;
        end
    end

    k=0;
    for i=1:numel(ngtu_global)
        k2=0;
        for j=1:num_of_frames
            unixtime_dbl_global((i-1)*num_of_frames+j) = double(unixtime_global(i)) + double(ngtu_u64_global(i))*(1e-6)*1000 +  double(k2*Ts)/1000;
            k2=k2+1;            
        end
    end        
    
    
    
    
    
    
    
    
       
   disp 'Saving martixes to .mat file'

   C = strsplit(pwd,'/');
   folder_name=cell2mat(C(size(C,2)));

   
   lightcurvesum_global=sum(sp_global);
   unixtime_dbl_sp_global = unixtime_dbl_global;
   sp_letter = ["A","I","B","J","C","K","D","L","E","M","F","N","G","Q","H","P"];
   sp_func = ["KC-11","UFS-1","EMPTY","J","430","337","EMPTY","EMPTY","EMPTY","M","EMPTY","EMPTY","EMPTY","Q","H","390"];
   save([path '/tuloma_sp.mat'], 'this_ver', 'this_sub_ver', 'sp_global', 'lightcurvesum_global', 'sp_letter', 'sp_func', 'unixtime_dbl_sp_global', 'D_tushv_global', 'period_us', '-v7.3');
   exit_code = 0;

   disp 'Generate .png'
   
   for i=1:3
        sp_global_decim(i,:) = decimate(sp_global(i,:),10);
   end
   
   integration = Ts*1000/1;
   %date = datetime(unixtime_dbl_global,'ConvertFrom', 'epochtime', 'Format', 'yyy-MM-dd HH:mm:ss.SSSSSSSSS');
   f = figure('visible','off');
   plot(sp_global_decim');
   dateshort = datetime(unixtime_dbl_global,'ConvertFrom', 'epochtime', 'Format', 'yyy-MM-dd');
   title(['Tuloma spectrum: ' string(dateshort(numel(dateshort)))]);
   saveas(f,[path '/tuloma_sp.png']);

    
   disp 'Done'
    
end




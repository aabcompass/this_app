% Universal .dat to .mat converter

% 8 IPF MLT d1
% 7 Lovozero (Aragats) D1
% 6 Lovozero (Aragats) D3
% 5 Tuloma SP channel
% 4 Tuloma 2nd and 3rd seasons 
% 3 Mini-EUSO L3 (Tuloma 1st season)
% 2 Mini-EUSO L2 (Tuloma 1st season)
% 1 Mini-EUSO L1 (Tuloma 1st season)
    
function exit_code = this(path, level, Ts)

    level = str2num(level);
    
    disp('JEM-EUSO .dat to .mat preprocessor'); 

    this_ver = "6";
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
    
    
    switch level
        case 1
            listing = dir([path '/frm*.dat'])
        case 2
            listing = dir([path '/frm*d3*.dat'])
        case 3    
            listing = dir([path '/frm*.dat'])
        case 4
            listing = dir([path '/frm*d3*.dat'])
        case 5
            listing = dir([path '/frm*sp*.dat'])
        case 6    
            listing = dir([path '/frm*d3*.dat']);
        case 7
            listing = dir([path '/frm*d1*.dat'])
        case 8
            listing = dir([path '/frm*d1*.dat'])
        otherwise
            'no such case'; stop    
    end
    

%     if(level==5)
%         listing = dir([path '/frm*sp*.dat']);
%     else
%         if(level==1 || level==3 || level==6)
%             listing = dir([path '/frm*.dat']);
%         else
%             listing = dir([path '/frm*d3*.dat']);
%         end
%     end
    
    if(level==8)
        period_us = 2.5; %IPF MLT d1
        frame_size=256; % задать число пикселей ФПУ / number of pixels on FS
        num_of_frames=16384; % задать число фреймов в пакете / number of frames per packet        
        dimx_ecasic = 8; %задать размер по х блока данных, выдаваемый платой ECASIC
        dimy_ecasic = 16;%задать размер по y блока данных, выдаваемый платой ECASIC
        n_ecasic=2;% задать количество плат ECASIC
        mode_mlt = 0;
        magic_word = [hex2dec('06') hex2dec('0A') hex2dec('1E') hex2dec('5A') hex2dec('18') hex2dec('FC') hex2dec('7F') hex2dec('00')];
    elseif(level==7)
        period_us = (Ts); %Lovozero
        frame_size=2880; % задать число пикселей ФПУ / number of pixels on FS
        num_of_frames=128; % 
        dimx_ecasic = 8; %задать размер по х блока данных, выдаваемый платой ECASIC
        dimy_ecasic = 60;%задать размер по y блока данных, выдаваемый платой ECASIC
        n_ecasic=6;% задать количество плат ECASIC
        magic_word = [hex2dec('06') hex2dec('0A') hex2dec('16') hex2dec('5A')];%hex2dec('1A') hex2dec('94') hex2dec('11') hex2dec('00')
    elseif(level==6)
        period_us = (Ts); %Lovozero
        frame_size=2880; % задать число пикселей ФПУ / number of pixels on FS
        num_of_frames=determine_n_frames(listing)-1; % 
        dimx_ecasic = 8; %задать размер по х блока данных, выдаваемый платой ECASIC
        dimy_ecasic = 60;%задать размер по y блока данных, выдаваемый платой ECASIC
        n_ecasic=6;% задать количество плат ECASIC
        magic_word = [hex2dec('03') hex2dec('0C') hex2dec('16') hex2dec('5A')];%hex2dec('1A') hex2dec('94') hex2dec('11') hex2dec('00')
    elseif(level==5)
        period_us = 1000; %Tuloma SP channel
        frame_size=16; % задать число пикселей ФПУ / number of pixels on FS
        num_of_frames=5000; % задать число фреймов в пакете / number of frames per packet
        magic_word = [hex2dec('00') hex2dec('10') hex2dec('1E') hex2dec('5A') hex2dec('1A') hex2dec('e2') hex2dec('04') hex2dec('00')];
    elseif(level==4)
        period_us = 1000; %Tuloma 2nd seasonS
        frame_size=256; % задать число пикселей ФПУ / number of pixels on FS
        num_of_frames=5000; % задать число фреймов в пакете / number of frames per packet        
        dimx_ecasic = 8; %задать размер по х блока данных, выдаваемый платой ECASIC
        dimy_ecasic = 16;%задать размер по y блока данных, выдаваемый платой ECASIC
        n_ecasic=2;% задать количество плат ECASIC
        mode_mlt = 0;
        magic_word = [hex2dec('03') hex2dec('0C') hex2dec('1E') hex2dec('5A') hex2dec('1A') hex2dec('20') hex2dec('4E') hex2dec('00')];
    else
        if(level==1)
            period_us = 2.5; %Mini-EUSO L1 (Tuloma 1st season)
            magic_word = [hex2dec('01') hex2dec('0A') hex2dec('01') hex2dec('5A') hex2dec('18') hex2dec('80') hex2dec('04') hex2dec('00')];
        elseif(level==2)
            period_us = 2.5*128; %Mini-EUSO L2 (Tuloma 1st season)
            magic_word = [hex2dec('01') hex2dec('0B') hex2dec('01') hex2dec('5A') hex2dec('18') hex2dec('00') hex2dec('09') hex2dec('00')];
        elseif(level==3)
            period_us = 2.5*128*128; %Mini-EUSO L3 (Tuloma 1st season)
            magic_word = [hex2dec('01') hex2dec('0C') hex2dec('01') hex2dec('5A') hex2dec('1C') hex2dec('00') hex2dec('12') hex2dec('00')];
        end
        frame_size=2304; % задать число пикселей ФПУ / number of pixels on FS
        num_of_frames=128; % задать число фреймов в пакете / number of frames per packet
        dimx_ecasic = 8; %задать размер по х блока данных, выдаваемый платой ECASIC
        dimy_ecasic = 48;%задать размер по y блока данных, выдаваемый платой ECASIC
        n_ecasic=6;% задать количество плат ECASIC
    end

    


    
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
    
    if(level==8)
        pdm_2d_rot_global = uint32(zeros(16,16,numel(listing)*num_of_frames));
        diag_global = uint32(zeros(16,numel(listing)*num_of_frames));
        lightcurvesum_global = zeros(1,numel(listing)*num_of_frames);
        unixtime_global = uint32(zeros(1, numel(listing)));
        ngtu_global = uint32(zeros(1, numel(listing)));
        sizeof_point = 1;
        rotation_needed = 1;
    elseif(level==7)
        pdm_2d_rot_global = uint32(zeros(48,16,numel(listing)*num_of_frames));
        pdm_2d_sp_global = uint32(zeros(16,8,numel(listing)*num_of_frames));
        %diag_global = uint32(zeros(16,numel(listing)*num_of_frames));
        lightcurvesum_global = zeros(1,numel(listing)*num_of_frames);
        unixtime_global = [];%uint32(zeros(1, numel(listing)));
        ngtu_global = [];%uint32(zeros(1, numel(listing)));
        sizeof_point = 1;
        rotation_needed = 0;    
    elseif(level==6)
        if(spb_2_48x48 == 0)
            pdm_2d_rot_global = uint32(zeros(48,16,numel(listing)*num_of_frames));
        else
            pdm_2d_rot_global = uint32(zeros(48,48,numel(listing)*num_of_frames));
        end
        
        pdm_2d_sp_global = uint32(zeros(16,8,numel(listing)*num_of_frames));
        %diag_global = uint32(zeros(16,numel(listing)*num_of_frames));
        lightcurvesum_global = zeros(1,numel(listing)*num_of_frames);
        unixtime_global = uint32(zeros(1, numel(listing)));
        ngtu_global = uint32(zeros(1, numel(listing)));
        sizeof_point = 4;
        rotation_needed = 0;
    elseif(level==5)
        sp_global = zeros(16, numel(listing)*num_of_frames);
        unixtime_global = uint32(zeros(1, numel(listing)));
        D_tushv_global  = uint8(zeros(1, numel(listing)))*12;
        unixtime_dbl_global = zeros(1,numel(listing)*num_of_frames);
        ngtu_global = uint32(zeros(1, numel(listing)));
        sizeof_point = 4;
        rotation_needed = 1;
    elseif(level==3 || level==4)
        pdm_2d_rot_global = uint32(zeros(16,16,numel(listing)*num_of_frames));
        diag_global = uint32(zeros(16,numel(listing)*num_of_frames));
        lightcurvesum_global = zeros(1,numel(listing)*num_of_frames);
        unixtime_global = uint32(zeros(1, numel(listing)));
        ngtu_global = uint32(zeros(1, numel(listing)));
        sizeof_point = 4;
        rotation_needed = 1;
    elseif(level==2)
        pdm_2d_rot_global = uint16(zeros(16,16,numel(listing)*num_of_frames*3));
        diag_global = uint16(zeros(16,numel(listing)*num_of_frames*3));
        lightcurvesum_global = zeros(1,numel(listing)*num_of_frames*3);
        unixtime_global = uint32(zeros(1, numel(listing)*3));
        ngtu_global = uint32(zeros(1, numel(listing)*3));
        sizeof_point = 2;
        rotation_needed = 1;
    else
        pdm_2d_rot_global = uint8(zeros(16,16,numel(listing)*num_of_frames*3));
        diag_global = uint8(zeros(16,numel(listing)*num_of_frames*3));
        lightcurvesum_global = zeros(1,numel(listing)*num_of_frames*3);
        unixtime_global = uint32(zeros(1, numel(listing)*3));
        ngtu_global = uint32(zeros(1, numel(listing)*3));
        sizeof_point = 1;
        rotation_needed = 1;
    end

    for filename_cntr = 1:numel(listing) % указание на номера файлов, из которых будет произведено чтение
        %цикл, выполняющийся для каждого файла. 

        lst = listing(filename_cntr,1);
        filename = [path '/' lst.name]; 
        short_filename = [lst.name];
        dir_fn = dir(filename);
        filesize = dir_fn.bytes;
        if(level==1 || level==2 || level==3)
            if(filesize ~= 4718884)
                continue;
            end
        elseif(level==4)
            if(filesize ~= 5120064)
                continue;
            end
        % elseif(level==5)
        %     if(filesize ~= 3840064)
        %         continue;
        %     end
        %elseif(level==6)
        %    if(filesize ~= 3840064)
        %        continue;
        %    end
        %elseif(level==7)
        %    if(filesize ~= 3687040)
        %        continue;
        %    end
        end

        fid = fopen(filename);

        fprintf('%s\n',filename);

        cpu_file = uint8(fread(fid, inf)); %прочитать файл в память / read file to memory
        fclose(fid); %закрыть файл / close file
        size_frame_file = size(cpu_file); % опрелелить размер прочитанных данных / get data size

        addrs = strfind(cpu_file',magic_word);        
        sections(1:numel(addrs)) = addrs;
        
        
        %D_bytes=uint8(zeros(3, numel(sections), sizeof_point*frame_size*num_of_frames));
        %D_tt = zeros(1, numel(sections(:)));
        %D_ngtu = zeros(1, numel(sections));
        if(level==1) 
            numel_section = numel(sections) - 1;
        else
            numel_section = numel(sections);
        end
        
        %if(level==7)
        %    section_list=[17:numel_section 1:16];
        %else 
        %    section_list=1:numel_section;
        %end
        
        strange_offset = 2;
        for i=1:numel_section
        %for i=section_list
            if (sections(i) ~= 0) || (only_triggered == 1)
                if(level == 1 || level == 2 || level == 3)
                    if(sections(i)+30+sizeof_point+strange_offset+sizeof_point*frame_size*num_of_frames-1) <= size(cpu_file, 1)
                        tmp=uint8(cpu_file(sections(i)+30+sizeof_point+strange_offset : sections(i)+30+sizeof_point+strange_offset+sizeof_point*frame_size*num_of_frames-1)); 
                        D_bytes(i,1:size(tmp)) = tmp(:);                                       
                        D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
                        D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
                        D_tt(i) = uint8(cpu_file(sections(i)+16));
                        %D_cath(j,i,:) = uint8(cpu_file(sections_D(j,i)+20:sections_D(j,i)+31));
                        %if D_tt(j,i)>2
                        %    D_tt(j,i) = 0;
                        %end
                    end
                elseif(level == 4)
                        tmp=uint8(cpu_file(sections(i)+28: sections(i)+28+sizeof_point*frame_size*num_of_frames-1)); 
                        D_bytes(i,1:size(tmp)) = tmp(:);                                       
                        D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
                        D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
                        D_tt(i) = uint8(cpu_file(sections(i)+16));
                elseif(level == 5)
                        tmp=uint8(cpu_file(sections(i)+28 : sections(i)+28+4*frame_size*num_of_frames-1)); 
                        D_bytes(i,1:size(tmp)) = tmp(:);                                       
                        D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
                        D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
                        D_tushv(1:8)  = cpu_file(sections(i)+16:sections(i)+23);
                elseif(level == 6)
                        tmp=uint8(cpu_file(sections(i)+28: sections(i)+28+sizeof_point*frame_size*num_of_frames-1)); 
                        tmp=circshift(tmp,-512+3840);
                        D_bytes(i,1:size(tmp)) = tmp(:);                                       
                        D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
                        D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
                        D_tt(i) = uint8(cpu_file(sections(i)+16));
                elseif(level == 7)
                        tmp=uint8(cpu_file(sections(i)+32: sections(i)+32+sizeof_point*frame_size*num_of_frames-1)); 
                        D_bytes(i,1:size(tmp)) = tmp(:);                                       
                        D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
                        D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
                        D_tt(i) = uint8(cpu_file(sections(i)+28));
                elseif(level == 8)
                        tmp=uint8(cpu_file(sections(i)+32: sections(i)+32+sizeof_point*frame_size*num_of_frames-1)); 
                        D_bytes(i,1:size(tmp)) = tmp(:);                                       
                        D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
                        D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
                        D_tt(i) = uint8(cpu_file(sections(i)+28));
                end
            end
        end
        
        % = circshift(D_ngtu,9);
        %D_unixtime = circshift(D_unixtime,9);
        %D_tt = circshift(D_tt,9);


        if (level == 1)
            unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
            unixtime_global(norm_file_cnt+1) = uint32(D_unixtime(2));
            unixtime_global(norm_file_cnt+2) = uint32(D_unixtime(3));
            ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
            ngtu_global(norm_file_cnt+1) = uint32(D_ngtu(2));
            ngtu_global(norm_file_cnt+2) = uint32(D_ngtu(3));
            norm_file_cnt = norm_file_cnt+3;            
        elseif (level==2)
            unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
            unixtime_global(norm_file_cnt+1) = uint32(D_unixtime(2));
            unixtime_global(norm_file_cnt+2) = uint32(D_unixtime(3));
            unixtime_global(norm_file_cnt+3) = uint32(D_unixtime(4));
            ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
            ngtu_global(norm_file_cnt+1) = uint32(D_ngtu(2));
            ngtu_global(norm_file_cnt+2) = uint32(D_ngtu(3));
            ngtu_global(norm_file_cnt+3) = uint32(D_ngtu(4));
            norm_file_cnt = norm_file_cnt+4;
        elseif(level==3 || level==4)
            unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
            ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
            norm_file_cnt = norm_file_cnt+1;   
        elseif(level==5)
            unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
            ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
            D_tushv_global(norm_file_cnt*8-7:norm_file_cnt*8) = D_tushv;
            norm_file_cnt = norm_file_cnt+1;   
        elseif(level==6)
            unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
            ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
            norm_file_cnt = norm_file_cnt+1;   
        elseif(level==7 || level==8)
            %unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
            unixtime_global = [unixtime_global uint32(D_unixtime)];
            ngtu_global = [ngtu_global uint32(D_ngtu)];
            %ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
            norm_file_cnt = norm_file_cnt+1;   
        end
        

        datasize = sizeof_point*frame_size*num_of_frames;
        %accumulation = 128^(level-1);
        %lightcurve_sum=zeros(128);
        %num_el=numel(sections); 
        for packet=1:1:numel_section
            if(level<=3)
                if (D_tt(packet) == 0) && (only_triggered == 1)
                  continue;
                end
            end
            %fprintf('T:%d\n', packet);

            frame_data = reshape(D_bytes(packet,1:datasize), [1 datasize]); % выбрать из всех данных, полученных из файла, блок, содержащий изображение / take subarray with only image data
            if (level == 3 || level == 4 || level == 5 || level == 6)% случай триггера уровня 3
                frame_data_cast = typecast(frame_data(:), 'uint32'); %преобразовать представление данных к  uint32 // convert to uint32
            elseif level == 2% случай триггера уровня 2
                frame_data_cast = typecast(frame_data(:), 'uint16');%преобразовать представление данных к  uint16 // convert to uint16
            elseif level == 1 || level == 7 || level == 8% случай триггера уровня 1
                frame_data_cast = frame_data;% оставить представление данных без изменения  // leave unchanged
            end
            frames = reshape(frame_data_cast, [frame_size num_of_frames]); % перегруппировать массив из одномерного в двумерный
            
            % Формирование изображения на экране
            if (level == 1 || level == 2 || level == 3 || level == 4)
                for current_frame=1:frame_step:num_of_frames % для каждого фрейма, прочитанного из файла / for each file in directory
                    %disp(current_frame); % вывести значение переменной на экран / print to log screen
                    if(do_rescale == 1)
                        pic = (frames(:, current_frame)');% выбрать один фрейм из блока данных, который содержит все фреймы / select just one frame
                    else
                        pic = (frames(:, current_frame)');
                    end
                    %                                 
                    ecasics_2d = fliplr(reshape(pic', [dimx_ecasic dimy_ecasic n_ecasic])); % сформировать двумерный массив 8х48, содержащий изображение одного фрейма / form an array 8x48 with just one frame

                    % сформировать двумерный массив 48х48, содержащий изображение одного фрейма 
                    if(n_ecasic == 6)
                        pdm_2d = [ecasics_2d(:,:,1)' ecasics_2d(:,:,2)' ecasics_2d(:,:,3)' ecasics_2d(:,:,4)' ecasics_2d(:,:,5)' ecasics_2d(:,:,6)']; % form an array 48x48 with just one frame
                    else
                        pdm_2d = [ecasics_2d(:,:,1)' ecasics_2d(:,:,2)'];
                    end

                    % выполнить поворот элементов изображения в зависимости от
                    % расположения
                    % here we rotate PMTs depending on their positions 

                    pdm_2d_rot = pdm_2d; % подготовить выходной массив для повернутых данных. Проинициализировать массив начальными данными до поворота
                    if(rotation_needed)
                        for i=0:n_ecasic-1 %для каждой строки элементов изображения 8х8 (МАФЭУ)
                            for j=0:dimy_ecasic/8-1 %для каждого столбца элементов изображения 8х8 (МАФЭУ)
                                if((rem(i,2)==0) && (rem(j,2)==0))%условия поворота
                                   pdm_2d_rot(i*8+1:i*8+8, j*8+1:j*8+8) = fliplr(rot90(pdm_2d(i*8+1:i*8+8, j*8+1:j*8+8), cw180));%поворот по часовой стрелке %rot90 cw90
                                end
                                if((rem(i,2)==0) && (rem(j,2)==1))%условия поворота
                                   pdm_2d_rot(i*8+1:i*8+8, j*8+1:j*8+8) = fliplr(rot90(pdm_2d(i*8+1:i*8+8, j*8+1:j*8+8), cw90));%поворот по часовой стрелке
                                end
                                if((rem(i,2)==1) && (rem(j,2)==0))%условия поворота
                                   pdm_2d_rot(i*8+1:i*8+8, j*8+1:j*8+8) = fliplr(rot90(pdm_2d(i*8+1:i*8+8, j*8+1:j*8+8), ccw90));%поворот по часовой стрелке
                                end
                                if((rem(i,2)==1) && (rem(j,2)==1))%условия поворота
                                   pdm_2d_rot(i*8+1:i*8+8, j*8+1:j*8+8) = fliplr(rot90(pdm_2d(i*8+1:i*8+8, j*8+1:j*8+8), 0));%зеркально отобразить fliplr
                                end
                           end
                        end            
                    end

                    if(mode_mlt == 1)
                        if(level == 6) 
                            %tmp_var=pdm_2d_rot; clear pdm_2d_rot; pdm_2d_rot = tmp_var(1:48,1:60);
                            tmp_var=pdm_2d_rot;
                        else
                            tmp_var=pdm_2d_rot; clear pdm_2d_rot; pdm_2d_rot = tmp_var(33:48,1:16);                            
                        end
                            
                        if(bad_pixel_removal==1)
                           pdm_2d_rot(11,2)=pdm_2d_rot(11,3);    
                        end
                    end
                    pdm_2d_rot_global_cnt = pdm_2d_rot_global_cnt + 1;
                    pdm_2d_rot_global(:,:,pdm_2d_rot_global_cnt) = pdm_2d_rot;


                    current_frame_global = current_frame_global + 1;
                    if one_pixel == 0
                        lightcurvesum(current_frame)=sum(pic)/n_active_pixels;
                        lightcurvesum_global(current_frame_global) = sum(pic)/n_active_pixels;
                    else
                        lightcurvesum(current_frame)=(pdm_2d_rot(pixel_y,pixel_x));
                        lightcurvesum_global(current_frame_global) = (pdm_2d_rot(pixel_y,pixel_x));                       
                    end
                end
            elseif(level==5)
                sp_global(:,(filename_cntr-1)*num_of_frames+1:filename_cntr*num_of_frames) = frames;
            elseif(level==6 || level==7)
                for current_frame=1:frame_step:num_of_frames
                    pic = (frames(:, current_frame)');
                    ecasics_2d = fliplr(reshape(pic', [dimx_ecasic dimy_ecasic n_ecasic]));
                    pdm_2d_rot = [ecasics_2d(:,:,1)' ecasics_2d(:,:,2)' ecasics_2d(:,:,3)' ecasics_2d(:,:,4)' ecasics_2d(:,:,5)' ecasics_2d(:,:,6)']; % form an array 48x48 with just one frame  
                    for ii = 1:n_ecasic % 6
                        pdm_2d_pc((ii-1)*8+1:ii*8,:) = pdm_2d_rot((ii-1)*10+3:ii*10,:); %показания с прибора
                        pdm_2d_ki(ii,:) = (pdm_2d_rot((ii-1)*10+2,:));
                    end
                    pdm_2d_rot_global_cnt = pdm_2d_rot_global_cnt + 1;
                    if(spb_2_48x48 == 0)
                        pdm_2d_rot_global(:,:,pdm_2d_rot_global_cnt) = [pdm_2d_pc(:,17:24) pdm_2d_pc(:,41:48)] ;
                    else    
                        pdm_2d_rot_global(:,:,pdm_2d_rot_global_cnt) = pdm_2d_pc;
                    end
                    pdm_2d_sp_global(:,:,pdm_2d_rot_global_cnt) = pdm_2d_pc(33:48,25:32);
                    lightcurvesum_global(pdm_2d_rot_global_cnt) = sum(sum(pdm_2d_rot_global(:,:,pdm_2d_rot_global_cnt)))/(256*3);
                end
            end
        end
    end
    
    if(level <= 4)
        diag_global(:,pdm_2d_rot_global_cnt) = diag(pdm_2d_rot);
        lightcurvesum_global_numel=numel(lightcurvesum_global);  
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
            if(level == 2) 
                unixtime_dbl_global((i-1)*num_of_frames+j)=double(unixtime_global(1)) + double(ngtu_u64_global(i) + j*128)*(2.5e-6);
            elseif(level == 3) 
                unixtime_dbl_global((i-1)*num_of_frames+j)=double(unixtime_global(1)) + double(ngtu_u64_global(i) + j*128*128)*(2.5e-6);
            elseif(level == 4) 
                unixtime_dbl_global((i-1)*num_of_frames+j)=double(unixtime_global(1)) + double(ngtu_u64_global(i) + k*400)*(2.5e-6)-5;
                k=k+1;
            elseif(level == 5) 
                unixtime_dbl_global((i-1)*num_of_frames+j)=double(unixtime_global(1)) + double(ngtu_u64_global(i) + k*1000)*(1e-6)-60;
                k=k+1;            
            elseif(level == 6) 
                unixtime_dbl_global((i-1)*num_of_frames+j) = double(unixtime_global(i)) + double(ngtu_u64_global(i))*(1e-6) +  double(k2*Ts)/1000;
                %unixtime_dbl_global((i-1)*num_of_frames+j) = double(unixtime_global(i)) + double(ngtu_global(i))*2.625e-6 + j*4*1e-3; %Ts
                k2=k2+1; 
            elseif(level == 7) 
                unixtime_dbl_global((i-1)*num_of_frames+j)=double(unixtime_global(i)) + double(ngtu_u64_global(i))*(1e-6) + double(k2*Ts)/1000000;
                %unixtime_dbl_global((i-1)*num_of_frames+j) = double(unixtime_global(i)) + double(ngtu_global(i))*2.625e-6 + j*4*1e-3; %Ts
                k2=k2+1; 
            %elseif(level == 8) 
            %    unixtime_dbl_global((i-1)*num_of_frames+j)=double(unixtime_global(i)) + double(ngtu_u64_global(i))*(1e-6) + double(k2*Ts)/1000000;
                %unixtime_dbl_global((i-1)*num_of_frames+j) = double(unixtime_global(i)) + double(ngtu_global(i))*2.625e-6 + j*4*1e-3; %Ts
            %    k2=k2+1; 
            end
        end
    end        
    
    
    
    
    
    
    
    if(level <= 3)
        
        disp 'Removing frames with wrong timestamps'

        valid_time=unixtime_dbl_global(lightcurvesum_global_numel);
        last_valid = 1;
        valid_pos=lightcurvesum_global_numel;


        for i=lightcurvesum_global_numel-1:-1:1
            if unixtime_dbl_global(i)>valid_time
                wrong_pos = i;
                last_valid = 0;
                fprintf('%s','-');
            else
                if last_valid == 0
                    unixtime_dbl_global(wrong_pos:valid_pos-1)=[];
                    lightcurvesum_global(wrong_pos:valid_pos-1)=[];
                    diag_global(:,wrong_pos:valid_pos-1)=[];
                    pdm_2d_rot_global(:,:,wrong_pos:valid_pos-1)=[];
                    fprintf('%s\n','x');
                end 
                valid_time = unixtime_dbl_global(i);
                valid_pos = i;
                last_valid = 1;
            end
        end
    end
    
%    disp 'Generating light curve with lower resolution'
%    if(level==4 || level==6)
%        period_us_decim = 20000; 
%        if(period_us_decim < period_us) 
%             period_us_decim = period_us;
%             lightcurvesum_global_decim = lightcurvesum_global;
%             unixtime_dbl_global_decim = unixtime_dbl_global;
%        else    
%             decim_factor = int32(period_us_decim / period_us); 
%             lightcurvesum_global_decim = decimate(lightcurvesum_global, decim_factor);
%             unixtime_dbl_global_decim = unixtime_dbl_global(1:decim_factor:end);
%        end
%    end   
   unixtime_dbl_global_decim = 0;
       
   disp 'Saving martixes to .mat file'

   C = strsplit(pwd,'/');
   folder_name=cell2mat(C(size(C,2)));

   
   if(level==8)
        save([path '/lovozero.mat'], 'this_ver', 'this_sub_ver','lightcurvesum_global', 'pdm_2d_rot_global','period_us', '-v7.3');
        %save([path '/lovozero_decim.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global_decim','lightcurvesum_global_decim', 'period_us_decim', '-v7.3');
   elseif(level==7)
        save([path folder_name '_d1.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global','lightcurvesum_global', 'pdm_2d_rot_global','period_us', '-v7.3');
        %save([path '/lovozero_decim.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global_decim','lightcurvesum_global_decim', 'period_us_decim', '-v7.3');
   elseif(level==6)
        save([path folder_name '_d3.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global','lightcurvesum_global', 'pdm_2d_rot_global','period_us', '-v7.3');
        %save([path '/lovozero_decim.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global_decim','lightcurvesum_global_decim', 'period_us_decim', '-v7.3');
   elseif(level==5)
        unixtime_dbl_sp_global = unixtime_dbl_global;
        sp_letter = ["A","I","B","J","C","K","D","L","E","M","F","N","G","Q","H","P"];
        sp_func = ["KC-11","UFS-1","EMPTY","J","430","337","EMPTY","EMPTY","EMPTY","M","EMPTY","EMPTY","EMPTY","Q","H","390"];
        save([path '/tuloma_sp.mat'], 'this_ver', 'this_sub_ver', 'sp_global', 'sp_letter', 'sp_func', 'unixtime_dbl_sp_global', 'D_tushv_global', 'period_us', '-v7.3');
   elseif(level==4)
        save([path '/tuloma.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global', 'lightcurvesum_global', 'pdm_2d_rot_global', 'diag_global',  'period_us', '-v7.3');
        %save([path '/tuloma_decim.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global_decim', 'lightcurvesum_global_decim', 'period_us_decim', '-v7.3');
   elseif(level==3)
        cwt_global = abs(cwt(lightcurvesum_global));
        lightcurvesum_global(128*unixtime_global_numel+1 : lightcurvesum_global_numel) = [];
        diag_global(:,128*unixtime_global_numel+1 : lightcurvesum_global_numel-1) = [];
        %save([path '/global_d3.mat'], 'this_ver', 'this_sub_ver', 'lightcurvesum_global', 'pdm_2d_rot_global', 'diag_global', 'unixtime_global', 'unixtime_dbl_global', 'ngtu_global' , 'd3_period_us', 'cwt_global', '-v7.3');
        save([path '/global_d3.mat'], 'this_ver', 'this_sub_ver', 'lightcurvesum_global', 'pdm_2d_rot_global', 'diag_global', 'period_us', 'unixtime_global', 'ngtu_global' ,'-v7.3');
    elseif(level==2) 
        lightcurvesum_global(128*unixtime_global_numel+1 : lightcurvesum_global_numel) = [];
        diag_global(:,128*unixtime_global_numel+1 : lightcurvesum_global_numel-1) = [];
        save([path '/global_d2.mat'], 'this_ver', 'this_sub_ver', 'lightcurvesum_global', 'pdm_2d_rot_global', 'diag_global', 'unixtime_dbl_global', 'period_us', '-v7.3');    
    elseif(level==1)
        %save([path '/global_d1.mat'], 'this_ver', 'this_sub_ver', 'lightcurvesum_global', 'pdm_2d_rot_global', 'diag_global', 'unixtime_global', 'd1_period_us', '-v7.3');    
        save([path '/global_d1.mat'], 'this_ver', 'this_sub_ver', 'pdm_2d_rot_global', 'lightcurvesum_global', 'unixtime_global', 'period_us', 'ngtu_global' ,'-v7.3');    
    end
    %save([path '/cwt_global.mat'], 'this_ver', 'this_sub_ver', );
    exit_code = 0;
    
    disp 'Done'
    
end




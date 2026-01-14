% Universal .dat to .mat converter

% 8 IPF MLT d1
% 7 Lovozero (Aragats) D1
% 6 Lovozero (Aragats) D3
% 5 Tuloma SP channel
% 4 Tuloma 2nd and 3rd seasons 
% 3 Mini-EUSO L3 (Tuloma 1st season)
% 2 Mini-EUSO L2 (Tuloma 1st season)
% 1 Mini-EUSO L1 (Tuloma 1st season)
    
function exit_code = this_Tuloma_D3(path, Ts, include_2d)

    
    disp('Tuloma .dat to .mat preprocessor'); 

    this_ver = "7";
    this_sub_ver = "1";

    
    % Задание параметров программы
    %clear; 
    %level=3; %  Data type {raw=1, 1st integrated=2, 2nd integrated=3}
    frame_step=1; % 1 - show all frames, 2 - show ever 2nd frame, etc
   
      
    bad_pixel_removal = 1; %  replace a bad pixel in MLT by neighbour one
    do_rescale = 1; %  do division D2 by 128, D3 by 128*128           
    only_triggered = 0; % show only triggered data (also periodic)

    n_active_pixels = 256; % needed for lightcurves.
 
    listing = dir([path '/frm*d3*.dat']);
   

    period_us = Ts; %Tuloma 2nd seasonS
    frame_size=256; % задать число пикселей ФПУ / number of pixels on FS
    num_of_frames=5000; % задать число фреймов в пакете / number of frames per packet        
    dimx_ecasic = 8; %задать размер по х блока данных, выдаваемый платой ECASIC
    dimy_ecasic = 16;%задать размер по y блока данных, выдаваемый платой ECASIC
    n_ecasic=2;% задать количество плат ECASIC

    magic_word = [hex2dec('03') hex2dec('0C') hex2dec('1E') hex2dec('5A') hex2dec('1A') hex2dec('20') hex2dec('4E') hex2dec('00')];
      
    cw90 = 3; % поворот МАФЭУ на 90 градусов по часовой стрелки 
    ccw90 = 1;% поворот МАФЭУ на 90 градусов против часовой стрелки
    cw180 = 2;% поворот МАФЭУ на 180 градусов
    
    % Некоторые МАФЭУ (8х)по техническим причинам повернуты. 
    current_frame_global = 0;
    pdm_2d_rot_global_cnt = 0;
    norm_file_cnt = 1;

    if(numel(listing) == 0) 
        display('No .dat files found in the specified folder');
        exit_code = -1;
        return;
    end
    
    if(include_2d == 1)
        pdm_2d_rot_global = uint32(zeros(16,16,numel(listing)*num_of_frames));
    end
    lightcurvesum_global = zeros(1,numel(listing)*num_of_frames);
    unixtime_global = uint32(zeros(1, numel(listing)));
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

        if(filesize ~= 5120064)
            continue;
        end


        fid = fopen(filename);

        fprintf('%s\n',filename);

        cpu_file = uint8(fread(fid, inf)); %прочитать файл в память / read file to memory
        fclose(fid); %закрыть файл / close file
        size_frame_file = size(cpu_file); % опрелелить размер прочитанных данных / get data size

        addrs = strfind(cpu_file',magic_word);        
        sections(1:numel(addrs)) = addrs;
        

        numel_section = numel(sections);
           

 
        for i=1:numel_section
        %for i=section_list
            if (sections(i) ~= 0) || (only_triggered == 1)                
                tmp=uint8(cpu_file(sections(i)+28: sections(i)+28+sizeof_point*frame_size*num_of_frames-1)); 
                D_bytes(i,1:size(tmp)) = tmp(:);                                       
                D_ngtu(i) = typecast(uint8(cpu_file(sections(i)+8:sections(i)+11)), 'uint32');
                D_unixtime(i) = typecast(uint8(cpu_file(sections(i)+12:sections(i)+15)), 'uint32');
                D_tt(i) = uint8(cpu_file(sections(i)+16));
            end
        end
       

        unixtime_global(norm_file_cnt) = uint32(D_unixtime(1));
        ngtu_global(norm_file_cnt) = uint32(D_ngtu(1));
        norm_file_cnt = norm_file_cnt+1; 

        datasize = sizeof_point*frame_size*num_of_frames;

        for packet=1:1:numel_section


            frame_data = reshape(D_bytes(packet,1:datasize), [1 datasize]); % выбрать из всех данных, полученных из файла, блок, содержащий изображение / take subarray with only image data
            frame_data_cast = typecast(frame_data(:), 'uint32'); %преобразовать представление данных к  uint32 // convert to uint32
            frames = reshape(frame_data_cast, [frame_size num_of_frames]); % перегруппировать массив из одномерного в двумерный
            
            % Формирование изображения на экране
            for current_frame=1:frame_step:num_of_frames % для каждого фрейма, прочитанного из файла / for each file in directory
                pic = (frames(:, current_frame)');% выбрать один фрейм из блока данных, который содержит все фреймы / select just one frame
                if(include_2d == 1)
                    ecasics_2d = fliplr(reshape(pic', [dimx_ecasic dimy_ecasic n_ecasic])); % сформировать двумерный массив 8х48, содержащий изображение одного фрейма / form an array 8x48 with just one frame
                    pdm_2d = [ecasics_2d(:,:,1)' ecasics_2d(:,:,2)'];
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
    
                    pdm_2d_rot_global_cnt = pdm_2d_rot_global_cnt + 1;
                    pdm_2d_rot_global(:,:,pdm_2d_rot_global_cnt) = pdm_2d_rot;                
                end

                current_frame_global = current_frame_global + 1;               
                lightcurvesum_global(current_frame_global) = sum(pic)/n_active_pixels;                                                  
            end
        end
    end
       
    %lightcurvesum_global_numel=numel(lightcurvesum_global);  

    
    %unixtime_global_numel=numel(unixtime_global);
    
    
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

    for i=1:numel(ngtu_global)
        k2=0;
        for j=1:num_of_frames
            
                unixtime_dbl_global((i-1)*num_of_frames+j) = double(unixtime_global(i)) + double(ngtu_u64_global(i))*(1e-6)*1000 +  double(k2*Ts)/1000;
                k2=k2+1;
        end
    end        

       
   disp 'Saving martixes to .mat file' 

   if(include_2d == 1)
       save([path '/tuloma.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global', 'lightcurvesum_global', 'pdm_2d_rot_global',  'period_us', '-v7.3');
   else
       save([path '/tuloma.mat'], 'this_ver', 'this_sub_ver', 'unixtime_dbl_global', 'lightcurvesum_global',  'period_us', '-v7.3');
   end

   exit_code = 0;
    
   disp 'Done'
    
end




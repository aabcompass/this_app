
function exit_code = this_exec2_lovozero(my_path)


    delete(gcp('nocreate'))
    
    %my_path = '/mnt/hdd/tuloma_data/7z_data/7z_20230317/';
    hour_begin = 12;
    hour_end = 6;
    parfor (i=0:24, 6)
        if (i <= hour_end)
            this(strcat(my_path, '0', num2str(i)),'4', '1');
        end
        if (i >= hour_begin) && (i ~= 24)
            this(strcat(my_path, num2str(i)),'4', '1');
        end
        if (i == 24)
            this(strcat(my_path, 'sp' ),'5', '1');
        end
    end

end




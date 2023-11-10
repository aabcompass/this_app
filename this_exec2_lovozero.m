function exit_code = this_exec2_lovozero(my_path, gtu_time)

    %gtu_time = 125;

    delete(gcp('nocreate'))
    
    hour_begin = 12;
    hour_end = 6;
    parfor (i=0:23, 2) %2 for Dan, 6 for lab
        if (i <= hour_end)
            
            try
                this(strcat(my_path, '/0', num2str(i)),'6', gtu_time);
            catch
                fprintf(strcat('hour 0', num2str(i), ' is not available'));
            end
        end
        if (i >= hour_begin)
            
            try
                this(strcat(my_path, '/', num2str(i)), '6', gtu_time);
            catch
                fprintf(strcat('hour ', num2str(i), ' is not available'));
                fprintf(strcat(my_path, num2str(i)));
            end
        end
    end

end




integration = 10000;
date = datetime(unixtime_dbl_global,'ConvertFrom', 'epochtime', 'Format', 'yyy-MM-dd HH:mm:ss.SSSSSSSSS');
    
plot(date,lightcurvesum_global/integration,'-k')
stop
%%
plot(reshape(pdm_2d_rot_global(1, 2, :), [], 1))

fix_color_map = 0;
colorbar_lim = 30;
accumulation = 1;
frame_step = 1;
frame_margin = 127;
delay=0.01;
frame_start = 1;
frame_stop = 9600;
do_avr = 0;
draw_time = 1;

figure(1)
figure(2)
%avr_frame = sum(pdm_2d_rot_global(:,:,frame_start:frame_stop),3)/(frame_stop-frame_start+1);
if(do_avr==1)
    avr_frame = sum(pdm_2d_rot_global(:,:,:),3)/numel(pdm_2d_rot_global(1,1,:));
else
    avr_frame  = 0;
end

for frame=frame_start:frame_step:frame_stop%numel(pdm_2d_rot_global(1,1,:))
    if(fix_color_map == 0)
        imagesc(double(pdm_2d_rot_global(:,:,frame))/accumulation-avr_frame); 
    else
        imagesc(double(pdm_2d_rot_global(:,:,frame))/accumulation-avr_frame, [0 colorbar_lim]); 
    end
    colorbar;
    pause(delay);
    if(mod(frame,128) == 1 && draw_time == 1)
        figure(2)
        plot(lightcurvesum_global(frame:frame+frame_margin));
        figure(1)
    end
    frame
end

stop
%%
%pixellightcurve = reshape(pdm_2d_rot_global(1, 2, :), [], 1);
close all;
k=1;
for frame=128*28299:128*k:numel(lightcurvesum_global)
    plot(lightcurvesum_global(frame:frame+127),'.-');
    xlabel(int2str(frame));
    pause(1);
end 

%% time
figure;plot(unixtime_dbl_global, '.-');

plt = plot(lightcurvesum_global, '.-');
plt.DataTipTemplate.DataTipRows(1).Format = '%10.0f';

cwt(lightcurvesum_global);

%lightcurvesum_global(:,1:3) = [];
w=hann(numel(lightcurvesum_global));
plot(20*log10(abs(fft(w'.*lightcurvesum_global))),'.-');
%plot((abs(fft(w'.*lightcurvesum_global))),'.-');

N = numel(lightcurvesum_global);
DF = 100;
pdm_2d_rot_global_lafft = 20*log10(abs(fft(pdm_2d_rot_global,N,3)));
pdm_2d_rot_global_lafft_dec = zeros(16,16,N/DF);

for i=1:16
    for j=1:16
        if (i==9) && (j==3)
            continue;
        end
        if (i==10) && (j==2)
            continue;
        end
        if (i==10) && (j==4)
            continue;
        end
        if (i==11) && (j==2)
            continue;
        end
        if (i==12) && (j==2)
            continue;
        end
        if (i==16) && (j==5)
            continue;
        end
        if (i==16) && (j==6)
            continue;
        end
        if (i==16) && (j==7)
            continue;
        end
        pdm_2d_rot_global_lafft_dec(i,j,:) = decimate(reshape(pdm_2d_rot_global_lafft(i,j,:),[1 N]), 100);
        %pdm_2d_rot_global_lafft = 20*log10(abs(fft(pdm_2d_rot_global(i,j,:))));
        %plot(reshape(pdm_2d_rot_global_lafft(i,j,:),[1 N]),'.-');
        %plot(reshape(pdm_2d_rot_global_lafft,[1 N]),'.-');
        %pause(1);
        fprintf('%d %d\n',i,j);
    end
end

fix_color_map = 1;
colorbar_lim = 70;
frame_step=1;

for frame=1:frame_step:numel(pdm_2d_rot_global_lafft_dec(1,1,:))
    if(fix_color_map == 0)
        imagesc(double(pdm_2d_rot_global_lafft_dec(:,:,frame))); 
    else
        imagesc(double(pdm_2d_rot_global_lafft_dec(:,:,frame)), [20 colorbar_lim]); 
    end
    colorbar;
    pause(0.1);
    frame
end


%% time checker
sz = int32(numel(unixtime_dbl_global)/128);
for i=1:sz
    plot(unixtime_dbl_global(128*i-127:128*i)-unixtime_dbl_global(128*i-127));
    pause(0.01);
    i
end
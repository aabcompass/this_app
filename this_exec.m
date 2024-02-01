% cd ('2021-10-31')
% this('.',2);
% this('.',3);
% cd ('../2022-01-11')
% this('.',2);
% this('.',3);
% cd ('../2022-01-22')
% this('.',2);
% this('.',3);
%this('/mnt/md0/xil_proj/MLT_TUS16/23-24/lovosero/lftp/Lvozero-1st/1','6','4');
%this('/mnt/md0/Aurora/l20231029/7z/22','6',4.2);
%this('/home/alx/tmp/lovozero_pixelmaps/pixels','6',4.2);
%this('/home/alx/tmp/lovozero_pixelmaps/PMTs','6',4.2);
this('.','6',4.2);

stop

delete(gcp('nocreate'))
p=parpool(3); %создает пул параллельных вычислений на 3 параллельных потока
F17 = parfeval(p, @this,1, '/mnt/md0/Aurora/l20231029/7z/22','6',4.2); %запускает на пуле p процесс  '/mnt/DNS/MLT_data/20230325/17'  с параметром '4'. 1 - число вых параметров
F18 = parfeval(p, @this,1, '/mnt/md0/Aurora/l20231029/7z/23','6',4.2);
F19 = parfeval(p, @this,1, '/mnt/md0/Aurora/l20231029/7z/00','6',4.2);
%F20 = parfeval(p, @this,1, '/mnt/DNS/MLT_data/20230318/20','4');
%F21 = parfeval(p, @this,1, '/mnt/DNS/MLT_data/20230318/21','4');
%F22 = parfeval(p, @this,1, '/mnt/DNS/MLT_data/20230318/22','4');
%F23 = parfeval(p, @this,1, '/mnt/DNS/MLT_data/20230318/23','4');
%F00 = parfeval(p, @this,1, '/mnt/DNS/MLT_data/20230318/00','4');
%F01 = parfeval(p, @this,1, '/mnt/DNS/MLT_data/20230318/01','4');
%F02 = parfeval(p, @this,1, '/mnt/DNS/MLT_data/20230318/02','4');
%Fsp = parfeval(p, @this,1, '/mnt/md0/xil_proj/MLT_TUS16/23-24/lovosero/lftp/Lvozero-1st/1','6');
Fsp.State


clear; clc; close all;

M = 7;     
N_arr = [1,2,3];            
C = 2;             
Block_Num = 200000;
L_arr = [1,2];

total=zeros(2,3,25);
for l=1:length(L_arr)
    L=L_arr(l);
    for n=1:length(N_arr)
        N=N_arr(n);
        for dB =0:1:24
            disp(dB);
            SNR=10^(dB/10);
            [Bits,Symbols0]=Transmitter(M,N,Block_Num,C);
            Symbols1=Channel(Symbols0,L,N,M,SNR);
            Bitsre=Receiver(M,N,Block_Num,C,Symbols1);
            total(l,n,dB+1)=sum(Bits~=Bitsre)/(N*(M+1)*Block_Num);
            if total(l,n,dB+1)==0
                fprintf('   >>> 误码率为0,跳过后续 SNR 点\n'); 
                break;
            end
        end
    end
end

figure();
box on; hold on;
styles = {'r-', 'b-x', 'k-+'}; 
for i = 1:2
    for j = 1:3
        plot(0:1:24, squeeze(total(i,j,:)), styles{j},...
             'LineWidth', 1.5, 'MarkerSize', 7);
    end
end
set(gca, 'Yscale', 'log');
ylim([1e-5 1]);      
xlim([0 24]);         
xlabel('Eb/N0 (dB)', 'FontSize', 12);
ylabel('BER', 'FontSize', 12);
legend('N=1, \beta=256, Simulation', ...
       'N=2, \beta=512, Simulation', ...
       'N=3, \beta=768, Simulation', ...
       'Location', 'SouthWest', 'FontSize', 10);
grid on;
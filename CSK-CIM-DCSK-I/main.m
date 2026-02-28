clear; clc; close all;

beta = 512;
m_c_arr = [2, 1, 2, 3];
m_s_arr = [1, 2, 3, 2];
C=2;                   
Block_Num =2000000;            
L_arr = [1, 2];                       
total = zeros(2,4,25);

for l=1:length(L_arr)
    L = L_arr(l);
    for m=1:length(m_c_arr)
        m_c = m_c_arr(m);
        m_s = m_s_arr(m);
        P = 2^(m_c + 1);
        theta = beta / P;
        for dB=0:1:24
            disp(dB);
            SNR = 10^(dB/10); 
            [Bits, Symbols0, r_arr] = Transmitter(m_c, m_s, theta, Block_Num,C);
            Symbols1 = Channel(Symbols0, L, m_c, m_s, SNR);
            Bitsre = Receiver(m_c, m_s, theta, Block_Num, Symbols1, r_arr,C);
            total(l,m,dB+1)=sum(Bits~=Bitsre)/((m_c+m_s+1)*Block_Num);
            if total(l,m,dB+1)==0
                fprintf('  >>> 误码率为0,跳过后续高信噪比点\n');
                break;
            end
        end
    end
end


figure();
box on; hold on; 
colors = {'b', 'r', 'm', 'k'};
markers = {'o', 'd', 's', '^'};   

for l = 1:length(L_arr)
    L = L_arr(l);
    for m = 1:length(m_c_arr)
        m_c = m_c_arr(m);
        m_s = m_s_arr(m);
        if L == 1
            style = [colors{m}, '-', markers{m}]; % AWGN 用实线
            display_name = sprintf('AWGN: m_c=%d, m_s=%d', m_c, m_s);
        else
            style = [colors{m}, '--', markers{m}]; % Rayleigh 用虚线
            display_name = sprintf('Rayleigh: m_c=%d, m_s=%d', m_c, m_s);
        end
        plot(0:1:24, squeeze(total(l, m, :)), style, ...
            'LineWidth', 1.5, ...
            'MarkerSize', 7, ...
            'MarkerFaceColor', 'none', ... 
            'DisplayName', display_name);
    end
end

set(gca, 'YScale', 'log');
ylim([1e-5 1]);
xlim([0 24]);
set(gca, 'XTick', 0:2:24); 
xlabel('E_b/N_0 (dB)', 'FontSize', 12);
ylabel('BER', 'FontSize', 12);
legend('Location', 'SouthWest', 'FontSize', 10);
grid on;
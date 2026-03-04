clear; clc; close all;

beta = 256;
m_c = 1; m_s = 4;
m = 5;
Block_Num = 200000;
L_arr = [1, 3];
theta_I = beta / (2^(m_c+1));
theta_II = beta / 2;
C = 0;
BER = zeros(4, 2, 25);

for l = 1:2
    L = L_arr(l);
    skip_flags = false(1, 4);
    
    for dB = 0:1:24
        disp(dB);
        SNR = 10^(dB/10);
        if ~skip_flags(1)
            [Bits1, Sym0_1] = Transmitter_I(m_c, m_s, theta_I, Block_Num, C);
            Sym1_1 = Universal_Channel(Sym0_1, L, SNR, (m_c+m_s+1));
            BitsRe1 = Receiver_I(m_c, m_s, theta_I, Block_Num, Sym1_1, C);
            err1 = sum(Bits1 ~= BitsRe1);
            BER(1, l, dB+1) = err1 / length(Bits1);
            if err1 == 0
                fprintf('  >>> CSK-CIM-DCSK-I 误码率为0, 提前跳过后续高信噪比点\n');
                skip_flags(1) = true;
            end
        end

        if ~skip_flags(2)
            [Bits2, Sym0_2] = Transmitter_II(m_c, m_s, theta_II, Block_Num, C);
            Sym1_2 = Universal_Channel(Sym0_2, L, SNR, (m_c+m_s+1));
            BitsRe2 = Receiver_II(m_c, m_s, theta_II, Block_Num, Sym1_2, C);
            err2 = sum(Bits2 ~= BitsRe2);
            BER(2, l, dB+1) = err2 / length(Bits2);
            if err2 == 0
                fprintf('  >>> CSK-CIM-DCSK-II 误码率为0, 提前跳过后续高信噪比点\n');
                skip_flags(2) = true;
            end
        end

        if ~skip_flags(3)
            [Bits3, Sym0_3] = Tx_CIM_DCSK(m, theta_II, Block_Num);
            Sym1_3 = Universal_Channel(Sym0_3, L, SNR, (m+1));
            BitsRe3 = Rx_CIM_DCSK(m, theta_II, Block_Num, Sym1_3);
            err3 = sum(Bits3(:).' ~= BitsRe3);
            BER(3, l, dB+1) = err3 / numel(Bits3);
            if err3 == 0
                fprintf('  >>> CIM-DCSK 误码率为0, 提前跳过后续高信噪比点\n');
                skip_flags(3) = true;
            end
        end

        if ~skip_flags(4)
            [Bits4, Sym0_4] = Tx_PI_DCSK(m, theta_II, Block_Num);
            Sym1_4 = Universal_Channel(Sym0_4, L, SNR, (m+1));
            BitsRe4 = Rx_PI_DCSK(m, theta_II, Block_Num, Sym1_4);
            err4 = sum(Bits4(:).' ~= BitsRe4);
            BER(4, l, dB+1) = err4 / numel(Bits4);
            if err4 == 0
                fprintf('  >>> PI-DCSK 误码率为0, 提前跳过后续高信噪比点\n');
                skip_flags(4) = true;
            end
        end
        if all(skip_flags)
            fprintf('  >>> 所有系统误码率均已降为0,提前结束当前信道的仿真！\n');
            break;
        end
    end
end

figure('Name', 'Figure 3.11 Reproduction');
box on; hold on;
colors = {'k', 'b', 'm', 'r'};
markers = {'o', 'd', 's', '*'};
names = {'CSK-CIM-DCSK-I', 'CSK-CIM-DCSK-II', 'CIM-DCSK', 'PI-DCSK'};

for l = 1:2
    line_style = '-';
    for sys = 1:4
        style = [colors{sys}, line_style, markers{sys}];
        display_name = names{sys};
        ber_data = squeeze(BER(sys, l, :));
        if l == 1
            semilogy(0:1:24, ber_data, style, ...
                'LineWidth', 1.5, 'MarkerSize', 7, 'DisplayName', display_name);
        else
            semilogy(0:1:24, ber_data, style, ...
                'LineWidth', 1.5, 'MarkerSize', 7, 'HandleVisibility', 'off');
        end
    end
end

set(gca, 'YScale', 'log');
ylim([1e-5 1]); xlim([0 24]);
set(gca, 'XTick', 0:2:24);
xlabel('E_b/N_0 (dB)', 'FontSize', 12);
ylabel('BER', 'FontSize', 12);
legend('Location', 'SouthWest', 'FontSize', 10);
grid on;
title('AWGN 和多径 Rayleigh 衰落信道下不同系统性能对比');
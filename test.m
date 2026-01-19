clear; clc; close all;

M = 7;            
N = 2;            
C = 0;   % 你可以尝试改变C的值来测试CP逻辑是否健壮          
Block_Num = 1000; % 测试逻辑时可以适当减少数量加快速度
% L = 1; % 理想信道不需要L

disp('正在进行理想信道自环测试...');

% 1. 发射
[Bits, Symbols0] = Transmitter(M, N, Block_Num, C);

% 2. 直接接收 (跳过 Channel)
Bitsre = Receiver(M, N, Block_Num, C, Symbols0);

% 3. 计算误码数
error_count = sum(Bits ~= Bitsre);
BER = error_count / (N * (M+1) * Block_Num);

fprintf('误码数: %d\n', error_count);
fprintf('误码率 (BER): %f\n', BER);

if BER == 0
    disp('>> 验证成功：发射机与接收机逻辑匹配。');
else
    disp('>> 验证失败：即使无噪声也存在误码，请检查索引或相关算法。');
end
clear; clc; close all;

M = 7;            
N = 2;            
C = 0;             
Block_Num = 10000;   
L = 1;

total=zeros(1,21);

for dB =0:1:20
    disp(dB);
    SNR=10^(dB/10);
    [Bits,Symbols0]=Transmitter(M,N,Block_Num,C);
    Symbols1=Channel(Symbols0,L,SNR);
    Bitsre=Receiver(M,N,Block_Num,C,Symbols1);
    total(1,dB+1)=sum(Bits~=Bitsre)/(N*(M+1)*Block_Num);
end

figure();
box on;hold on;
plot(0:1:20,total(1,:),'bo-');
set(gca,'Yscalse','log');
ylim([1e-6 1]);
xlabel('Eb/N0 (dB)');
ylabel('BER');
legend('MCSI-DCSK');
grid on;




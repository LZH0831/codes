function [Bits, Symbols0]=Transmitter_II(m_c,m_s,theta,Block_Num,C)       
    P=2^m_c;          
    R=theta/P;     
    beta=2*theta+2*C;   
    bits=m_c+m_s+1; 
    Bits=randi([0, 1], 1, bits * Block_Num);
    Bits2=reshape(Bits, bits, Block_Num);
    weight_c=2.^((m_c-1):-1:0);
    weight_s=2.^((m_s-1):-1:0);
    
    a_arr=weight_c*Bits2(1:m_c,:);               
    b_arr=weight_s*Bits2(m_c+1:m_c+m_s,:);       
    q_arr=2*Bits2(end, :)-1;                    
    
    H = hadamard(P); 
    w_info=H(1:P, :); 
    Symbols0=zeros(beta, Block_Num);
    for b_idx=1:Block_Num
        a=a_arr(b_idx);
        b=b_arr(b_idx);
        q=q_arr(b_idx);
        
        w_a=w_info(a + 1, :);
        x0=rand();
        c0=generate_chaos_seq(theta, x0);
        c=(c0-mean(c0))/std(c0);
        
        Cx_shifted=circshift(c, [0, b]); 
        x_segments=reshape(Cx_shifted, R, P);
        modulated_segments=x_segments.*w_a;
        info_signal=q*reshape(modulated_segments, 1, theta);
        c_cp = [c(end-C+1:end), c];
        info_cp = [info_signal(end-C+1:end), info_signal];
        sk=[c_cp, info_cp]; 
        Symbols0(:, b_idx)=sk.';
    end
end
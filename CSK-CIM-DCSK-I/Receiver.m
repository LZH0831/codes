function Bitsre=Receiver(m_c,m_s,theta,Block_Num,Symbols1,r_arr,C)
    N=2^m_c;
    P=2^(m_c+1);
    M=2^m_s;
    bits=m_c+m_s+1;
    Bitsre_mat=zeros(bits,Block_Num);

    H=hadamard(P);
    W=H(1:N,:);
    for b_idx=1:Block_Num
        cur_block=Symbols1(C+1:end,b_idx);
        r_segments=reshape(cur_block,theta,P).';
        r_s=(W*r_segments)/P;
        r_index=r_arr(b_idx);
        cx_tilde=r_s(r_index,:);
        I_m=sum(r_s.^2,2);
        I_m(r_index)=0;
        [~,a_idx]=max(I_m);
        a_hat=a_idx-1;
        r_inf=r_s(a_idx,:);
        D_n=zeros(1,M);
        for n=0:M-1
            cx_shifted=circshift(cx_tilde,[0,n]);
            D_n(n+1)=sum(cx_shifted.*r_inf);
        end
        [~,b_pos]=max(abs(D_n));
        b_hat=b_pos-1;
        q_hat=sign(D_n(b_pos));
        a_bits=bitget(a_hat,m_c:-1:1);
        b_bits=bitget(b_hat,m_s:-1:1);
        q_bit=(q_hat+1)/2;
        Bitsre_mat(:,b_idx)=[a_bits,b_bits,q_bit].';
    end
    Bitsre=Bitsre_mat(:).'; 
end
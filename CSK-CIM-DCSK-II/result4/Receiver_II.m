function Bitsre=Receiver_II(m_c, m_s, theta, Block_Num, Symbols1, C)
    M=2^m_c;            
    P=2^m_c;            
    N=2^m_s;            
    R=theta / P;        
    bits=m_c + m_s + 1;     
    Bitsre_mat=zeros(bits, Block_Num);
    
    W=hadamard(P);
    w_info=W(1:P, :); 
    W_expanded=kron(w_info, ones(1, R)); 
    
    for b_idx=1:Block_Num
        cur_block=Symbols1(:, b_idx).'; 
        r_ref=cur_block(C+1 : C+theta);
        r_inf=cur_block(2*C+theta+1 : 2*C+2*theta);
        r_tp=W_expanded.*repmat(r_inf, M, 1);
        r_st=zeros(N, theta);
        for n=1:N
            shift_amount=n-1; 
            r_st(n, :)=circshift(r_ref, [0, shift_amount]);
        end
        I_matrix=r_tp*r_st.';
        [~, max_idx]=max(abs(I_matrix(:)));
        [m_hat, n_hat]=ind2sub([M, N], max_idx);
        a_hat=m_hat-1;
        b_hat=n_hat-1;
        q_hat=sign(I_matrix(m_hat, n_hat));

        a_bits=bitget(a_hat, m_c:-1:1);
        b_bits=bitget(b_hat, m_s:-1:1);
        q_bit=(q_hat + 1)/2;
        
        Bitsre_mat(:, b_idx)=[a_bits, b_bits, q_bit].';
    end
    Bitsre=Bitsre_mat(:).';
end
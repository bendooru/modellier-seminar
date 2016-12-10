function idx = findNearestVec(v, A)
    % findet Vektor mit geringster Distanz zu v in A, wobei v ein mx1-Vektor ist
    % und A eine mxn-Matrix bestehend aus n mx1-Vektoren
    if size(v, 1) == size(A, 1)
        % spaltenweise euklidische Norm
        [~, idx] = min(sum((A - repmat(v,1,size(A,2))).^2, 1));
    else
        warning('Wrong vector or matrix dimension in findNearestVec.');
        idx = NaN;
    end
end
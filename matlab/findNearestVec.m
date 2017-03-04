function idx = findNearestVec(v, A)
    % FINDNEARESTVEC Findet Vektor mit geringster Distanz zu v in A
    %   Aufruf: idx = findNearestVec(v, A) mit
    %   v       Ausgangsvektor
    %   A       Matrix, deren Spalten Vektoren enthalten, die gleichgroß wie v sind
    %   idx     Index mit ||A(:,idx) - v|| minimal
    if size(v, 1) == size(A, 1)
        % spaltenweise euklidische Norm
        [~, idx] = min(sum((A - repmat(v,1,size(A,2))).^2, 1));
    else
        warning('Wrong vector or matrix dimension in findNearestVec.');
        idx = NaN;
    end
end
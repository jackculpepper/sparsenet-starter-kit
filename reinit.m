

%% select images for the test set
switch datasource
    case 'images'
        load ../data/IMAGES.mat

        [Nsz,Nsz,K] = size(IMAGES);

        Xtest = zeros( L, Btest );
        
        % extract subimages at random from this image to make data vector X
        for b = 1:Btest
            %% choose an image
            i = ceil(K*rand);

            %% choose a position
            r = buff + ceil((Nsz-Lsz-2*buff)*rand);
            c = buff + ceil((Nsz-Lsz-2*buff)*rand);

            Xtest(:,b) = reshape(IMAGES(r:r+Lsz-1,c:c+Lsz-1,i), L, 1);

            %% normalize each patch to mean zero, unit variance
            %% note: you may not want to do this! however, doing so makes
            %% it easy to get things working on a variety of data sets.

            Xtest(:,b) = Xtest(:,b) - mean(Xtest(:,b));
            Xtest(:,b) = Xtest(:,b) / std(Xtest(:,b));
        end

        atest0 = zeros(M, Btest);
        
end

a0 = zeros(M,B);

phi = randn(L,M);
phi = phi*diag(1./sqrt(sum(phi.^2)));

update = 1;

eta_log = [];
objtest_log = [];
snr_log = [];


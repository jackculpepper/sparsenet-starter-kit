

for t = 1:num_trials


    switch datasource
        case 'images'
            %% choose an image for this batch
            i = ceil(K*rand);
            I = IMAGES(:,:,i);

            X = zeros(L,B);

            % extract subimages at random from this image to make data vector X
            for b = 1:B
                r = buff + ceil((Nsz-Lsz-2*buff)*rand);
                c = buff + ceil((Nsz-Lsz-2*buff)*rand);

                X(:,b) = reshape(I(r:r+Lsz-1,c:c+Lsz-1), L, 1);

                %% normalize each patch to mean zero, unit variance
                %% note: you may not want to do this! however, doing so makes
                %% it easy to get things working on a variety of data sets.

                X(:,b) = X(:,b) - mean(X(:,b));
                X(:,b) = X(:,b) / std(X(:,b));
            end

    end


    tic
    switch mintype_inf
        case 'lbfgsb'

            %% stupidest initialization, but consistent
            a0 = zeros(M, 1);
            a = zeros(M, B); 

            %% run lbfgsb on each patch, separately.

            %% note this could be sped up by running on the entire batch.
            %% however, for large batches you may then need to increase the
            %% number of line searches to get a consistent solution.

            %% running separately is slower, but consistent.

            for b = 1:B
                [a1,fx,exitflag,userdata] = lbfgs(@objfun_a,a0(:),lb,ub,nb, ...
                    opts,phi,X(:,b),lambda);
                a(:,b) = a1;
            end

    end
    time_inf = toc;

    E = X - phi*a;
    snr = 10 * log10 ( sum(X(:).^2) / sum(E(:).^2) );

    snr_log = snr_log(1:update-1);
    snr_log = [ snr_log ; snr ];


    tic
    % update bases
    switch mintype_lrn
        case 'gd'
            [obj0,g] = objfun_phi(phi(:),a,X,lambda,gamma);
            dphi = reshape(g,L,M);

            phi1 = phi - eta*dphi;

            [obj1,dphi] = objfun_phi(phi1(:),a,X,lambda,gamma);

            if obj1 > obj0
                fprintf('warning: objfun increased\n');
            end

            %% pursue a constant change in angle
            angle_phi = acos(phi1(:)' * phi(:) / sqrt(sum(phi1(:).^2)) / sqrt(sum(phi(:).^2)));
            if angle_phi < target_angle
                eta = eta*1.01;
            else
                eta = eta*0.99;
            end

            phi = phi1;

            eta_log = eta_log(1:update-1);
            eta_log = [ eta_log ; eta ];


    end
    time_lrn = toc;


    if test_every == 1 || mod(update,test_every) == 0
        %% do inference on the test set
        switch mintype_inf
            case 'lbfgsb'
                atest1 = zeros(M, Btest);
                for i = 1:Btest
                    atest0 = zeros(M,1);
                    [atest1(:,i),fx,exitflag,userdata] = lbfgs(@objfun_a, ...
                        atest0,lb,ub,nb,opts,phi,Xtest(:,i),lambda);
                    fprintf('\r%d / %d', i, Btest);
                end
                atest0 = atest1;
                fprintf('\n');
        end

        objtest = objfun_a(atest1(:),phi,Xtest,lambda);
        objtest_log = [ objtest_log objtest ];

        sfigure(7);
        plot(test_every*(1:length(objtest_log)), objtest_log, 'r-');
        title('Test Set Energy History');
        xlabel('Iteration');
        ylabel('E');
    end


    %% display

    if display_every == 1 || mod(update,display_every) == 0
        % Display the bfs
        array = render_network(phi, Mrows);
 
        sfigure(1); colormap(gray);
        imagesc(array, [-1 1]);
        axis image off;
 
        EI = phi*a(:,1);

        mx = max(abs([ EI(:) ; X(:,1) ]));

        sfigure(4);
        subplot(1,2,1),imagesc(reshape(EI,Lsz,Lsz), [-mx mx]),title('EI');
            colormap(gray),axis image off;
        subplot(1,2,2),imagesc(reshape(X(:,1),Lsz,Lsz),[-mx mx]),title('X');
            colormap(gray),axis image off;

        sfigure(5);
        bar(a(:,1));
        axis tight;

        sfigure(6);
        plot(1:update, eta_log, 'r-');
        title('\eta History');
        xlabel('Iteration');
        ylabel('\eta');

        sfigure(12);
        plot(1:update, snr_log, 'r-');
        title('Reconstruction SNR History');
        xlabel('Iteration');
        ylabel('SNR');

        if save_every == 1 || mod(update,save_every) == 0
            array_frame = uint8(255*((array+1)/2)+1);

            [sucess,msg,msgid] = mkdir(sprintf('state/%s', paramstr));
 
            imwrite(array_frame, ...
                sprintf('state/%s/bf_up=%06d.png',paramstr,update), 'png');
            eval(sprintf('save state/%s/phi.mat phi',paramstr));

            saveparamscmd = sprintf('save state/%s/params.mat', paramstr);
            saveparamscmd = sprintf('%s lambda', saveparamscmd);
            saveparamscmd = sprintf('%s gamma', saveparamscmd);
            saveparamscmd = sprintf('%s eta', saveparamscmd);
            saveparamscmd = sprintf('%s eta_log', saveparamscmd);
            saveparamscmd = sprintf('%s objtest_log', saveparamscmd);
            saveparamscmd = sprintf('%s L', saveparamscmd);
            saveparamscmd = sprintf('%s M', saveparamscmd);
            saveparamscmd = sprintf('%s mintype_inf', saveparamscmd);
            saveparamscmd = sprintf('%s update', saveparamscmd);

            eval(saveparamscmd);
    

        end
        drawnow;

    end

    %% renormalize columns of phi to have unit length
    phi = phi*diag(1./sqrt(sum(phi.^2)));

    fprintf('%s', paramstr);
    fprintf(' update %d o0 %.8f o1 %.8f eta %.4f', update, obj0, obj1, eta);
    fprintf(' ang %.4f', angle_phi);
    fprintf(' snr %.4f inf %.4f lrn %.4f\n', snr, time_inf, time_lrn);

    update = update + 1;
end


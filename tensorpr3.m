classdef tensorpr3
    properties
        R
        alpha
        v
    end
    
    methods
        function obj = tensorpr3(R, alpha, v)
            % TENSORPR3 Create a TensorPR3 problem
            % A tensor PR3 problem solves:
            %   x = alpha*R*kron(x,x) + (1-alpha) v
            % The matrix R is required.
            % The value alpha defaults to 1/2
            % and the value v defaults to 1/n, where R is n-by-n^2
            % The matrix R must be column stochastic.
            
            if ~ismatrix(R)
                if ndims(R) ~= 3
                    error('tensorpr3:invalidSize', ...
                        'tensorpr3 is only defined by 3rd order tensors');
                end
                n = size(R,1);
                R = reshape(R,n,n^2);
            else
                n = size(R,1);
                if size(R,2) ~= n^2
                    error('tensorpr3:invalidSize', ...
                        'tensorpr3 needs an n-by-n^2 stochastic matrix');
                end
            end

            n = size(R,1);
            if nargin < 2
                alpha = 1/2;
            end
            if nargin < 3
                v = ones(n,1)/n;
            end
            % error checking
            if abs(sum(v) - 1) > n*eps
                error('tensorpr3:notStochastic',...
                    'input vector v is not stochastic.');
            end
            
            if any( abs( sum(R) - ones(1,size(R,2)) ) > n*eps )
                error('tensorpr3:notStochastic',...
                    'input matrix R is not column stochastic.');
            end
            
            obj.R = R;
            obj.alpha = alpha;
            obj.v = v;
        end
        
        function J = jacobian(obj,x,gamma)
            % JACOBIAN The Jacobian of the problem at x with shift gamma
            
            if nargin < 3
                gamma = 1;
            end
            
            n = size(obj.R,1);
            I = eye(n);
            J = obj.alpha*gamma*obj.R*(kron(x,I) + kron(I,x)) + (1-gamma)*I;
        end
        
        function r = residual(obj,x)
            % RESIDUAL The residual of the problem for solution x
            r = obj.alpha * (obj.R * kron(x, x)) + (1-obj.alpha) * obj.v - x;
        end
        
        function varargout = solve(obj,varargin)
            % SOLVE Use a shifted iteration to solve the tensor PageRank problem 
            if obj.alpha < 1/2
                [varargout{1:nargout}] = obj.shifted(varargin{:});
            else
                [varargout{1:nargout}] = obj.innout(varargin{:});
            end
        end
            
        
        function [x,hist,flag] = shifted(obj,varargin)
            % SHIFTED Run the power method on a tensor PageRank problem
            %
            % x = shifted(P) solves with gamma=1/2, which may or may not
            % converge.
            %
            % x = shifted(P,gamma) solves with a shift of gamma
            % x = shifted(P,'key',value,'key',value,...)
            % x = shifted(P,gamma,'key',value,'key',value,...)
            %
            % Valid additional parameters
            %   'maxiter' : the maximum number of iterations, set to 1000
            %   'tol' : the solution tolerance, set to 1e-8
            %   'xtrue' : an optional true solution to get errors
            %             to report for analytic descriptions

            if nargin>1 && isnumeric(varargin{1})
                gamma = varargin{1};
                varargin = varargin(2:end);
            else
                gamma = 0.5;
            end
            
            p = inputParser;
            p.addOptional('maxiter',1e5);
            p.addOptional('tol',1e-8);
            p.addOptional('xtrue',[]);
            p.parse(varargin{:});
            opts = p.Results;
            
            % Extract data from obj
            R = obj.R;
            n = size(R,1);
            a = obj.alpha;
            v = obj.v;
            
            niter = opts.maxiter;
            tol = opts.tol;
            
            Gamma = 1 / (1+gamma);
            xcur = zeros(n,1); % this allows us to keep v = 1/n :-)
            xcur = xcur + v; 
            
            hist = zeros(niter, 1);
            
            for i=1:niter
                % TODO make this iteration better
                y = a*(R*kron(xcur, xcur)); 
                z = y * Gamma + Gamma*(1-sum(y))*v;
                xn = z + (1-sum(z))*xcur;
                
                curdiff = norm(xn - xcur, 1);
                hist(i) = curdiff;
                if ~isempty(opts.xtrue)
                    hist(i) = norm(xn - opts.xtrue,inf);
                end
                
                % check for termination
                if curdiff <= tol
                    break;
                end
                
                % switch solutions
                xcur = xn;
            end
            
            hist = hist(1:i,:);
            if i == niter && curdiff > tol
                warning('tensorpr3:notConverged',...
                    'did not converge after %i iterations to %e tolerance',...
                    niter, tol);
                flag = 0;
            else
                flag = 1;
            end
            
            x = xn ./ sum(xn);
        end
        
        function [x, hist, flag] = inverseiter(obj, varargin)
            % INVERSEITER solve the tensorpr3 iteration using an inverse iteration
            
            p = inputParser;
            p.addOptional('maxiter',1e5);
            p.addOptional('tol',1e-8);
            p.addOptional('xtrue',[]);
            p.parse(varargin{:});
            opts = p.Results;
            
            % Extract data from obj
            R = obj.R;
            n = size(R,1);
            a = obj.alpha;
            v = obj.v;
            
            niter = opts.maxiter;
            tol = opts.tol;
            xcur = zeros(n,1);
            xcur = xcur + v;
            
            hist = zeros(niter, 1);
            
            I = eye(n);
            
            for i = 1:niter
                A = kron(xcur, I) + kron(I, xcur);
                A = I - a/2*R*A;
                b = (1-a)*v;
                xn = A \ b;
                xn = xn ./ norm(xn, 1);
                
                curdiff = norm(xn - xcur, 1);
                hist(i) = curdiff;
                
                if ~isempty(opts.xtrue), hist(i) = norm(xn - opts.xtrue,inf); end
                
                if curdiff <= tol
                    break
                end
           
                xcur = xn;
            end
            
            
            hist = hist(1:i, :);
            if i == niter && curdiff > tol
                warning('tensorpr3:notConverged',...
                    'did not converge after %i iterations to %e tolerance',...
                    niter, tol);
                flag = 0;
            else
                flag = 1;
            end
            
            x = xn;
        end
        
        
        function [x, hist, flag] = newton(obj, varargin)
            % NEWTON Solve the tensorpr3 iteration using Newton's method
            
            p = inputParser;
            p.addOptional('maxiter',1e5);
            p.addOptional('tol',1e-8);
            p.addOptional('xtrue',[]);
            p.addOptional('randInit', 0);
            p.parse(varargin{:});
            opts = p.Results;
            
            % Extract data from obj
            R = obj.R;
            n = size(R,1);
            a = obj.alpha;
            v = obj.v;
            
            niter = opts.maxiter;
            tol = opts.tol;
            xcur = zeros(n,1);
            if opts.randInit ~= 0
                xcur = rand(n, 1);
                xcur = xcur ./ sum(xcur);
            else
                xcur = xcur + v;
            end
            
            hist = zeros(niter, 1);
            
            I = eye(n);
            for i = 1:niter
                A = a*R*(kron(xcur, I) + kron(I, xcur)) - I;
                b = a*R*kron(xcur, xcur) - (1-a)*v; % residual
                xn = A \ b;
                xn = xn ./ sum(xn);
                
                curdiff = norm(xn - xcur, 1);
                hist(i) = curdiff;
                
                if ~isempty(opts.xtrue), hist(i) = norm(xn - opts.xtrue,inf); end
                
                if curdiff <= tol
                    break
                end
           
                xcur = xn;
            end
            
            hist = hist(1:i, :);
            if i == niter && curdiff > tol
                warning('tensorpr3:notConverged',...
                    'did not converge after %i iterations to %e tolerance',...
                    niter, tol);
                flag = 0;
            else
                flag = 1;
            end
            
            x = xn;
        end
    
        function [x, hist, flag] = innout(obj, varargin)
            % INNOUT Solve via an inner-outer iteration
            
            p = inputParser;
            p.addOptional('maxiter',1e5);
            p.addOptional('tol',1e-8);
            p.addOptional('xtrue',[]);
            p.parse(varargin{:});
            opts = p.Results;
            niter = opts.maxiter;
            tol = opts.tol;
            
            % Extract data from obj
            R = obj.R;
            n = size(R,1);
            a = obj.alpha;
            v = obj.v;
            
            Rt = a*R + (1-a)*v*ones(1, n^2);
            at = a / 2;
            xt = v;
            hist = zeros(niter, 1);
            for i = 1:niter
                xt = xt ./ sum(xt);
                Tr = tensorpr3(Rt, at, xt);
                xt2 = Tr.solve('tol',tol/10);
                curdiff = norm(obj.residual(xt2), 1);
                hist(i) = curdiff;
                if ~isempty(opts.xtrue)
                    hist(i) = norm(xt2 - opts.xtrue,inf);
                end
                
                % check for termination
                if curdiff <= tol
                    break;
                end
                % switch solutions
                xt = xt2;                
            end
            hist = hist(1:i,:);
            if i == niter && curdiff > tol
                warning('did not converge');
                flag = 0;
            else
                flag = 1;
            end
            
            x = xt2;
        end
        
        function [P,MR] = markov(obj)
            % MARKOV Return the tensors and matrices for the modified Markov chain 
            %
            % Example:
            %   R = [1/3 1/3 1/3 1/3 0 0 0 0 0;
            %        1/3 1/3 1/3 1/3 0 1/2 1 0 1;
            %        1/3 1/3 1/3 1/3 1 1/2 0 1 0];
            %   pr = tensorpr3(R,0.99);
            %   gamma = li_gamma(markov(pr))
            
            n = size(obj.R,1);
            e = ones(n,1);
            MR = obj.alpha * obj.R + (1-obj.alpha)*(obj.v * kron(e',e'));
            P = reshape(obj.R,n,n,n);
        end
    
        function P = markov2(obj)
            % MARKOV2 The transition matrix for the 2nd order Markov chain.
            %
            % M = markov2(pr) returns the Markov chain transition matrix
            % for the second order Markov chain problem with a unique
            % solution corresponding to the tensor PageRank problem. (The
            % solution is only unique if alpha < 1, but the second order
            % chain is well defined regardless.)
            n = size(obj.R, 1);
            e = ones(n,1);
            MR = obj.alpha * obj.R + (1-obj.alpha)*(obj.v * kron(e',e'));
            n = size(MR, 1);
            P = zeros(n^2, n^2);
            for i = 1:n     % group i
                tmp = zeros(n^2, n);
                for j = 1:n % column j
                    ej = zeros(n, 1);
                    ej(j) = 1;
                    tmp(:, j) = kron(ej, MR(:, (i-1)*n + j));
                end
                P(:, (i-1)*n +1: i*n) = tmp;
            end
        end
    
    end
end
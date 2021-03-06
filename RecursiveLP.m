clear
outfileID = fopen('solutions.in','w');
firstFile = 1;
% instances that cannot be solved by LP
problemList = [2 6 18 24 30 35 37 45 53 59 63 76 87 90 94 104 110 111 113 114 120 123 129 132 137 140 144 148 153 160 168 169 171 173 176 178 184 187 189 200 201 204 206 207 215 222 224 225 228 229 230 239 259 261 267 269 285 287 289 290 296 303 314 316 317 334 340 349 360 361 368 370 377 380 405 419 421 436 438 444 445 453 460 464 467 468 483 492];
num_sol = 0;
for instID = 1:492
    %extract adjacency matrix and transpose of adjacency matrix
    if firstFile
        firstFile = 0;
    else
        fprintf(outfileID, '\n');
    end
    %     if ~any(instID==problemList)
    filename = sprintf('phase1-processed/%d.in', instID);
    %     filename = 'team.in';
    fid = fopen(filename, 'r');
    num_v = fgetl(fid);
    num_v = str2num(num_v);
    
    children = str2num(fgetl(fid));
    children = children + 1;
    Nrow_original = num_v;
    Ncol_original = num_v;
    
    Identity_matrix = eye(Nrow_original)* -1;
    M = dlmread(filename);
    
    if (size(M, 1) == size(M, 2) + 1)
        M(1, :) = [];
    else
        M(1:2,:) = [];
    end
    M_transpose = M.';
    
     G = digraph(M);
%             figure
%             plot(G);
%             drawnow
%             titlename = sprintf('initial graph %d', instID);
%             title(titlename);
    
    num_e = size(G.Edges, 1);
    density = num_e/(num_v * (num_v - 1));
    
    if (density < 0.5) && (num_v < 200) && ~any(instID==problemList)
        num_sol = num_sol + 1;
        %form Aeq
        new_M = zeros(num_v, num_v^2, 'double');
        for i = 1:num_v
            start_i = (i - 1)*num_v + 1;
            end_i = i*num_v;
            new_M(i, start_i : end_i) = M(i,:);
        end
        
        new_M = [new_M Identity_matrix];
        
        new_M_transpose = zeros(num_v, num_v^2, 'double');
        for i = 1:num_v
            to_be_diagnolized = M(i, :);
            D = diag(to_be_diagnolized);
            col_start = (i-1)*num_v + 1;
            col_end = i*num_v;
            new_M_transpose(1:num_v,col_start:col_end) = D;
        end
        new_M_transpose = [new_M_transpose Identity_matrix];
        
        Aeq = [new_M; new_M_transpose];
        
        %form beq
        beq = zeros(num_v * 2, 1, 'double');
        
        %form upper bound and lower bound for x
        lb = zeros(num_v^2 + num_v,1,'double');
        ub = ones(num_v^2 + num_v,1,'double');
        
        %form f
        M_transpose_weight = M_transpose * -1;
        for i = children
            children_row = M_transpose_weight(i,:);
            children_row(children_row == -1) = -2;
            M_transpose_weight(i,:) = children_row;
        end
        
        f = reshape(M_transpose_weight,1, num_v*num_v);
        num_v_zeros = zeros(1, num_v, 'double');
        f = horzcat(f, num_v_zeros);
        
        intcon = 1:num_v*num_v+num_v;
        
        continueUpdate = 1;
        A_ub = [];
        b_ub = [];
        num_iter = 0;
        while continueUpdate == 1
            num_iter = num_iter + 1;
            options = optimset('Display','off');
            x = intlinprog(f, intcon, A_ub, b_ub, Aeq, beq, lb, ub);
            [continueUpdate, A_ub, b_ub] ...
                = updateLP(x, num_v, A_ub, b_ub);
        end
        
        % visualize solution
        A = zeros(num_v);
        for i = 1:num_v
            startID = (i-1)*num_v+1;
            endID = i*num_v;
            A(i, :) = x(startID:endID);
        end
        Gx = digraph(A);
        %             figure
        %             plot(Gx)
        %             titlename = sprintf('instance %d solution', instID);
        %             title(titlename);
        fx = x(endID + 1:num_v^2+num_v);
        
        % retrieve cycles in solution for output
        existsCycle = 0;
        firstCycle = 1;
        for vID = 1:num_v
            if fx(vID) == 1
                existsCycle = 1;
                if firstCycle
                    firstCycle = 0;
                else
                    fprintf(outfileID, '; ');
                end
                T = dfsearch(Gx, vID, ...
                    {'edgetonew', 'edgetodiscovered', 'discovernode'});
                v = T.Node(T.Event == 'discovernode',:);
                fx(v)=0;
                v = v-1;
                for vid = 1:length(v)-1
                    fprintf(outfileID, '%d ', v(vid));
                end
                fprintf(outfileID, '%d', v(vid+1));
            end
        end
        
        if ~existsCycle
            fprintf(outfileID, 'None');
        end
    else % else use greedy
        greedy_cycles = greedy_find_cycles(num_v, children, M) - 1;
        %display(greedy_cycles);
        if isempty(greedy_cycles)
            fprintf(outfileID, 'None');
        else 
            if size(greedy_cycles, 1) == 1 
                greedy_col = 1; 
                greedy_row = 1; 
                while (greedy_col < 5) & (greedy_cycles(greedy_row, greedy_col + 1) >= 0)
                    fprintf(outfileID, '%d ', greedy_cycles(greedy_row, greedy_col));
                    greedy_col = greedy_col + 1; 
                end
                fprintf(outfileID, '%d', greedy_cycles(greedy_row, greedy_col));
            else 
                for greedy_row = 1: size(greedy_cycles, 1)-1
                    greedy_col = 1; 
                    while greedy_col < 5 && greedy_cycles(greedy_row, greedy_col + 1) >= 0
                        fprintf(outfileID, '%d ', greedy_cycles(greedy_row, greedy_col));
                        greedy_col = greedy_col + 1; 
                    end
                    fprintf(outfileID, '%d; ', greedy_cycles(greedy_row, greedy_col));
                end 
                greedy_col = 1; 
                greedy_row = greedy_row + 1; 
                while (greedy_col < 5) & (greedy_cycles(greedy_row, greedy_col + 1) >= 0)
                    fprintf(outfileID, '%d ', greedy_cycles(greedy_row, greedy_col));
                    greedy_col = greedy_col + 1; 
                end
                fprintf(outfileID, '%d', greedy_cycles(greedy_row, greedy_col));
            end 
        end 
        
    end
    
    fclose(fid);
end
fclose(outfileID);

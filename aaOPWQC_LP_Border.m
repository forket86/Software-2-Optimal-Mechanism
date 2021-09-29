if 1 % get file name, say hello
    [~, thisFileName, ~] = fileparts(mfilename('fullpath'));
    thisLpName = strrep(thisFileName, 'fn_', '');
    fprintf('\n-----------------------------------')
    fprintf('\nvvv from %s:  vvvvvv',...
        thisFileName)
end

thisScriptFolder = pwd;

if 1 % create subfolder and move in it
    if 1 % make subfolder for output files
        if 1 % make dateTimeString
            ecco = clock;
            dateTimeString = num2str(ecco(1));
            dateTimeString = [dateTimeString '-' num2str(ecco(2))];
            dateTimeString = [dateTimeString '-' num2str(ecco(3))];
            dateTimeString = [dateTimeString '_' num2str(ecco(4))];
            dateTimeString = [dateTimeString '-' num2str(ecco(5))];
        end
        subFolderName = [dateTimeString '_' thisFileName];
    end
    mkdir([desktopFolder subFolderName]);
    fprintf('\n   New subfolder %s created', subFolderName)
    cd([desktopFolder subFolderName]);
    fprintf('\n   we now are inside the folder %s', subFolderName)
end

if 1 % solve the LP
    if 1 % write AMPL's .MOD file
        modFileName = [thisLpName '.mod'];
        fid = fopen(modFileName, 'wt');
        if 1 % parameters
            fprintf(fid,'# --- Parameters ----');
            fprintf(fid,'\n param T; # num of Cost values ');
            fprintf(fid,'\n param S; # num of Suppliers ');
            fprintf(fid,'\n param D; # to rescale Q ');
            fprintf(fid,'\n param f {1..T};');
            fprintf(fid,'\n param F {1..T};');
            fprintf(fid,'\n param c {1..T};');
            fprintf(fid,'\n param w {1..T};');
            fprintf(fid,'\n');
        end
        if 1 % variables
            fprintf(fid,'\n# --- Decision variables ----');
            fprintf(fid,'\n var Q {1..T}; ');
            fprintf(fid,'\n');
        end
        
        if 1 % objective function
            fprintf(fid,'\n# --- LP ----');
            fprintf(fid,'\n maximize O_BUYER_SURPLUS:');
            fprintf(fid,'\n sum{t in 1..T} (f[t]*w[t]*Q[t]);');
            %fprintf(fid,'\n ');
        end
        if 1 % constraints
            if 1 % BorderDemandConstraint
                fprintf(fid,'\n\n subject to BorderDemandConstraint {t in 1..T}:');
                fprintf(fid,'\n sum{k in 1..t} (Q[k]*f[k]) <= D*(1-(1-F[t])^S)/S;');
            end
            if 1 % Non Negativity
                fprintf(fid,'\n\n subject to QNonNegT:');
                fprintf(fid,'\n -Q[T] <= 0;');
            end
            if 1 % qMon
                fprintf(fid,'\n\n subject to QMon {t in 1..T-1}:');
                fprintf(fid,'\n - Q[t] + Q[t+1] <= 0;');
            end
        end
        fclose(fid);
        fprintf('\n    ''%s'' (text file) written', modFileName)
        
    end
    if 1 % write AMPL's .DAT file
        datFileName = [thisLpName '.dat'];
        fid = fopen(datFileName, 'wt');
        if 1 % write parameters
            
            fprintf(fid,'param T = %d;\n\n', T);
            fprintf(fid,'param S = %d;\n\n', S);
            fprintf(fid,'param D = %d;\n\n', 1);
            if 1 % w
                fprintf(fid,'param w = \r\n');
                fprintf(fid,'\t');
                for t = 1:T
                    fprintf(fid,'%d\t', t);
                    fprintf(fid,'%.9f\r\n\t', w(t));
                end
                fprintf(fid,';\r\n\r\n');
            end
            
            if 1 % cost grid
                fprintf(fid,'param c = \r\n');
                fprintf(fid,'\t');
                for t = 1:T
                    fprintf(fid,'%d\t', t);
                    fprintf(fid,'%.9f\r\n\t', c(t));
                end
                fprintf(fid,';\r\n\r\n');
            end
            
            if 1 % f
                fprintf(fid,'param f = \r\n');
                fprintf(fid,'\t');
                for t = 1:T
                    fprintf(fid,'%d\t', t);
                    fprintf(fid,'%.9f\r\n\t', f(t));
                end
                fprintf(fid,';\r\n\r\n');
            end
            
            if 1 % F_marginal
                fprintf(fid,'param F = \r\n');
                fprintf(fid,'\t');
                for t = 1:T
                    fprintf(fid,'%d\t', t);
                    fprintf(fid,'%.9f\r\n\t', F(t));
                end
                fprintf(fid,';\r\n\r\n');
            end
            
        end
        fclose(fid);
        fprintf('\n    ''%s'' (text file) written', datFileName)
    end
    if 1 % write AMPL's .RUN file
        runFileName = [thisLpName '.run'];
        fid = fopen(runFileName, 'wt');
        if 1 % write: load .mod and .dat
            fprintf(fid,'# --- Load .mod and .dat ----\n');
            fprintf(fid,'reset;\n');
            fprintf(fid,'model %s;\n', modFileName);
            fprintf(fid,'data %s;\n', datFileName);
            fprintf(fid,'\n');
        end
        if 1 % write: display options
            fprintf(fid,'# --- Display options -----\n');
            %fprintf(fid,'option display_width 500;\n');
            %fprintf(fid,'option display_eps 1e-10;\n');
            %How to start the barrier algorithm:
            %0 (default) = 1 for MIP subproblems, else 3
            %1 = infeasibility-estimate start
            %2 = infeasibility-constant start
            %3 = standard start.
            %fprintf(fid,'option baralg 0;\n');
            %fprintf(fid,'option display_width 1000;\n');
            
            %fprintf(fid,'option gutter_width 1;\n');
            fprintf(fid,'\n');
        end
        if 0 % write: Write out Numerical LP -> Numerical_LP.txt
            fprintf(fid,'# --- Write out Numerical LP -----\n');
            NumLPFileName = ['Numerical_' thisLpName '.txt'];
            fprintf(fid,'expand >> %s;\n',NumLPFileName);
            fprintf(fid,'\n');
        end
        if 1 % write: call Cplex
            fprintf(fid,'# --- call CPLEX ----\n');
            fprintf(fid,'option solver ''%s'';\n', [cplexPath 'cplexamp']);
            fprintf(fid,'solve;\n\n');
        end
        if 1 % write: Store LP Value and optimal solution in .txt files
            fprintf(fid,'# --- Store optimal solution in .txt files --- \n');
            fprintf(fid,'print{t in 1..T}: Q[t] > Q_out.txt;\n');
            fprintf(fid,'close Q_out.txt;\n\n');
            fprintf(fid,'print O_BUYER_SURPLUS > LP_Value_out.txt;\n');
            fprintf(fid,'close LP_Value_out.txt;');
        end
        if 1 % write: Solution Report: _conname, _con.dual, _con.slack, _con.body, _con.ub, _con.lb
            fprintf(fid,'# --- Solution Report  --- \n');
            fprintf(fid,'display O_BUYER_SURPLUS > SOL_REPORT.txt;\n');
            fprintf(fid,'display _conname, _con.dual, _con.slack, _con.body, _con.ub, _con.lb  >> SOL_REPORT.txt;\r\n');
            fprintf(fid,'close SOL_REPORT.txt;\r\n\r\n');
        end
        if 1 % write: store slacks and Dual
            fprintf(fid,'print{t in 1..T}: BorderDemandConstraint[t].slack > BorderDemandConstraintSlacks_out.txt;\n');
            fprintf(fid,'close BorderDemandConstraintSlacks_out.txt;\n\n');
            
            fprintf(fid,'print{t in 1..T}: BorderDemandConstraint[t].dual > BorderDemandConstraintDuals_out.txt;\n');
            fprintf(fid,'close BorderDemandConstraintDuals_out.txt;\n\n');
            
            fprintf(fid,'print{t in 1..T-1}: QMon[t].slack > QMonSlacks_out.txt;\n');
            fprintf(fid,'close QMonSlacks_out.txt;\n\n');
            
            fprintf(fid,'print{t in 1..T-1}: QMon[t].dual > QMonDuals_out.txt;\n');
            fprintf(fid,'close QMonDuals_out.txt;\n\n');
            
            fprintf(fid,'print: QNonNegT.slack > QNonNegTSlacks_out.txt;\n');
            fprintf(fid,'close QNonNegTSlacks_out.txt;\n\n');
            
            fprintf(fid,'print: QNonNegT.dual > QNonNegTDuals_out.txt;\n');
            fprintf(fid,'close QNonNegTDuals_out.txt;\n\n');
        end
        if 1 % close .run file
            fclose(fid);
        end
        fprintf('\n    ''%s'' (text file) written', runFileName)
    end
    if 1 % system call: feed .RUN file to AMPL
        fprintf('\n\nSolving the given LP %s with CPLEX ... \n', thisLpName)
        system([amplPath 'ampl ' runFileName]);
        fprintf('CPLEX is done.\n')
    end
    if 1 % Load:  LP_Value, Q, M (function output)
        fprintf('\n  Loading CPLEX output in Matlab ... ')
        
        load LP_Value_out.txt;
        BSopt_LP_IICIIRQM = LP_Value_out;
        fprintf('\n   %s loaded', 'LP_Value')
        
        load Q_out.txt;
        Q = Q_out;
        fprintf('\n   %s loaded', 'Q')
        
        load BorderDemandConstraintSlacks_out.txt;
        Border_Slacks = BorderDemandConstraintSlacks_out;
        fprintf('\n   %s loaded', 'Border_Slacks')
        
        load BorderDemandConstraintDuals_out.txt;
        Border_Duals = BorderDemandConstraintDuals_out;
        fprintf('\n   %s loaded', 'Border_Duals')
        
        load QMonSlacks_out.txt;
        QMon_Slacks = QMonSlacks_out;
        fprintf('\n   %s loaded', 'QMon_Slacks')
        
        load QMonDuals_out.txt;
        QMon_Duals = QMonDuals_out;
        fprintf('\n   %s loaded', 'QMon_Duals')
        
        load QNonNegTSlacks_out.txt;
        QTNN_Slack = QNonNegTSlacks_out;
        fprintf('\n   %s loaded', 'QTNN_Slack')
        
        load QNonNegTDuals_out.txt;
        QTNN_Dual = QNonNegTDuals_out;
        fprintf('\n   %s loaded', 'QTNN_Dual')
        
        fprintf('\n   ... done.')
    end
end

if 1  % save output
    save([subFolderName '.mat']);
    fprintf(['\n\n   Workspace saved in subfolder: ' subFolderName ])
end

if 1 % final report
    fprintf('\n\n^^^ %s is done ^^^^^^ ', thisFileName)
    fprintf('\n------------------------------------\n')
end

cd(thisScriptFolder)
if 1 % get file name, say hello
    [~, thisFileName, ~] = fileparts(mfilename('fullpath'));
    thisLpName = strrep(thisFileName, 'fn_', '');
    
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
    fprintf('\n   We now are inside %s', subFolderName)
end

if 1 % solve the LP
    if 1 % write AMPL's .MOD file
        modFileName = [thisLpName '.mod'];
        fid = fopen(modFileName, 'wt');
        if 1 % parameters
            fprintf(fid,'# --- Parameters ----\n');
            fprintf(fid,'param T; # num of Cost values \n');
            fprintf(fid,'param S; # num of Suppliers \n');
            fprintf(fid,'param D; # to rescale Q \n');
            fprintf(fid,'param fmarg {1..T};\n');
            fprintf(fid,'param Fmarg {1..T};\n');
            fprintf(fid,'param c {1..T};\n');
            fprintf(fid,'param Weight {1..T};\n');
            fprintf(fid,'\n');
        end
        if 1 % variables
            fprintf(fid,'# --- Decision variables ----\n');
            fprintf(fid,'var Q {1..T}; \n');
            fprintf(fid,'\n');
        end
        
        if 1 % objective function
            fprintf(fid,'# --- LP ----\n');
            fprintf(fid,'maximize O_BUYER_SURPLUS:\n');
            fprintf(fid,'sum{t in 1..T}\n');
            fprintf(fid,' (Weight[t]*Q[t]);\n\n');
        end
        if 1 % constraints
            if 1 % BorderDemandConstraint
                fprintf(fid,'subject to BorderDemandConstraint {t in 1..T}:\n');
                fprintf(fid,'sum{k in 1..t} (Q[k]*fmarg[k]) <= D*(1-(1-Fmarg[t])^S)/S;\n\n');
            end
            if 1 % Non Negativity
                fprintf(fid,'subject to QNonNegT:\n');
                fprintf(fid,'-Q[T] <= 0;\n\n');
            end
            if 1 % qMon
                fprintf(fid,'subject to QMon {t in 1..T-1}:\n');
                fprintf(fid,'- Q[t] + Q[t+1] <= 0;\n\n');
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
            fprintf(fid,'param D = %d;\n\n', D);
            if 1 % w
                fprintf(fid,'param Weight = \r\n');
                fprintf(fid,'\t');
                for t = 1:T
                    fprintf(fid,'%d\t', t);
                    fprintf(fid,'%.9f\r\n\t', Weight(t));
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
            
            if 1 % f_marginal
                fprintf(fid,'param fmarg = \r\n');
                fprintf(fid,'\t');
                for t = 1:T
                    fprintf(fid,'%d\t', t);
                    fprintf(fid,'%.9f\r\n\t', f(t));
                end
                fprintf(fid,';\r\n\r\n');
            end
            
            if 1 % F_marginal
                fprintf(fid,'param Fmarg = \r\n');
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
        fprintf('\n    Solving the given LP %s with CPLEX ... \n \n', thisLpName)
        %tic
        system([amplPath 'ampl ' runFileName]);
        %toc
        fprintf('   CPLEX is done.')
    end
    if 1 % Load:  LP_Value, Q, M (function output)
        load LP_Value_out.txt;
        SBopt_LP_IICIIRQM = LP_Value_out;
        
        load BorderDemandConstraintSlacks_out.txt;
        BorderDemandConstraintSlacks = BorderDemandConstraintSlacks_out;
        
        load BorderDemandConstraintDuals_out.txt;
        BorderDemandConstraintDuals = BorderDemandConstraintDuals_out;
        
        load QMonSlacks_out.txt;
        QMonSlacks = QMonSlacks_out;
        
        load QMonDuals_out.txt;
        QMonDuals = QMonDuals_out;
        
        load QNonNegTSlacks_out.txt;
        QNonNegTSlacks = QNonNegTSlacks_out;
        
        load QNonNegTDuals_out.txt;
        QNonNegTDuals = QNonNegTDuals_out;
        
        load Q_out.txt;
        Q_SB = Q_out;
        fprintf('\n    Q loaded in Matlab')
    end
end

if 1  % save output
    save([subFolderName '.mat']);
    fprintf(['\n    Output saved in subfolder: ' subFolderName ])
end

if 1 % final report
    fprintf('\n\n^^^ %s is done ^^^^^^ \n', thisFileName)
end

cd(thisScriptFolder)
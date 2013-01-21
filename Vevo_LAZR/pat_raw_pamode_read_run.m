function out = pat_raw_pamode_read_run(job)
% Batch function to import .raw.pamode files into NIfTI files.
%_______________________________________________________________________________
% Copyright (C) 2012 LIOM Laboratoire d'Imagerie Optique et Moleculaire
%                    Ecole Polytechnique de Montreal
%_______________________________________________________________________________

% ------------------------------------------------------------------------------
% REMOVE AFTER FINISHING THE FUNCTION //EGC
% ------------------------------------------------------------------------------
% fprintf('Work in progress...\nEGC\n')
% % out.PATmat = job.PATmat;
% return
% ------------------------------------------------------------------------------
% Add Vevo LAZR related functions
addpath(['.',filesep,'Vevo_LAZR/'])
try
    for scanIdx = 1:length(job.input_dir)
        tic
        % Set save structure and associated directory
        clear PAT
        PAT.input_dir = job.input_dir{scanIdx};
        % Current input dir
        filesdir = job.input_dir{scanIdx};
        % Extract only raw.pamode files
        files = dir(fullfile(filesdir,'*.raw.pamode'));
        dirlen = size(job.input_data_topdir{1},2);
        [pathstr, ~] = fileparts(filesdir);
        % Current output dir
        PAT.output_dir = fullfile(job.output_dir{1},pathstr(dirlen+1:end));
        if ~exist(PAT.output_dir,'dir'),mkdir(PAT.output_dir); end
        % current PAT structure
        PATmat = fullfile(PAT.output_dir,'PAT.mat');
        % Preallocate cell with filenames
        PAT.nifti_files = cell(length(files),2);
        PAT.nifti_files_affine_matrix = cell(length(files),2);
        for fileIdx = 1:length(files)
            [nifti_filename affine_mat_filename PAT.PAparam] = pat_raw2nifti(...
                fullfile(filesdir,files(fileIdx).name), PAT.output_dir);
            PAT.nifti_files{fileIdx,1} = nifti_filename{1};
            PAT.nifti_files{fileIdx,2} = nifti_filename{2};
            PAT.nifti_files_affine_matrix{fileIdx,1} = affine_mat_filename{1};
            PAT.nifti_files_affine_matrix{fileIdx,2} = affine_mat_filename{2};
        end % files loop
        % raw.pamode extraction done!
        PAT.jobsdone.extract_rawPAmode = true;
        save(PATmat,'PAT');
        out.PATmat{scanIdx} = PATmat;
        disp(['Elapsed time: ' datestr(datenum(0,0,0,0,0,toc),'HH:MM:SS')]);
        fprintf('Subject %d of %d complete\n', scanIdx, length(job.input_dir));
    end % scans loop
catch exception
    disp(exception.identifier)
    disp(exception.stack(1))
    out.PATmat{scanIdx} = PATmat;
end
end

% EOF
function out = pat_raw_bmode_read_run(job)
% Batch function to import .raw.bmode files into NIfTI files.
%_______________________________________________________________________________
% Copyright (C) 2012 LIOM Laboratoire d'Imagerie Optique et Moleculaire
%                    Ecole Polytechnique de Montreal
%_______________________________________________________________________________

% ------------------------------------------------------------------------------
% REMOVE AFTER FINISHING THE FUNCTION //EGC
% ------------------------------------------------------------------------------
% fprintf('Work in progress...\nEGC\n')
% out.PATmat = job.PATmat;
% return
% ------------------------------------------------------------------------------

% Add Vevo LAZR related functions
addpath(['.',filesep,'Vevo_LAZR/'])
try
    for scanIdx = 1:length(job.PATmat)
        % Load PAT.mat information
        [PAT PATmat dir_patmat] = pat_get_PATmat(job,scanIdx);
        if ~isfield(PAT, 'jobsdone')
            PAT.jobsdone = struct([]);
        end
        if ~isfield(PAT.jobsdone,'extract_rawBmode') || job.force_redo
            tic
            % Extract only raw.bmode files
            files = dir(fullfile(PAT.input_dir,'*.raw.bmode'));
            if isempty(files)
                % Try 3D raw files
                files = dir(fullfile(PAT.input_dir,'*.raw.3d.bmode'));
            end
            % Preallocate cell with filenames
            if ~isfield(PAT, 'nifti_files')
                PAT.nifti_files = cell(length(files),3);
                PAT.nifti_files = cell(length(files),3);
            end
            for fileIdx = 1:length(files)
                [bmode_nifti_filename affine_mat_filename PAT.bModeParam] = pat_raw2nifti_bmode(...
                    fullfile(PAT.input_dir,files(fileIdx).name), PAT.output_dir);
                if job.extractBMP
                    % Directory with .BMP images
                    bmp_dir = fullfile(dir_patmat,'Bmode_images');
                    if ~exist(bmp_dir,'dir'),mkdir(bmp_dir); end
                    fileNameTXT = pat_raw2bmp_bmode(fullfile(PAT.input_dir,files(fileIdx).name), dir_patmat, bmp_dir);
                    PAT.bModeParam.bmode_bmp_dir{fileIdx,1} = bmp_dir;
                    PAT.bModeParam.bmode_frameData_fname{fileIdx,1}= fileNameTXT;
                end
                % B-mode is the 3rd color
                PAT.nifti_files{fileIdx,3} = bmode_nifti_filename{1};
                PAT.nifti_files_affine_matrix{fileIdx,3} = affine_mat_filename{1};
            end % files loop
            % Creates anatomical template
            PAT = pat_create_anatomical_file(PAT);
            % raw.bmode extraction done!
            PAT.jobsdone.extract_rawBmode = true;
            save(PATmat,'PAT');
        end
        out.PATmat{scanIdx} = PATmat;
        disp(['Elapsed time: ' datestr(datenum(0,0,0,0,0,toc),'HH:MM:SS')]);
        fprintf('Subject %d of %d complete\n', scanIdx, length(job.PATmat));
    end % scans loop
catch exception
    disp(exception.identifier)
    disp(exception.stack(1))
    out.PATmat{scanIdx} = PATmat;
end % End try
end % End function

% EOF

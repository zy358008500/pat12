function [rawData,  param] = pat_VsiOpenRawPa_singleWL_multi(fileName, varargin)
% Modified from VsiOpenRawPa.m. This version opens the file once, reads all
% available frames and closes it.
% SYNTAX
% [rawDataSO2, rawDataHbT,  param] = pat_VsiOpenRawPa_multi(fileName, [framesVector])
% INPUTS
% fileName          Full file name with extension of raw.pamode file
% [framesVector]    Vector with frames to extract, if empty, extracts the whole
%                   file
% OUTPUTS
% rawData           4-D matrix with single wavelength raw data, with the following dimensions:
%                   [nSamples(depth) nLines(width) 1 nFrames]
% param             Structure with relevant info in the extracted images
%_______________________________________________________________________________
% Copyright VisualSonics 1999-2010
% A. Needles
% Revision: 1.0 Dec 3 2010
%_______________________________________________________________________________

% only want 1 optional input at most
numVarArgs = length(varargin);
if numVarArgs > 2
    error('pat12:pat_VsiOpenRawPa_multi:TooManyInputs', ...
        'requires at most 2 optional input: framesVector');
end
% set defaults for optional inputs ()
optArgs = {Inf};
% skip any new inputs if they are empty
newVals = cellfun(@(x) ~isempty(x), varargin);
% now put these defaults into the optArgs cell array, and overwrite the ones
% specified in varargin.
optArgs(newVals) = varargin(newVals);

% Place optional args in memorable variable names
framesVector = optArgs{:};

% Set up file names
[pathString fnameBase ModeName] = fileparts(fileName);
fnameBase = fullfile(pathString, fnameBase);
fnameXml = [fnameBase '.xml'];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse the XML parameter file - DO NOT CHANGE
param           = VsiParseXml(fnameXml, ModeName);
PaNumSamples    = param.PaNumSamples;
PaNumLines      = param.PaNumLines;
PaDepthOffset   = param.PaDepthOffset;  % mm
PaDepth         = param.PaDepth;        % mm
PaWidth         = param.PaWidth;        % mm
param.pixDepth  = (PaDepth-PaDepthOffset)/(PaNumSamples-1);
param.DepthAxis = PaDepthOffset:param.pixDepth:PaDepth;
param.pixWidth  = PaWidth/(PaNumLines-1);
param.WidthAxis = 0:param.pixWidth:PaWidth;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is to strip the header data in the files - DO NOT CHANGE
size            = 2;    % 2 bytes
file_header     = 40;   % 40bytes
line_header     = 0;    % 0 bytes
frame_header    = 56;   % 56 bytes  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Open file
fid = fopen(fileName, 'r');

%% Get total number of frames
fileInfo = dir(fileName);
fileSize = fileInfo.bytes;
% nFrames represents the total of frames SO2 & HbT
nFrames = (fileSize - file_header) / (PaNumLines*(size*PaNumSamples + line_header) + frame_header/2);
if isinf(framesVector)
    framesVector = 1:nFrames;
end
% Initialize data
rawData = zeros(PaNumSamples, PaNumLines, 1, numel(framesVector));

%% Frames loop
fprintf('Reading %d frames from file %s...\n',numel(framesVector), fileName);
% Initialize progress bar
spm_progress_bar('Init', nFrames, sprintf('Read %d frames from raw PA-mode (single wavelength)\n',numel(framesVector)), 'Frames');
pat_text_waitbar(0, sprintf('Read %d frames from raw PA-mode file %s\n',numel(framesVector)), fileName);
for iFrames = framesVector,
    % Update header for each frame
    header = file_header + frame_header*iFrames + (size*PaNumSamples*PaNumLines + PaNumLines*line_header)*(iFrames-1);
    % A-lines loop
    for iLines = 1:PaNumLines,
        fseek(fid, header + (size*PaNumSamples + line_header)*(iLines-1),-1);
        fseek(fid, line_header, 'cof');
        [rawData(:,iLines,1,iFrames), ~] = fread(fid, PaNumSamples, 'ushort');
    end
%     rawDataSO2 = Rawdata(:,:,1,1:2:end);
    % Update progress bar
    spm_progress_bar('Set', iFrames);
    pat_text_waitbar(iFrames/numel(framesVector), sprintf('Processing frame %d from %d', iFrames, numel(framesVector)));
end
% Clear progress bar
spm_progress_bar('Clear');
pat_text_waitbar('Clear');

%% Close file
fclose(fid);
fprintf('%d frames extracted!\n',numel(framesVector));

% EOF

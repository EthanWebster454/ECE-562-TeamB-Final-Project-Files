% Author: Ethan Webster
% File: knnfilt_run.m
% Purpose: This script runs the KNN source separation algorithm on an
%          audio file of choice using file dialog. Simply press "Run" in
%          MATLAB, then file dialog will open. Choose a music file.
%          NOTE: Processing might take a significant amount of time.
%          Output music files will be saved to relative path:
%          "../estimated results/[musicFileName].flac"
%          Implements method described in:
%          FitzGerald, Derry. "Vocal separation using nearest neighbours 
%          and median filtering." (2012): 98-98.

clearvars
addpath(genpath('dependencies'));
addpath('helper_functions');

% obtain music file from prompt
[file,path] = uigetfile("Source_Tracks\*.flac");
fileNameFull = fullfile(path,file);
[~,name,~] = fileparts(fileNameFull);
[splitTrack,Fs]=audioread(fileNameFull);

audioFileInst = splitTrack(:,1);
audioFileVoc =  splitTrack(:,2);

wavlength=length(audioFileInst);

% mix the two tracks to create mixed record for testing
mixedAudioTrack=(audioFileInst+audioFileVoc)/2;

% specify parameters for separation function
inParams.lambda = .00001;
inParams.nFFT= 4096;
inParams.fs=Fs;
inParams.p = 800;
inParams.windowsize=4096;
inParams.outfilename="KNN_Result_Tracks\"+name;

% call KNN separation function with provided parameters
outParams=knnfilt(inParams,mixedAudioTrack,audioFileInst,audioFileVoc);

% calculate ground truth to compare metrics
[s_target,e_interf,e_noise] = bss_decomp_gain( mixedAudioTrack', 1, audioFileVoc');
[sdrGT,sirGT,sarGT] = bss_crit( s_target,e_interf,e_noise);

NSDR=outParams.SDR-sdrGT;   % normalized SDR                            

% display results
fprintf('SDR:%f\nSIR:%f\nSAR:%f\nNSDR:%f\n',outParams.SDR,outParams.SIR,outParams.SAR,NSDR);

% f=figure;
% b = bar(categorical({'SDR','SIR','SAR'}),[Parms.SDR,Parms.SIR,Parms.SAR], 0.4, 'LineWidth', 1);
% ylabel('dB')
% b.FaceColor = 'flat';
% b.CData(1,:) = [1,0,0];
% b.CData(2,:) = [0,1,0];
% b.CData(3,:) = [0,0,1];
% f.Position=[413.0000  184.2000  717.6000  492.8000];
% set(gca,  'FontName', 'Times New Roman', 'FontSize', 14)
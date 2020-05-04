% Author: Ethan Webster
% File: rpca_ss_run.m
% Purpose: This script runs the RPCA source separation algorithm on an
%          audio file of choice using file dialog. Simply press "Run" in
%          MATLAB, then file dialog will open. Choose a music file.
%          NOTE: Processing might take a significant amount of time.
% Implements the RPCA blind source separation method described in
% P. Huang, S. D. Chen, P. Smaragdis and M. Hasegawa-Johnson, 
% "Singing-voice separation from monaural recordings using robust 
% principal component analysis," 2012 IEEE International Conference 
% on Acoustics, Speech and Signal Processing (ICASSP), Kyoto, 2012


% initialize/add dependency file paths to PATH
clearvars
addpath(genpath('dependencies'));
addpath('helper_functions');

% open file dialog to select split track music file
[file,path] = uigetfile("Source_Tracks\*.flac");
fileNameFull = fullfile(path,file);
[~,name,~] = fileparts(fileNameFull);
[splitTrack,Fs]=audioread(fileNameFull);

audioOnlyTrack=splitTrack(:,1);
vocalOnlyTrack=splitTrack(:,2);

wavlength=length(audioOnlyTrack);

mixedAudioTrack=(audioOnlyTrack+vocalOnlyTrack)/2;
        
% calculate ground truth to compare metrics
[s_target,e_interf,e_noise] = bss_decomp_gain( mixedAudioTrack', 1, vocalOnlyTrack');
[sdrGT,sirGT,sarGT] = bss_crit( s_target,e_interf,e_noise);

inputParams.outfilename="RPCA_Result_Tracks\"+name;
inputParams.lambda=1;
inputParams.nFFT=1024;
inputParams.windowSize=1024;
inputParams.fs=Fs;
inputParams.tolerance=0.001;

outParams=rpca_ss(inputParams,mixedAudioTrack,audioOnlyTrack,vocalOnlyTrack);                   

% NSDR = SDR(estimated voice, voice)-SDR(mixture, voice)
NSDR=outParams.SDR-sdrGT;
                          
fprintf('SDR:%f\nSIR:%f\nSAR:%f\nNSDR:%f\n',outParams.SDR,outParams.SIR,outParams.SAR,NSDR);

% f=figure;
% b = bar(categorical({'SDR','SIR','SAR'}),[outParams.SDR,outParams.SIR,outParams.SAR], 0.4, 'LineWidth', 1);
% ylabel('dB')
% b.FaceColor = 'flat';
% b.CData(1,:) = [1,0,0];
% b.CData(2,:) = [0,1,0];
% b.CData(3,:) = [0,0,1];
% f.Position=[413.0000  184.2000  717.6000  492.8000];
% set(gca,  'FontName', 'Times New Roman', 'FontSize', 14)

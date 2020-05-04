[fileV,pathV] = uigetfile("..\split tracks\sources\*.flac","Specify vocals file");
fullV=fullfile(pathV,fileV);

[fileI,pathI] = uigetfile("..\split tracks\sources\*.flac","Specify instrumental file");
fullI=fullfile(pathI,fileI);

[inst,~]=audioread(fullI);
[voc,Fs]=audioread(fullV);

monoI = inst(:,1);%+inst(:,2))/2;
monoV = voc(:,1);%+voc(:,2))/2;

lenI=size(monoI);
lenV=size(monoV);

start=4 *Fs;
stop= 21 *Fs;
%minlen=min(lenI(1),lenV(1));

splitT = [monoI(start:stop),monoV(start:stop)];

%splitT=[inst,voc];

[file,path] = uiputfile("..\split tracks\splits\"+fileI+".flac","Specify output file");
savePath=fullfile(path,file);

audiowrite(savePath,splitT,Fs);

fprintf("The song length is: %0.03d min\n", (stop-start+1)/Fs/60);

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

minlen=min(lenI(1),lenV(1));

splitT = [monoI(1:minlen),monoV(1:minlen)];

%splitT=[inst,voc];

[file,path] = uiputfile("..\split tracks\splits\"+fileI+".flac","Specify output file");
savePath=fullfile(path,file);

audiowrite(savePath,splitT,Fs);

fprintf("The song length is: %0.03d min\n", minlen/Fs/60);

function mapred_reducer_runner(reducer,keyconsumer,valueconsumer,keywriter,valuewriter)
infile=getenv('MATLAB_MAPRED_INFIFO');
outfile=getenv('MATLAB_MAPRED_OUTFIFO');
if isempty(infile),
    fprintf('environment variable MATLAB_MAPRED_INFIFO not set\n');
    exit();
end
if isempty(outfile),
    fprintf('environment variable MATLAB_MAPRED_OUTFIFO not set\n');
    exit();
end
if ~exist(outfile,'file'),
    fprintf('out channel %s does not exist\n',outfile);
    exit();
end
if ~exist(infile,'file'),
    fprintf('in channel %s does not exist\n',infile);
    exit();
end
inid=fopen(infile,'r');
outid=fopen(outfile,'w');
while ~feof(inid),
    inkey=keyconsumer(inid);
    if feof(inid), %% we need to issue an additional read or feof will not fire
        break;
    end
    indatas=cell(0,1);
    while fwrite(inid,1,'uint8')~=0,
        indatas{end+1}=valueconsumer(inid); %#ok<AGROW>
    end
    [outkeys,outdatas]=reducer(inkey,indatas);
    for i=1:numel(outkeys),
        fwrite(outid,1,'uint8');
        keywriter(outid,outkeys(i));
        valuewriter(outid,outdatas(i));
    end
    fwrite(outid,0,'uint8'); %% 
end
fclose(outid);
fclose(inid);
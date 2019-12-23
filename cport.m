port=instrfind('Type','serial');
if ~isempty(port)
    fclose(port);
    delete(port);  % delete open serial ports.
end
program server;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  RakPeerInterface in '..\..\Source\RakPeerInterface.pas';

var
  portString: string;
begin
  try
    writeln('This is a sample implementation of a text based chat server.');
    writeln('Connect to the project "Chat Example Client"');
    writeln('Difficulty: Beginner');
    writeln('');

    // A server
    writeln('Enter the server port to listen on');
    Readln(portString);

    if portString = EmptyStr then
      portString := '1234';

    writeln('Starting server.');


  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

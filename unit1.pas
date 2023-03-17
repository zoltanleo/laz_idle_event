unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLIntf,
  LCLType, syncobjs, LMessages, ExtCtrls;

const
  LM_KILLTHREAD = LM_USER + $101;

type

  { TMyIdleThr }

  TMyIdleThr = class(TThread)
  private
    FCounter: Integer;
    procedure ShowCounter;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  published
  end;

  { TForm1 }

  TForm1 = class(TForm)
    IdleTimer: TIdleTimer;
    Label1: TLabel;
    Timer1: TTimer;
    procedure FormClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IdleTimerStopTimer(Sender: TObject);
    procedure IdleTimerTimer(Sender: TObject);
    procedure LmKillThread(var msg: TLMessage); message LM_KILLTHREAD;
  private
    FIdleThr: TMyIdleThr;
  public

  end;

var
  Form1: TForm1;
  IdleEvent: TEvent;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  if not Assigned(FIdleThr) then FIdleThr:= TMyIdleThr.Create(False);
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  IdleTimer.AutoEnabled:= not IdleTimer.AutoEnabled;
  if IdleTimer.AutoEnabled
    then Self.Caption:= 'True'
    else Self.Caption:= 'False';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  PostMessage(Self.Handle,LM_KILLTHREAD,0,0);
end;

procedure TForm1.IdleTimerStopTimer(Sender: TObject);
begin
  if Assigned(IdleEvent) then IdleEvent.SetEvent;
end;

procedure TForm1.IdleTimerTimer(Sender: TObject);
begin
  if Assigned(IdleEvent) then IdleEvent.ResetEvent;
end;

procedure TForm1.LmKillThread(var msg: TLMessage);
begin
  if Assigned(FIdleThr) then
  begin
    FIdleThr.Terminate;
    if Assigned(IdleEvent) then FreeAndNil(IdleEvent);
    FreeAndNil(FIdleThr);
  end;
end;

{ TMyIdleThr }

procedure TMyIdleThr.ShowCounter;
begin
  Form1.Label1.Caption:= Format('Application is not active %d ms',[FCounter]);
end;

procedure TMyIdleThr.Execute;
begin
  while (FCounter < 1000) and not Terminated do
    if IdleEvent.WaitFor(1) <> wrSignaled then
    begin
      Inc(FCounter);
      Queue(@ShowCounter);
      if FCounter > 999 then FCounter:= 0;
    end;
end;

constructor TMyIdleThr.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate:= False;
  Priority:= tpLowest;
  if not Assigned(IdleEvent)
    then IdleEvent:= TEvent.Create(nil,True,False,'_IdleEvent');
end;

destructor TMyIdleThr.Destroy;
begin
  if Assigned(IdleEvent) then FreeAndNil(IdleEvent);
  inherited Destroy;
end;

end.


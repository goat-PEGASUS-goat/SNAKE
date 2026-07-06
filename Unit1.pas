unit Unit1;

interface

uses
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.Imaging.GIFImg, mGusano,
  Winapi.Windows, Winapi.Messages,
  Winapi.MMSystem, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFrutaInfo = record
    X, Y   : Integer;
    Tipo   : Integer;    // 0=uvita, 1=manzana, 2=banana, 3=quitarcola, 4=quitarvida, 5=calavera
    Activa : Boolean;
  end;

const
  MAX_FRUTAS = 100;

type
  TForm1 = class(TForm)
    Fruta: TImage;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Timer1: TTimer;
    Timer2: TTimer;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    v: Integer;
    p: Word;
    gusi: TGusano;
    RutaImg: string;
    RutaAudio: string;
    TimerSonidoUva: TTimer;
    PnlMenu: TPanel;
    ImgMenuFondo: TImage;
    LblTitulo: TLabel;
    BtnJugar: TButton;
    BtnSalir: TButton;
    FBuffer: TBitmap;
    BgBmp: TBitmap;
    Frutas: array[0..MAX_FRUTAS-1] of TFrutaInfo;
    FrutasCount: Integer;
    FrutasComidas: Integer;
    ProximaCantidadFrutas: Integer;
    ProximoSpawnExtra: Cardinal;
    PicUva, PicManzana, PicBanana: TPicture;
    PicQuitarCola, PicQuitarVida, PicCalavera: TPicture;
    Obstaculos: array of TPosicion;
    IntervaloNormal: Cardinal;
    OscuridadHasta: Cardinal;
    VelocidadHasta: Cardinal;
    TamanoVisual: Integer;
    PnlGO: TPanel;
    LblGO: TLabel;
    LblPuntaje: TLabel;
    BtnRei: TButton;
    BtnMenu   : TButton;
    Pausado: Boolean;
    PausaInicio: Cardinal;
    PnlPausa: TPanel;
    LblPausaTitulo: TLabel;
    LblPausaHint: TLabel;
    BtnReanudar: TButton;
    WallBmp: TBitmap;
    TimerFlash: TTimer;
    HeadDer: TPicture;
    HeadIzq: TPicture;
    HeadArr: TPicture;
    HeadAba: TPicture;
    BodyImg: TPicture;
    procedure SpawnFrutas(Cantidad: Integer);
    procedure SpawnFrutasExtra(Cantidad: Integer);
    function EsObstaculo(X, Y: Integer): Boolean;
    function PicPorTipo(Tipo: Byte): TPicture;
    function HayFrutasActivas: Boolean;
    procedure GenerarObstaculos;
    procedure DibujarObstaculos;
    procedure ReiniciarGusano;
    procedure DibujarFondo;
    procedure MostrarGameOver;
    procedure BtnReiniciarClick(Sender: TObject);
    procedure BtnMenuClick(Sender: TObject);
    procedure CrearPanelGameOver;
    procedure CrearPanelPausa;
    procedure PausarJuego;
    procedure ReanudarJuego;
    procedure BtnReanudarClick(Sender: TObject);
    procedure RedibujarTodo;
    procedure DibujarParedes;
    procedure DibujarGusano(cc: TCanvas);
    procedure DibujarTrianguloCabeza(cc: TCanvas; X, Y: Integer; Dir: Byte);
    procedure CargarTexturaPared(const RutaArchivo: string);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure TimerFlashTimer(Sender: TObject);
    procedure IniciarMusica;
    procedure IniciarMusicaMenu;
    procedure DetenerMusicaMenu;
    procedure ReproducirSonidoUva;
    procedure TimerSonidoUvaTimer(Sender: TObject);
  public
    procedure IniciarJuego;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// forward reference al menú
uses Unit2;

const
  ScoreTipo: array[0..5] of Word = (100, 300, 200, 0, 0, 0);

procedure TForm1.CrearPanelGameOver;
begin
  PnlGO := TPanel.Create(Self);
  PnlGO.Parent := Self;
  PnlGO.Width := 320;
  PnlGO.Height := 220;
  PnlGO.Left := (ClientWidth - PnlGO.Width) div 2;
  PnlGO.Top := (ClientHeight - PnlGO.Height) div 2;
  PnlGO.Color := $00111111;
  PnlGO.BevelOuter := bvNone;
  PnlGO.Caption := '';
  PnlGO.Visible := False;

  LblGO := TLabel.Create(Self);
  LblGO.Parent := PnlGO;
  LblGO.Caption := 'GAME OVER';
  LblGO.Font.Name := 'Impact';
  LblGO.Font.Size := 32;
  LblGO.Font.Color := clRed;
  LblGO.AutoSize := True;
  LblGO.Top := 28;
  LblGO.Left := (PnlGO.Width - 200) div 2;
  LblGO.Transparent := True;

  LblPuntaje := TLabel.Create(Self);
  LblPuntaje.Parent := PnlGO;
  LblPuntaje.Caption := 'Puntaje: 0';
  LblPuntaje.Font.Name := 'Segoe UI';
  LblPuntaje.Font.Size := 14;
  LblPuntaje.Font.Color := clWhite;
  LblPuntaje.AutoSize := True;
  LblPuntaje.Top := 100;
  LblPuntaje.Left := (PnlGO.Width - 100) div 2;
  LblPuntaje.Transparent := True;

  BtnRei := TButton.Create(Self);
  BtnRei.Parent := PnlGO;
  BtnRei.Caption := 'REINICIAR';
  BtnRei.Width := 180;
  BtnRei.Height := 48;
  BtnRei.Left := (PnlGO.Width - 180) div 2;
  BtnRei.Top := 148;
  BtnRei.Font.Name := 'Audex';
  BtnRei.Font.Size := 16;
  BtnRei.OnClick := BtnReiniciarClick;
end;

procedure TForm1.CrearPanelPausa;
begin
  PnlPausa := TPanel.Create(Self);
  PnlPausa.Parent := Self;
  PnlPausa.Width := 300;
  PnlPausa.Height := 190;
  PnlPausa.Left := (ClientWidth - PnlPausa.Width) div 2;
  PnlPausa.Top := (ClientHeight - PnlPausa.Height) div 2;
  PnlPausa.Color := $00111111;
  PnlPausa.BevelOuter := bvNone;
  PnlPausa.Caption := '';
  PnlPausa.Visible := False;

  LblPausaTitulo := TLabel.Create(Self);
  LblPausaTitulo.Parent := PnlPausa;
  LblPausaTitulo.Caption := 'PAUSA';
  LblPausaTitulo.Font.Name := 'Impact';
  LblPausaTitulo.Font.Size := 26;
  LblPausaTitulo.Font.Color := clWhite;
  LblPausaTitulo.AutoSize := True;
  LblPausaTitulo.Top := 22;
  LblPausaTitulo.Left := (PnlPausa.Width - 120) div 2;
  LblPausaTitulo.Transparent := True;

  BtnReanudar := TButton.Create(Self);
  BtnReanudar.Parent := PnlPausa;
  BtnReanudar.Caption := 'REANUDAR';
  BtnReanudar.Width := 170;
  BtnReanudar.Height := 46;
  BtnReanudar.Left := (PnlPausa.Width - 170) div 2;
  BtnReanudar.Top := 78;
  BtnReanudar.Font.Name := 'Audex';
  BtnReanudar.Font.Size := 15;
  BtnReanudar.OnClick := BtnReanudarClick;

  LblPausaHint := TLabel.Create(Self);
  LblPausaHint.Parent := PnlPausa;
  LblPausaHint.Caption := 'presiona espacio para continuar';
  LblPausaHint.Font.Name := 'Segoe UI';
  LblPausaHint.Font.Size := 8;
  LblPausaHint.Font.Color := clGray;
  LblPausaHint.AutoSize := True;
  LblPausaHint.Top := 138;
  LblPausaHint.Left := (PnlPausa.Width - 170) div 2;
  LblPausaHint.Transparent := True;
end;

procedure TForm1.PausarJuego;
begin
  if Pausado or (not Timer1.Enabled) then Exit;
  Pausado := True;
  PausaInicio := GetTickCount;
  Timer1.Enabled := False;
  TimerFlash.Enabled := False;
  PnlPausa.Left := (ClientWidth - PnlPausa.Width) div 2;
  PnlPausa.Top := (ClientHeight - PnlPausa.Height) div 2;
  LblPausaHint.Left := (PnlPausa.Width - LblPausaHint.Width) div 2;
  PnlPausa.BringToFront;
  PnlPausa.Visible := True;
end;

procedure TForm1.ReanudarJuego;
var
  transcurrido: Cardinal;
begin
  if not Pausado then Exit;
  transcurrido := GetTickCount - PausaInicio;
  if OscuridadHasta <> 0 then Inc(OscuridadHasta, transcurrido);
  if VelocidadHasta <> 0 then Inc(VelocidadHasta, transcurrido);
  Inc(ProximoSpawnExtra, transcurrido);
  Pausado := False;
  PnlPausa.Visible := False;
  TimerFlash.Enabled := True;
  Timer1.Enabled := True;
end;

procedure TForm1.BtnReanudarClick(Sender: TObject);
begin
  ReanudarJuego;
end;


// ================================================================
//  IniciarJuego — llamado desde Unit2 al presionar JUGAR
// ================================================================
procedure TForm1.IniciarJuego;
var i: Integer;
begin
  PnlGO.Visible    := False;
  Pausado          := False;
  v := 3; p := 0;
  Label1.Caption   := 'Vidas: 3';
  Label2.Caption   := 'Puntaje: 0';
  FrutasComidas    := 0;
  Panel1.Visible   := True;
  ReiniciarGusano;
  GenerarObstaculos;
  for i := 0 to MAX_FRUTAS - 1 do
    Frutas[i].Activa := False;
  FrutasCount      := 0;
  SpawnFrutas(1);
  OscuridadHasta   := 0;
  VelocidadHasta   := 0;
  Timer1.Interval  := IntervaloNormal;
  Timer1.Enabled   := True;
  Timer2.Enabled   := True;
  IniciarMusica;
  if Assigned(FBuffer) then begin
    FBuffer.Width  := ClientWidth;
    FBuffer.Height := ClientHeight;
  end;
  RedibujarTodo;
end;

// ================================================================
//  BtnMenuClick — vuelve al menu desde el Game Over
// ================================================================
procedure TForm1.BtnMenuClick(Sender: TObject);
begin
  Timer1.Enabled := False;
  Timer2.Enabled := False;
  PnlGO.Visible  := False;
  DetenerMusicaMenu;
  Self.Hide;
  Form2.VolverDelJuego;
end;
procedure TForm1.MostrarGameOver;
begin
  Timer1.Enabled := False;
  LblPuntaje.Caption := 'Puntaje final: ' + IntToStr(p);
  PnlGO.Left := (ClientWidth - PnlGO.Width) div 2;
  PnlGO.Top := (ClientHeight - PnlGO.Height) div 2;
  PnlGO.BringToFront;
  PnlGO.Visible := True;
end;

procedure TForm1.BtnReiniciarClick(Sender: TObject);
var
  i: Integer;
begin
  PnlGO.Visible := False;
  Pausado := False;
  PnlPausa.Visible := False;
  v := 3;
  p := 0;
  Label1.Caption := 'Vidas: ' + IntToStr(v);
  Label2.Caption := 'Puntaje: ' + IntToStr(p);
  FrutasComidas := 0;
  ReiniciarGusano;
  GenerarObstaculos;
  for i := 0 to MAX_FRUTAS - 1 do
    Frutas[i].Activa := False;
  FrutasCount := 0;
  SpawnFrutas(1);
  ProximaCantidadFrutas := 3;
  ProximoSpawnExtra := GetTickCount + 10000;
  RedibujarTodo;
  Timer1.Enabled := True;
end;

function TForm1.PicPorTipo(Tipo: Byte): TPicture;
begin
  case Tipo of
    0: Result := PicUva;
    1: Result := PicManzana;
    2: Result := PicBanana;
    3: Result := PicQuitarCola;
    4: Result := PicQuitarVida;
    5: Result := PicCalavera;
  else
    Result := nil;
  end;
end;

function TForm1.EsObstaculo(X, Y: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(Obstaculos) do
    if (Obstaculos[i].x = X) and (Obstaculos[i].y = Y) then
    begin
      Result := True;
      Exit;
    end;
end;

function TForm1.HayFrutasActivas: Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FrutasCount - 1 do
    if Frutas[i].Activa then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TForm1.GenerarObstaculos;
const
  SEG_ALTO = 4;
  SEP_COLS = 6;
var
  topeY, pisoY, izqX, derX: Integer;
  centroX, centroY: Integer;
  col, fila, i: Integer;
  arriba: Boolean;
begin
  SetLength(Obstaculos, 0);
  topeY := Panel1.Height + MargenPared;
  topeY := ((topeY + 29) div 30) * 30;
  pisoY := FBuffer.Height - MargenPared - 30;
  pisoY := (pisoY div 30) * 30;
  izqX := MargenPared;
  derX := FBuffer.Width - MargenPared - 30;
  centroX := 180;
  centroY := 270;
  arriba := True;
  col := izqX + 180;
  while col < derX - 60 do
  begin
    if arriba then fila := topeY else fila := pisoY - (SEG_ALTO - 1) * 30;
    for i := 0 to SEG_ALTO - 1 do
    begin
      if not ((col >= centroX - 60) and (col <= centroX + 60) and
              (Abs((fila + i * 30) - centroY) <= 60)) then
      begin
        SetLength(Obstaculos, Length(Obstaculos) + 1);
        Obstaculos[High(Obstaculos)].x := col;
        Obstaculos[High(Obstaculos)].y := fila + i * 30;
      end;
    end;
    arriba := not arriba;
    Inc(col, SEP_COLS * 30);
  end;
end;

procedure TForm1.DibujarObstaculos;
var
  i: Integer;
begin
  if not (Assigned(WallBmp) and (WallBmp.Width > 0)) then Exit;
  for i := 0 to High(Obstaculos) do
    FBuffer.Canvas.Draw(Obstaculos[i].x, Obstaculos[i].y, WallBmp);
end;

procedure TForm1.SpawnFrutas(Cantidad: Integer);
var
  cols, rows, i, j, intentos: Integer;
  nx, ny: Integer;
  colisiona: Boolean;
begin
  cols := (ClientWidth - 2 * MargenPared - 30) div 30;
  rows := (ClientHeight - Panel1.Height - 2 * MargenPared - 30) div 30;
  if cols < 1 then cols := 1;
  if rows < 1 then rows := 1;
  if Cantidad > MAX_FRUTAS then Cantidad := MAX_FRUTAS;
  if Cantidad < 1 then Cantidad := 1;
  FrutasCount := Cantidad;

  for i := 0 to Cantidad - 1 do
  begin
    intentos := 0;
    repeat
      nx := MargenPared + Random(cols) * 30;
      ny := Panel1.Height + MargenPared + Random(rows) * 30;
      nx := (nx div 30) * 30;
      ny := (ny div 30) * 30;
      Inc(intentos);
      colisiona := EsObstaculo(nx, ny);
      if not colisiona then
        for j := 0 to i - 1 do
          if (Frutas[j].X = nx) and (Frutas[j].Y = ny) then
          begin
            colisiona := True;
            Break;
          end;
    until (not colisiona) or (intentos > 300);

    Frutas[i].X := nx;
    Frutas[i].Y := ny;
    Frutas[i].Tipo := Random(6);
    if (Frutas[i].Tipo = 3) and (gusi.GetTamaño <= 1) then Frutas[i].Tipo := 2;
    if (Frutas[i].Tipo = 4) and (v <= 1) then Frutas[i].Tipo := 1;
    Frutas[i].Activa := True;
  end;
end;

procedure TForm1.SpawnFrutasExtra(Cantidad: Integer);
var
  cols, rows, creadas, intentos, slot, j: Integer;
  nx, ny: Integer;
  colisiona: Boolean;
begin
  cols := (ClientWidth - 2 * MargenPared - 30) div 30;
  rows := (ClientHeight - Panel1.Height - 2 * MargenPared - 30) div 30;
  if cols < 1 then cols := 1;
  if rows < 1 then rows := 1;
  creadas := 0;
  slot := 0;
  while (creadas < Cantidad) and (slot < MAX_FRUTAS) do
  begin
    while (slot < MAX_FRUTAS) and Frutas[slot].Activa do
      Inc(slot);
    if slot >= MAX_FRUTAS then Break;

    intentos := 0;
    repeat
      nx := MargenPared + Random(cols) * 30;
      ny := Panel1.Height + MargenPared + Random(rows) * 30;
      nx := (nx div 30) * 30;
      ny := (ny div 30) * 30;
      Inc(intentos);
      colisiona := EsObstaculo(nx, ny);
      if not colisiona then
        for j := 0 to MAX_FRUTAS - 1 do
          if Frutas[j].Activa and (Frutas[j].X = nx) and (Frutas[j].Y = ny) then
          begin
            colisiona := True;
            Break;
          end;
    until (not colisiona) or (intentos > 300);

    Frutas[slot].X := nx;
    Frutas[slot].Y := ny;
    Frutas[slot].Tipo := Random(6);
    if (Frutas[slot].Tipo = 3) and (gusi.GetTamaño <= 1) then Frutas[slot].Tipo := 2;
    if (Frutas[slot].Tipo = 4) and (v <= 1) then Frutas[slot].Tipo := 1;
    Frutas[slot].Activa := True;

    if slot >= FrutasCount then
      FrutasCount := slot + 1;

    Inc(creadas);
    Inc(slot);
  end;
end;

procedure TForm1.ReiniciarGusano;
begin
  FreeAndNil(gusi);
  gusi := TGusano.Create;
  OscuridadHasta := 0;
  VelocidadHasta := 0;
  Timer1.Interval := IntervaloNormal;
  TamanoVisual := 30;
end;

procedure TForm1.CargarTexturaPared(const RutaArchivo: string);
var
  TempPic: TPicture;
  SrcBmp: TBitmap;
begin
  if not FileExists(RutaArchivo) then Exit;
  TempPic := TPicture.Create;
  SrcBmp := TBitmap.Create;
  try
    TempPic.LoadFromFile(RutaArchivo);
    SrcBmp.Assign(TempPic.Graphic);
    WallBmp.PixelFormat := pf24bit;
    WallBmp.Width := MargenPared;
    WallBmp.Height := MargenPared;
    SetStretchBltMode(WallBmp.Canvas.Handle, HALFTONE);
    StretchBlt(WallBmp.Canvas.Handle, 0, 0, MargenPared, MargenPared,
      SrcBmp.Canvas.Handle, 0, 0, SrcBmp.Width, SrcBmp.Height, SRCCOPY);
  finally
    SrcBmp.Free;
    TempPic.Free;
  end;
end;

procedure TForm1.IniciarMusica;
begin
  if not FileExists(RutaAudio + 'musica.mp3') then Exit;
  mciSendString('close musica', nil, 0, 0);
  if mciSendString(PChar('open "' + RutaAudio + 'musica.mp3" alias musica'), nil, 0, 0) = 0 then
    mciSendString('play musica repeat', nil, 0, 0);
end;

procedure TForm1.IniciarMusicaMenu;
begin
  if not FileExists(RutaAudio + 'menuMusica.mp3') then Exit;
  mciSendString('close musicaMenu', nil, 0, 0);
  if mciSendString(PChar('open "' + RutaAudio + 'menuMusica.mp3" alias musicaMenu'), nil, 0, 0) = 0 then
    mciSendString('play musicaMenu repeat', nil, 0, 0);
end;

procedure TForm1.DetenerMusicaMenu;
begin
  mciSendString('stop musicaMenu', nil, 0, 0);
  mciSendString('close musicaMenu', nil, 0, 0);
end;

procedure TForm1.ReproducirSonidoUva;
begin
  if not FileExists(RutaAudio + 'uva.mp3') then Exit;
  mciSendString('close sonidoUva', nil, 0, 0);
  if mciSendString(PChar('open "' + RutaAudio + 'uva.mp3" alias sonidoUva'), nil, 0, 0) = 0 then
  begin
    mciSendString('play sonidoUva from 0', nil, 0, 0);
    TimerSonidoUva.Enabled := False;
    TimerSonidoUva.Enabled := True;
  end;
end;

procedure TForm1.TimerSonidoUvaTimer(Sender: TObject);
begin
  TimerSonidoUva.Enabled := False;
  mciSendString('stop sonidoUva', nil, 0, 0);
  mciSendString('close sonidoUva', nil, 0, 0);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Self.WindowState := wsMaximized; // arranca en pantalla completa
  Randomize;
  v := 3;
  p := 0;
  RutaImg := 'C:\Users\AISACK\Desktop\eliminar este proyecto\Imágenes\';
  RutaAudio := 'C:\Users\AISACK\Desktop\eliminar este proyecto\Audio\';
  gusi := TGusano.Create;
  Label1.Caption := 'Vidas: ' + IntToStr(v);
  Label2.Caption := 'Puntaje: ' + IntToStr(p);

  Panel1.Align := alTop;
  Label1.Anchors := [akLeft, akTop];
  Label2.Anchors := [akTop, akRight];

  Fruta.Visible := False;
  FrutasCount := 0;
  FrutasComidas := 0;
  ProximaCantidadFrutas := 3;
  ProximoSpawnExtra := GetTickCount + 10000;
  Timer2.Enabled := False;

  IntervaloNormal := Timer1.Interval;
  OscuridadHasta := 0;
  VelocidadHasta := 0;
  TamanoVisual := 30;

  FBuffer := TBitmap.Create;
  FBuffer.Width := ClientWidth;
  FBuffer.Height := ClientHeight;

  BgBmp := TBitmap.Create;
  if FileExists(RutaImg + 'fondo.png') then
    BgBmp.LoadFromFile(RutaImg + 'fondo.png');

  WallBmp := TBitmap.Create;
  CargarTexturaPared(RutaImg + 'pared.png');

  PicUva := TPicture.Create;
  if FileExists(RutaImg + 'uvita.png') then PicUva.LoadFromFile(RutaImg + 'uvita.png');
  PicManzana := TPicture.Create;
  if FileExists(RutaImg + 'manzanita.png') then PicManzana.LoadFromFile(RutaImg + 'manzanita.png');
  PicBanana := TPicture.Create;
  if FileExists(RutaImg + 'bananita.png') then PicBanana.LoadFromFile(RutaImg + 'bananita.png');
  PicQuitarCola := TPicture.Create;
  if FileExists(RutaImg + 'quitarcola.png') then PicQuitarCola.LoadFromFile(RutaImg + 'quitarcola.png');
  PicQuitarVida := TPicture.Create;
  if FileExists(RutaImg + 'quitarvida.png') then PicQuitarVida.LoadFromFile(RutaImg + 'quitarvida.png');
  PicCalavera := TPicture.Create;
  if FileExists(RutaImg + 'calavera.png') then PicCalavera.LoadFromFile(RutaImg + 'calavera.png');

  HeadDer := TPicture.Create;
  if FileExists(RutaImg + 'cabezaDer.png') then HeadDer.LoadFromFile(RutaImg + 'cabezaDer.png');
  HeadIzq := TPicture.Create;
  if FileExists(RutaImg + 'cabezaIzq.png') then HeadIzq.LoadFromFile(RutaImg + 'cabezaIzq.png');
  HeadArr := TPicture.Create;
  if FileExists(RutaImg + 'cabezaArr.png') then HeadArr.LoadFromFile(RutaImg + 'cabezaArr.png');
  HeadAba := TPicture.Create;
  if FileExists(RutaImg + 'cabezaAba.png') then HeadAba.LoadFromFile(RutaImg + 'cabezaAba.png');

  BodyImg := TPicture.Create;
  if FileExists(RutaImg + 'cuerpo.png') then BodyImg.LoadFromFile(RutaImg + 'cuerpo.png');

  Self.DoubleBuffered := True;
  Self.OnDestroy := FormDestroy;
  Self.OnResize := FormResize;

  TimerFlash := TTimer.Create(Self);
  TimerFlash.Interval := 40;
  TimerFlash.OnTimer := TimerFlashTimer;
  TimerFlash.Enabled := True;

  TimerSonidoUva := TTimer.Create(Self);
  TimerSonidoUva.Interval := 3500;
  TimerSonidoUva.OnTimer := TimerSonidoUvaTimer;
  TimerSonidoUva.Enabled := False;

  IniciarMusicaMenu;
  CrearPanelGameOver;
  CrearPanelPausa;
  GenerarObstaculos;
  SpawnFrutas(1);
  RedibujarTodo;

  Panel1.Visible := False;
  Timer1.Enabled := False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  mciSendString('stop musica', nil, 0, 0);
  mciSendString('close musica', nil, 0, 0);
  mciSendString('stop musicaMenu', nil, 0, 0);
  mciSendString('close musicaMenu', nil, 0, 0);
  mciSendString('stop sonidoUva', nil, 0, 0);
  mciSendString('close sonidoUva', nil, 0, 0);

  FBuffer.Free;
  BgBmp.Free;
  WallBmp.Free;
  HeadDer.Free;
  HeadIzq.Free;
  HeadArr.Free;
  HeadAba.Free;
  BodyImg.Free;
  PicUva.Free;
  PicManzana.Free;
  PicBanana.Free;
  PicQuitarCola.Free;
  PicQuitarVida.Free;
  PicCalavera.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
var
  i: Integer;
  nuevaX, nuevaY: Integer;
  intentos: Integer;
  colisiona: Boolean;
  j: Integer;
begin
  if Assigned(FBuffer) then
  begin
    FBuffer.Width := ClientWidth;
    FBuffer.Height := ClientHeight;
    GenerarObstaculos;

    for i := 0 to FrutasCount - 1 do
    begin
      if not Frutas[i].Activa then Continue;
      if (Frutas[i].X < MargenPared) or (Frutas[i].X > ClientWidth - MargenPared - 30) or
         (Frutas[i].Y < Panel1.Height + MargenPared) or (Frutas[i].Y > ClientHeight - MargenPared - 30) then
      begin
        intentos := 0;
        repeat
          nuevaX := MargenPared + Random((ClientWidth - 2 * MargenPared - 30) div 30) * 30;
          nuevaY := Panel1.Height + MargenPared + Random((ClientHeight - Panel1.Height - 2 * MargenPared - 30) div 30) * 30;
          Inc(intentos);
          colisiona := EsObstaculo(nuevaX, nuevaY);
          if not colisiona then
            for j := 0 to FrutasCount - 1 do
              if (j <> i) and Frutas[j].Activa and (Frutas[j].X = nuevaX) and (Frutas[j].Y = nuevaY) then
              begin
                colisiona := True;
                Break;
              end;
        until (not colisiona) or (intentos > 300);
        if not colisiona then
        begin
          Frutas[i].X := nuevaX;
          Frutas[i].Y := nuevaY;
        end;
      end;
    end;

    RedibujarTodo;
  end;
end;

procedure TForm1.TimerFlashTimer(Sender: TObject);
begin
  if OscuridadHasta <> 0 then
    RedibujarTodo;
end;

procedure TForm1.DibujarParedes;
var
  x, y: Integer;
  TopeY: Integer;
begin
  if not (Assigned(WallBmp) and (WallBmp.Width > 0)) then Exit;
  TopeY := Panel1.Height;

  x := 0;
  while x < FBuffer.Width do
  begin
    FBuffer.Canvas.Draw(x, TopeY, WallBmp);
    Inc(x, WallBmp.Width);
  end;

  y := TopeY;
  while y < FBuffer.Height do
  begin
    FBuffer.Canvas.Draw(0, y, WallBmp);
    FBuffer.Canvas.Draw(FBuffer.Width - MargenPared, y, WallBmp);
    Inc(y, WallBmp.Height);
  end;

  x := 0;
  while x < FBuffer.Width do
  begin
    FBuffer.Canvas.Draw(x, FBuffer.Height - MargenPared, WallBmp);
    Inc(x, WallBmp.Width);
  end;
end;

procedure TForm1.DibujarFondo;
var
  x, y, juegoTop: Integer;
begin
  FBuffer.Canvas.Brush.Color := $00111111;
  FBuffer.Canvas.Pen.Style := psClear;
  FBuffer.Canvas.FillRect(Rect(0, 0, FBuffer.Width, FBuffer.Height));

  juegoTop := Panel1.Height + MargenPared;
  y := juegoTop;
  while y < FBuffer.Height - MargenPared do
  begin
    x := MargenPared;
    while x < FBuffer.Width - MargenPared do
    begin
      if ((x div 30) + (y div 30)) mod 2 = 0 then
        FBuffer.Canvas.Brush.Color := $00002800
      else
        FBuffer.Canvas.Brush.Color := $00003C00;
      FBuffer.Canvas.FillRect(Rect(x, y, x + 30, y + 30));
      Inc(x, 30);
    end;
    Inc(y, 30);
  end;
end;

procedure TForm1.DibujarTrianguloCabeza(cc: TCanvas; X, Y: Integer; Dir: Byte);
var
  pts: array[0..5] of TPoint;
  ojoX, ojoY: Integer;
begin
  cc.Brush.Color := clLime;
  cc.Pen.Color := $00006400;
  cc.Pen.Width := 2;

  case Dir of
    dDer: begin pts[0] := Point(X, Y + 4); pts[1] := Point(X + 20, Y); pts[2] := Point(X + 30, Y + 10); pts[3] := Point(X + 22, Y + 15); pts[4] := Point(X + 30, Y + 20); pts[5] := Point(X, Y + 26); ojoX := X + 12; ojoY := Y + 8; end;
    dIzq: begin pts[0] := Point(X + 30, Y + 4); pts[1] := Point(X + 10, Y); pts[2] := Point(X, Y + 10); pts[3] := Point(X + 8, Y + 15); pts[4] := Point(X, Y + 20); pts[5] := Point(X + 30, Y + 26); ojoX := X + 18; ojoY := Y + 8; end;
    dArr: begin pts[0] := Point(X + 4, Y + 30); pts[1] := Point(X, Y + 10); pts[2] := Point(X + 10, Y); pts[3] := Point(X + 15, Y + 8); pts[4] := Point(X + 20, Y); pts[5] := Point(X + 26, Y + 30); ojoX := X + 8; ojoY := Y + 18; end;
  else begin pts[0] := Point(X + 4, Y); pts[1] := Point(X, Y + 20); pts[2] := Point(X + 10, Y + 30); pts[3] := Point(X + 15, Y + 22); pts[4] := Point(X + 20, Y + 30); pts[5] := Point(X + 26, Y); ojoX := X + 8; ojoY := Y + 12; end;
  end;

  cc.Polygon(pts);
  cc.Brush.Color := clYellow;
  cc.Pen.Color := clBlack;
  cc.Pen.Width := 1;
  cc.Ellipse(ojoX, ojoY, ojoX + 6, ojoY + 6);
end;

procedure TForm1.DibujarGusano(cc: TCanvas);
var
  i: Integer;
  seg: TPosicion;
  cx, cy: Integer;
  headPic: TPicture;
  off: Integer;
begin
  off := (TamanoVisual - 30) div 2;

  for i := 1 to gusi.GetTamaño do
  begin
    seg := gusi.GetSegmento(i);
    if Assigned(BodyImg) and (BodyImg.Width > 0) then
      cc.StretchDraw(Rect(seg.x - off, seg.y - off, seg.x - off + TamanoVisual, seg.y - off + TamanoVisual), BodyImg.Graphic)
    else
    begin
      cc.Brush.Color := clGreen;
      cc.Pen.Color := clGreen;
      cx := seg.x + 15; cy := seg.y + 15;
      cc.Polygon([Point(cx, seg.y - off), Point(seg.x - off + TamanoVisual, cy), Point(cx, seg.y - off + TamanoVisual), Point(seg.x - off, cy)]);
    end;
  end;

  headPic := nil;
  case gusi.GetDireccion of
    dDer: if Assigned(HeadDer) and (HeadDer.Width > 0) then headPic := HeadDer;
    dIzq: if Assigned(HeadIzq) and (HeadIzq.Width > 0) then headPic := HeadIzq;
    dArr: if Assigned(HeadArr) and (HeadArr.Width > 0) then headPic := HeadArr;
    dAba: if Assigned(HeadAba) and (HeadAba.Width > 0) then headPic := HeadAba;
  end;

  if Assigned(headPic) then
    cc.StretchDraw(Rect(gusi.Posicion.x - off, gusi.Posicion.y - off,
                        gusi.Posicion.x - off + TamanoVisual, gusi.Posicion.y - off + TamanoVisual),
                        headPic.Graphic)
  else
    DibujarTrianguloCabeza(cc, gusi.Posicion.x, gusi.Posicion.y, gusi.GetDireccion);
end;

procedure TForm1.RedibujarTodo;
const
  FlashFlipMs = 100;
var
  i: Integer;
  pic: TPicture;
begin
  if Assigned(BgBmp) and (BgBmp.Width > 0) then
    FBuffer.Canvas.StretchDraw(Rect(0, 0, FBuffer.Width, FBuffer.Height), BgBmp)
  else
    DibujarFondo;

  DibujarParedes;
  DibujarObstaculos;

  for i := 0 to FrutasCount - 1 do
    if Frutas[i].Activa then
    begin
      pic := PicPorTipo(Frutas[i].Tipo);
      if Assigned(pic) and (pic.Width > 0) then
        FBuffer.Canvas.StretchDraw(Rect(Frutas[i].X, Frutas[i].Y, Frutas[i].X + 30, Frutas[i].Y + 30), pic.Graphic)
      else if Frutas[i].Tipo = 5 then
      begin
        FBuffer.Canvas.Brush.Color := clBlack;
        FBuffer.Canvas.Pen.Color := clWhite;
        FBuffer.Canvas.Ellipse(Frutas[i].X + 2, Frutas[i].Y + 2, Frutas[i].X + 28, Frutas[i].Y + 28);
      end;
    end;

  DibujarGusano(FBuffer.Canvas);

  if OscuridadHasta <> 0 then
  begin
    if (GetTickCount div FlashFlipMs) mod 2 = 0 then
      FBuffer.Canvas.Brush.Color := clBlack
    else
      FBuffer.Canvas.Brush.Color := clWhite;
    FBuffer.Canvas.FillRect(Rect(0, Panel1.Height, FBuffer.Width, FBuffer.Height));
  end;

  Canvas.Draw(0, 0, FBuffer);
end;

procedure TForm1.FormPaint(Sender: TObject);
begin
  if Assigned(FBuffer) then
    Canvas.Draw(0, 0, FBuffer);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  dir: Byte;
begin
  if Key = VK_ESCAPE then
  begin
    Close;
    Key := 0;
    Exit;
  end;

  if Key = VK_SPACE then
  begin
    if Pausado then
      ReanudarJuego
    else
      PausarJuego;
    Key := 0;
    Exit;
  end;

  dir := gusi.GetDireccion;
  case Key of
    37: if dir <> dDer then gusi.SetDireccion(dIzq);
    38: if dir <> dAba then gusi.SetDireccion(dArr);
    39: if dir <> dIzq then gusi.SetDireccion(dDer);
    40: if dir <> dArr then gusi.SetDireccion(dAba);
    65: if dir <> dDer then gusi.SetDireccion(dIzq);
    87: if dir <> dAba then gusi.SetDireccion(dArr);
    68: if dir <> dIzq then gusi.SetDireccion(dDer);
    83: if dir <> dArr then gusi.SetDireccion(dAba);
  end;
  Key := 0;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
const
  TAMANO_MAX = 66;
var
  i, mult: Integer;
begin
  if (VelocidadHasta <> 0) and (GetTickCount >= VelocidadHasta) then
    VelocidadHasta := 0;
  if (OscuridadHasta <> 0) and (GetTickCount >= OscuridadHasta) then
    OscuridadHasta := 0;

  mult := 1;
  if VelocidadHasta <> 0 then mult := mult * 2;
  if OscuridadHasta <> 0 then mult := mult * 2;
  if mult < 1 then mult := 1;
  if mult > 8 then mult := 8;
  Timer1.Interval := IntervaloNormal div mult;

  gusi.Mover(FBuffer.Canvas, Panel1.Height + MargenPared, Obstaculos);

  if gusi.GetChoco then
  begin
    Dec(v);
    Label1.Caption := 'Vidas: ' + IntToStr(v);
    if v = 0 then
    begin
      MostrarGameOver;
      Exit;
    end;
    ReiniciarGusano;
    RedibujarTodo;
    Exit;
  end;

  for i := 0 to FrutasCount - 1 do
  begin
    if Frutas[i].Activa and
       (gusi.Posicion.x = Frutas[i].X) and
       (gusi.Posicion.y = Frutas[i].Y) then
    begin
      Frutas[i].Activa := False;
      p := p + ScoreTipo[Frutas[i].Tipo];
      Label2.Caption := 'Puntaje: ' + IntToStr(p);

      if Frutas[i].Tipo in [1, 2] then
        gusi.Crecer;

      Inc(FrutasComidas);

      case Frutas[i].Tipo of
        0:
          begin
            OscuridadHasta := GetTickCount + 3500;
            ReproducirSonidoUva;
          end;
        1: VelocidadHasta := GetTickCount + 5000;
        2: if TamanoVisual < TAMANO_MAX then Inc(TamanoVisual, 4);
        3: gusi.Encoger;
        4:
          begin
            Dec(v);
            Label1.Caption := 'Vidas: ' + IntToStr(v);
            if v <= 0 then
            begin
              v := 0;
              RedibujarTodo;
              MostrarGameOver;
              Exit;
            end;
          end;
        5:
          begin
            v := 0;
            Label1.Caption := 'Vidas: ' + IntToStr(v);
            RedibujarTodo;
            MostrarGameOver;
            Exit;
          end;
      end;

      Break;
    end;
  end;

  if GetTickCount >= ProximoSpawnExtra then
  begin
    SpawnFrutasExtra(ProximaCantidadFrutas);
    if ProximaCantidadFrutas = 3 then
      ProximaCantidadFrutas := 5
    else
      ProximaCantidadFrutas := 3;
    ProximoSpawnExtra := GetTickCount + 10000;
  end;

  RedibujarTodo;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  Timer2.Enabled := False;
  SpawnFrutas(ProximaCantidadFrutas);
  RedibujarTodo;
end;

end.

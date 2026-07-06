unit Unit2;

interface

uses
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.Imaging.GIFImg,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TForm2 = class(TForm)
    TimerBlink: TTimer; // sin uso por ahora (ver nota al final del archivo)
    Image1: TImage;     // fondo: lo que le pongas en Picture se ve tal cual
    Button1: TButton;   // JUGAR
    Button2: TButton;   // SALIR
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerBlinkTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    // ---- Pantalla de carga ----
    PnlCarga  : TPanel;
    ImgDraw   : TImage;
    FBufCarga : TBitmap;
    CargaPaso : Integer;
    CargaMax  : Integer;
    TimerCarga: TTimer;
    RutaImg      : string;
    CargaFondoPic: TPicture; // fondo de la pantalla de carga (gif/png/jpg/jpeg/bmp)

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure CrearPantallaCarga;
    procedure CargarFondoCarga;
    procedure DibujarCargando;
    procedure TimerCargaTimer(Sender: TObject);
    procedure PosicionarBotones;
  public
    procedure VolverDelJuego; // llamado por Unit1 al volver al menú
  end;

var
  Form2: TForm2;

implementation

uses Unit1;

{$R *.dfm}

// ================================================================
//  FORMCREATE
// ================================================================
procedure TForm2.FormCreate(Sender: TObject);
begin
  Self.WindowState := wsMaximized; // arranca en pantalla completa

  RutaImg := 'C:\Users\AISACK\Desktop\eliminar este proyecto\Imágenes\';
  CargarFondoCarga;

  CargaMax  := 40;
  CargaPaso := 0;

  // Image1 es el fondo: lo que le pongas en Picture desde el Object
  // Inspector se muestra tal cual, sin tocar código. Solo nos aseguramos
  // de que cubra todo el formulario y quede detrás de los botones.
  Image1.Align   := alClient;
  Image1.Stretch := True;
  Image1.Visible := True;
  Image1.SendToBack;

  // Conecta los botones que ya pusiste en el diseñador. El texto, tamaño,
  // fuente y posición se controlan 100% desde el Object Inspector.
  Button1.OnClick := Button1Click;
  Button2.OnClick := Button2Click;
  PosicionarBotones; // los centra según el tamaño real (ya maximizado)

  CrearPantallaCarga; // oculta hasta que se presione Button1 (JUGAR)
end;

// Centra Button1 (JUGAR) y Button2 (SALIR) según el tamaño actual de la
// ventana. Se llama al crear el form y de nuevo en cada resize, así no
// quedan pegados a la izquierda/derecha si maximizás o cambiás de monitor.
procedure TForm2.PosicionarBotones;
begin
  Button1.Left := (ClientWidth - Button1.Width) div 2;
  Button1.Top  := (ClientHeight * 2) div 3;
  Button2.Left := (ClientWidth - Button2.Width) div 2;
  Button2.Top  := Button1.Top + Button1.Height + 20;
end;

procedure TForm2.FormResize(Sender: TObject);
begin
  PosicionarBotones;
end;

// ================================================================
//  CARGAR FONDO DE LA PANTALLA DE CARGA
//  Busca, en orden, hasta 5 archivos posibles (el primero que
//  encuentra es el que usa): carga.gif, carga.png, carga.jpg,
//  carga.jpeg, carga.bmp. Si es GIF, se anima solo.
//  Si no encuentra ninguno, la pantalla de carga sigue funcionando
//  igual que antes (fondo negro liso).
// ================================================================
procedure TForm2.CargarFondoCarga;
var
  candidatos: array[0..4] of string;
  i: Integer;
begin
  candidatos[0] := RutaImg + 'carga.gif';
  candidatos[1] := RutaImg + 'carga.png';
  candidatos[2] := RutaImg + 'carga.jpg';
  candidatos[3] := RutaImg + 'carga.jpeg';
  candidatos[4] := RutaImg + 'carga.bmp';

  CargaFondoPic := TPicture.Create;
  for i := 0 to High(candidatos) do
    if FileExists(candidatos[i]) then
    begin
      CargaFondoPic.LoadFromFile(candidatos[i]);
      if CargaFondoPic.Graphic is TGIFImage then
        TGIFImage(CargaFondoPic.Graphic).Animate := True;
      Break;
    end;
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FBufCarga);
  FreeAndNil(CargaFondoPic);
end;

// ================================================================
//  CLICK JUGAR (Button1) → oculta el menú y empieza la carga
// ================================================================
procedure TForm2.Button1Click(Sender: TObject);
begin
  Button1.Visible  := False;
  Button2.Visible  := False;
  PnlCarga.Visible := True;
  PnlCarga.BringToFront;
  CargaPaso        := 0;
  TimerCarga.Enabled := True;
end;

// ================================================================
//  CLICK SALIR (Button2)
// ================================================================
procedure TForm2.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

// ================================================================
//  CREA EL PANEL DE CARGA (oculto al inicio)
// ================================================================
procedure TForm2.CrearPantallaCarga;
begin
  PnlCarga               := TPanel.Create(Self);
  PnlCarga.Parent        := Self;
  PnlCarga.Align         := alClient;
  PnlCarga.Color         := clBlack;
  PnlCarga.BevelOuter    := bvNone;
  PnlCarga.Caption       := '';
  PnlCarga.Visible       := False;

  ImgDraw               := TImage.Create(Self);
  ImgDraw.Parent        := PnlCarga;
  ImgDraw.Align         := alClient;
  ImgDraw.Stretch       := False;

  FBufCarga             := TBitmap.Create;
  FBufCarga.PixelFormat := pf32bit;
  FBufCarga.Width       := ClientWidth;
  FBufCarga.Height      := ClientHeight;

  TimerCarga            := TTimer.Create(Self);
  TimerCarga.Interval   := 60;
  TimerCarga.Enabled    := False;
  TimerCarga.OnTimer    := TimerCargaTimer;
end;

// ================================================================
//  DIBUJA LA PANTALLA DE CARGA al estilo PlayStation
// ================================================================
procedure TForm2.DibujarCargando;
var
  cc         : TCanvas;
  i, bx, by  : Integer;
  pct        : Double;
  s          : string;
  totalBarras: Integer;
  barAncho   : Integer;
  barAlto    : Integer;
  barSep     : Integer;
  startX     : Integer;
  barY       : Integer;
  alpha      : Byte;
  clr        : TColor;
begin
  if (FBufCarga.Width <> ClientWidth) or (FBufCarga.Height <> ClientHeight) then
  begin
    FBufCarga.Width  := ClientWidth;
    FBufCarga.Height := ClientHeight;
  end;
  cc := FBufCarga.Canvas;
  if Assigned(CargaFondoPic) and (CargaFondoPic.Width > 0) then
    cc.StretchDraw(Rect(0, 0, FBufCarga.Width, FBufCarga.Height), CargaFondoPic.Graphic)
  else
  begin
    cc.Brush.Color := clBlack;
    cc.FillRect(Rect(0, 0, FBufCarga.Width, FBufCarga.Height));
  end;

  pct        := CargaPaso / CargaMax;
  totalBarras:= 25;
  barAncho   := 16;
  barAlto    := 6;
  barSep     := 8;
  startX     := (PnlCarga.Width - totalBarras * (barAncho + barSep)) div 2;
  barY       := PnlCarga.Height * 3 div 5;

  cc.Brush.Style := bsClear;
  cc.Font.Name   := 'Impact';
  cc.Font.Size   := 60;
  cc.Font.Color  := clLime;
  s := 'GUSANITO';
  cc.TextOut((PnlCarga.Width - cc.TextWidth(s)) div 2,
             PnlCarga.Height div 5, s);

  cc.Font.Size  := 16;
  cc.Font.Color := clRed;
  s := '~ COBRA RAGE EDITION ~';
  cc.TextOut((PnlCarga.Width - cc.TextWidth(s)) div 2,
             PnlCarga.Height div 5 + 75, s);

  cc.Pen.Style := psClear;
  for i := 0 to totalBarras - 1 do
  begin
    bx := startX + i * (barAncho + barSep);
    by := barY;

    if i < Round(pct * totalBarras) then
    begin
      alpha := Round(80 + 175 * (i / (totalBarras - 1)));
      clr   := RGB(alpha div 3, alpha, alpha div 3);
      cc.Brush.Color := clr;
    end else
      cc.Brush.Color := $00111111;

    cc.FillRect(Rect(bx, by, bx + barAncho, by + barAlto * 2));
  end;

  cc.Font.Size  := 9;
  cc.Font.Color := clDkGray;
  s := 'CARGANDO...';
  cc.TextOut((PnlCarga.Width - cc.TextWidth(s)) div 2,
             barY + barAlto * 2 + 12, s);

  if (CargaPaso mod 8) < 4 then
  begin
    cc.Pen.Style := psSolid;
    cc.Pen.Color := $00003000;
    cc.MoveTo(startX - 10, barY - 4);
    cc.LineTo(startX + totalBarras * (barAncho + barSep) + 10, barY - 4);
  end;

  ImgDraw.Picture.Assign(FBufCarga);
end;

// ================================================================
//  TIMER CARGA — al terminar, lanza el juego directamente
// ================================================================
procedure TForm2.TimerCargaTimer(Sender: TObject);
begin
  Inc(CargaPaso);
  DibujarCargando;

  if CargaPaso >= CargaMax then
  begin
    TimerCarga.Enabled := False;
    // Flash blanco de transición
    FBufCarga.Canvas.Brush.Color := clWhite;
    FBufCarga.Canvas.FillRect(Rect(0, 0, FBufCarga.Width, FBufCarga.Height));
    ImgDraw.Picture.Assign(FBufCarga);
    Application.ProcessMessages;
    Sleep(80);

    Form1.IniciarJuego;
    Form1.Show;
    Self.Hide;
  end;
end;

// ================================================================
//  TimerBlink — ya no se usa (un TButton estándar no soporta bien
//  el parpadeo de color sin volverlo owner-draw, y eso te quitaría
//  control desde el Object Inspector). Lo dejo vacío por si el .dfm
//  todavía referencia este evento; si no lo necesitas, puedes borrar
//  el componente TimerBlink del formulario sin problema.
// ================================================================
procedure TForm2.TimerBlinkTimer(Sender: TObject);
begin
  // intencionalmente vacío
end;

// ================================================================
//  VolverDelJuego — llamado por Unit1 cuando se vuelve al menú
// ================================================================
procedure TForm2.VolverDelJuego;
begin
  PnlCarga.Visible := False;
  Button1.Visible  := True;
  Button2.Visible  := True;
  PosicionarBotones;
  Self.Show;
  Self.BringToFront;
end;

end.

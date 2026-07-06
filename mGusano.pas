unit mGusano;

interface
uses vcl.Graphics;
  const dIzq = 37;
        dArr = 38;
        dDer = 39;
        dAba = 40;
        MargenPared = 30; // grosor de las paredes laterales/inferior, en px
  TYPE
    Tposicion = record
      x,y: integer;
    end;
    TGusano = class
      private
        p: Tposicion;
        d: byte;
        t: byte;
        c: TColor;
        g: array[1..30] of Tposicion;
        choco: Boolean;
      public
        constructor Create;
        procedure SetPosicion(pp: TPosicion);
        procedure SetDireccion(dd: byte);
        procedure SetTamaño(tt: byte);
        procedure SetColor(cc: TColor);
        function GetPosicion: TPosicion;
        function GetDireccion: Byte;
        function GetTamaño: byte;
        function GetColor: TColor;
        function GetChoco: Boolean;
        function GetSegmento(i: byte): TPosicion;
        function ChocaConsigoMismo: boolean;
        procedure Mover(cc: TCanvas; TopeArriba: Integer; const Obstaculos: array of TPosicion);
        procedure Crecer;
        procedure Encoger;
        procedure Morir;
        procedure Dibujar(cc: TCanvas);
        procedure Borrar(cc: TCanvas);
        property Direccion: byte read GetDireccion write SetDireccion;
        property Posicion: TPosicion read GetPosicion write SetPosicion;
    end;

  implementation

  procedure TGusano.Borrar(cc: TCanvas);
  var i: byte;
  begin
    cc.Pen.Color   := clBtnFace;
    cc.Brush.Color := clBtnFace;
    for i := 1 to t do
      cc.Ellipse(g[i].x, g[i].y, g[i].x+30, g[i].y+30);
    cc.Ellipse(p.x, p.y, p.x+30, p.y+30);
  end;

  procedure TGusano.Dibujar(cc: TCanvas);
  var i: byte;
  begin
    cc.Pen.Color   := c;
    cc.Brush.Color := c;
    for i := 1 to t do
      cc.Ellipse(g[i].x, g[i].y, g[i].x+30, g[i].y+30);
    cc.Ellipse(p.x, p.y, p.x+30, p.y+30);
  end;

  constructor TGusano.Create;
  var i: byte;
  begin
    p.x := 180; p.y := 270;
    d := dDer; t := 4; c := clGreen;
    choco := False;
    for i := 1 to t do begin
      g[i].x := p.x - 30*i;
      g[i].y := p.y;
    end;
  end;

  procedure TGusano.SetPosicion(pp: TPosicion);
  begin
    if (pp.x mod 30 = 0) and (pp.y mod 30 = 0) then p := pp;
  end;

  procedure TGusano.SetDireccion(dd: byte);
  begin
    if dd in [dArr, dAba, dIzq, dDer] then d := dd;
  end;

  procedure TGusano.SetTamaño(tt: byte);
  begin
    if tt <= 30 then t := tt;
  end;

  procedure TGusano.SetColor(cc: TColor);
  begin c := cc; end;

  function TGusano.GetPosicion: TPosicion;
  begin result := p; end;

  function TGusano.GetDireccion: Byte;
  begin result := d; end;

  function TGusano.GetTamaño: byte;
  begin result := t; end;

  function TGusano.GetColor: TColor;
  begin result := c; end;

  function TGusano.GetChoco: Boolean;
  begin result := choco; end;

  function TGusano.GetSegmento(i: byte): TPosicion;
  begin
    if (i >= 1) and (i <= t) then
      result := g[i]
    else begin
      result.x := -1000; result.y := -1000; // fuera de pantalla, por seguridad
    end;
  end;

  function TGusano.ChocaConsigoMismo: boolean;
  var i: byte;
  begin
    result := false;
    for i := 1 to t do begin
      if (g[i].x = p.x) and (g[i].y = p.y) then begin
        result := true;
        Exit;
      end;
    end;
  end;

  // -------------------------------------------------------
  // MOVER: calcula la próxima posición y checa colisión
  // Si choca: solo marca choco=True y NO mueve (Unit1 decide)
  // Si no choca: mueve normal
  // -------------------------------------------------------
  procedure TGusano.Mover(cc: TCanvas; TopeArriba: Integer; const Obstaculos: array of TPosicion);
  var
    i, j        : Integer;
    nx, ny      : Integer;
    hayColision : Boolean;
  begin
    choco := False;

    nx := p.x; ny := p.y;
    case d of
      dIzq: nx := p.x - 30;
      dArr: ny := p.y - 30;
      dDer: nx := p.x + 30;
      dAba: ny := p.y + 30;
    end;

    // Choca con paredes (deja MargenPared de espacio en los 4 lados;
    // arriba, el lÃ­mite lo pasa Unit1 segÃºn el alto real del panel)
    hayColision :=
      (nx < MargenPared) or (nx + 30 > cc.ClipRect.Right - MargenPared) or
      (ny < TopeArriba) or (ny + 30 > cc.ClipRect.Bottom - MargenPared);

    // Choca con su propio cuerpo
    if not hayColision then begin
      for i := 2 to t do begin
        if (nx = g[i].x) and (ny = g[i].y) then begin
          hayColision := True;
          Break;
        end;
      end;
    end;

    // Choca con un bloque/obstÃ¡culo interno del mapa
    if not hayColision then begin
      for j := 0 to High(Obstaculos) do begin
        if (nx = Obstaculos[j].x) and (ny = Obstaculos[j].y) then begin
          hayColision := True;
          Break;
        end;
      end;
    end;

    if hayColision then begin
      // Solo marcar: Unit1 decide si reinicia o hace game over
      choco := True;
    end else begin
      // Solo actualiza posiciones; el dibujo lo controla Unit1
      for i := t downto 2 do
        g[i] := g[i-1];
      g[1] := p;
      p.x  := nx;
      p.y  := ny;
    end;
  end;

  procedure TGusano.Crecer;
  begin
    if t < 30 then begin
      Inc(t);
      g[t] := g[t-1];
    end;
  end;


  // Encoger: quita el último segmento de cola (inverso de Crecer)
  // No deja que el gusano quede en 0 segmentos.
  procedure TGusano.Encoger;
  begin
    if t > 1 then
      Dec(t);
  end;
  procedure TGusano.Morir;
  var i: byte;
  begin
    p.x := 180; p.y := 270;
    d   := dDer; t := 4;
    choco := False;
    for i := 1 to t do begin
      g[i].x := p.x - 30*i;
      g[i].y := p.y;
    end;
  end;

end.

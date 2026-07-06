program Project1;

uses
  Vcl.Forms,
  Unit2   in 'Unit2.pas'   {Form2},
  Unit1   in 'Unit1.pas'   {Form1},
  mGusano in 'mGusano.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  // Orden: Form2 (splash + carga + menú, todo fusionado) → Form1 (juego)
  // Form2 es el primero = pantalla principal al arrancar
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
